CJ = CJ or {}
CJ.WeeklySalesReport = CJ.WeeklySalesReport or {}

local reportKvpKey = 'weekly_sales_report:last_week'

local function formatCurrency(amount)
    amount = math.floor(tonumber(amount) or 0)
    local formatted = tostring(amount):reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return formatted:gsub('^%.', '')
end

local function weekStartTimestamp(date)
    -- O os.date usa domingo = 1, segunda-feira = 2, ..., sábado = 7.
    local daysSinceMonday = (date.wday + 5) % 7
    return os.time({
        year = date.year,
        month = date.month,
        day = date.day - daysSinceMonday,
        hour = 0,
        min = 0,
        sec = 0,
        isdst = date.isdst
    })
end

local function reportKey(date)
    return os.date('%Y-%m-%d', weekStartTimestamp(date))
end

local function groupLines(lines)
    local fields, chunk = {}, ''
    for _, line in ipairs(lines) do
        local separator = chunk == '' and '' or '\n'
        if #chunk + #separator + #line > 950 then
            fields[#fields + 1] = chunk
            chunk = line
        else
            chunk = chunk .. separator .. line
        end
    end
    if chunk ~= '' then fields[#fields + 1] = chunk end
    return fields
end

---@param date table
---@return boolean
function CJ.WeeklySalesReport.Send(date)
    date = date or os.date('*t')
    if not CJ.Utils.IsNonEmptyString(Config.Webhooks.weekly_sales) then return false end

    local key = reportKey(date)
    if GetResourceKvpString(reportKvpKey) == key then return false end

    local company = CJ.Company.Get()
    if not company then return false end

    local periodStart = weekStartTimestamp(date)
    local periodEnd = os.time(date)
    local rows = CJ.Database.Query([[SELECT
            JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.sellerId')) AS `seller_id`,
            JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.sellerLabel')) AS `seller_label`,
            COUNT(*) AS `sales`, COALESCE(SUM(`amount`), 0) AS `revenue`
        FROM `cj_transactions`
        WHERE `company_id` = ? AND `type` LIKE '%_purchase'
          AND `created_at` >= FROM_UNIXTIME(?) AND `created_at` <= FROM_UNIXTIME(?)
          AND JSON_VALID(`metadata`) = 1
          AND JSON_EXTRACT(`metadata`, '$.sellerId') IS NOT NULL
        GROUP BY `seller_id`, `seller_label`]], { company.id, periodStart, periodEnd }) or {}

    local salesBySeller, configuredSellerIds = {}, {}
    for _, row in ipairs(rows) do
        if row.seller_id then salesBySeller[row.seller_id] = row end
    end

    local sellers = {}
    for _, seller in ipairs(Config.Sellers or {}) do
        local row = salesBySeller[seller.id] or {}
        sellers[#sellers + 1] = {
            id = seller.id,
            label = seller.label,
            sales = tonumber(row.sales) or 0,
            revenue = tonumber(row.revenue) or 0
        }
        configuredSellerIds[seller.id] = true
    end
    for _, row in ipairs(rows) do
        if row.seller_id and not configuredSellerIds[row.seller_id] then
            sellers[#sellers + 1] = {
                id = row.seller_id,
                label = row.seller_label or row.seller_id,
                sales = tonumber(row.sales) or 0,
                revenue = tonumber(row.revenue) or 0
            }
        end
    end
    table.sort(sellers, function(left, right) return left.label < right.label end)

    local totalSales, totalRevenue, lines = 0, 0, {}
    for _, seller in ipairs(sellers) do
        totalSales = totalSales + seller.sales
        totalRevenue = totalRevenue + seller.revenue
        lines[#lines + 1] = ('• **%s** — %s vendas | €%s'):format(seller.label, seller.sales, formatCurrency(seller.revenue))
    end
    if #lines == 0 then lines[1] = 'Nenhum ponto de venda configurado.' end

    local fields = {
        { name = 'Vendas totais', value = tostring(totalSales), inline = true },
        { name = 'Faturação total', value = ('€%s'):format(formatCurrency(totalRevenue)), inline = true }
    }
    for index, value in ipairs(groupLines(lines)) do
        fields[#fields + 1] = { name = ('Lojas (%s)'):format(index), value = value, inline = false }
    end

    local description = ('Período: **%s** até **%s**.'):format(
        os.date('%d/%m/%Y %H:%M', periodStart),
        os.date('%d/%m/%Y %H:%M', periodEnd)
    )
    local sent = CJ.Log.Discord('weekly_sales', 'Relatório semanal de faturação', description, fields, 3066993)
    if sent then SetResourceKvp(reportKvpKey, key) end
    return sent
end

local function isDue(date)
    local schedule = Config.WeeklySalesReport
    if not schedule or not schedule.enabled or date.wday ~= schedule.day then return false end
    return date.hour > schedule.hour or (date.hour == schedule.hour and date.min >= schedule.minute)
end

CreateThread(function()
    while true do
        local date = os.date('*t')
        if isDue(date) then CJ.WeeklySalesReport.Send(date) end
        Wait(60000)
    end
end)

exports('SendWeeklySalesReport', function()
    return CJ.WeeklySalesReport.Send()
end)
