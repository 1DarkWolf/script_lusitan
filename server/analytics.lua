CJ = CJ or {}
CJ.Analytics = CJ.Analytics or {}

local function numeric(rows, field)
    return rows and rows[1] and tonumber(rows[1][field]) or 0
end

local function normaliseRows(rows, fields)
    for _, row in ipairs(rows or {}) do
        for _, field in ipairs(fields) do row[field] = tonumber(row[field]) or 0 end
    end
    return rows or {}
end

---@param source number
---@return table|nil
function CJ.Analytics.GetOwnerDashboard(source)
    if not CJ.Company.IsBoss(source) then return nil end

    local company = CJ.Company.Get()
    if not company then return nil end

    -- MantÃ©m uma linha visÃ­vel no painel para cada sorteio, mesmo antes de ter contribuiÃ§Ãµes.
    for _, name in ipairs({ 'euromillions', 'totoloto', 'eurodreams', 'joker', 'classic', 'popular' }) do
        CJ.Jackpot.Ensure(name, 0)
    end

    local scratch = CJ.Database.Query([[SELECT COUNT(*) AS `sold`, COALESCE(SUM(`amount`), 0) AS `revenue`
        FROM `cj_transactions` WHERE `company_id` = ? AND `type` = 'scratch_purchase']], { company.id })
    local gameSales = CJ.Database.Query([[SELECT `type`, COUNT(*) AS `sales`, COALESCE(SUM(`amount`), 0) AS `revenue`
        FROM `cj_transactions` WHERE `company_id` = ? AND `type` LIKE '%_purchase'
        GROUP BY `type` ORDER BY `revenue` DESC]], { company.id }) or {}
    local dailySales = CJ.Database.Query([[SELECT DATE(`created_at`) AS `day`, COUNT(*) AS `sales`, COALESCE(SUM(`amount`), 0) AS `revenue`
        FROM `cj_transactions` WHERE `company_id` = ? AND `type` LIKE '%_purchase'
        GROUP BY DATE(`created_at`) ORDER BY `day` DESC LIMIT 7]], { company.id }) or {}
    local weeklySellerSales = CJ.Database.Query([[SELECT
            JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.sellerId')) AS `seller_id`,
            JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.sellerLabel')) AS `seller_label`,
            COUNT(*) AS `sales`, COALESCE(SUM(`amount`), 0) AS `revenue`
        FROM `cj_transactions`
        WHERE `company_id` = ? AND `type` LIKE '%_purchase'
          AND `created_at` >= DATE_SUB(NOW(), INTERVAL 7 DAY)
          AND JSON_VALID(`metadata`) = 1
          AND JSON_EXTRACT(`metadata`, '$.sellerId') IS NOT NULL
        GROUP BY `seller_id`, `seller_label` ORDER BY `revenue` DESC]], { company.id }) or {}
    local jackpots = CJ.Database.Query([[SELECT `name`, `amount`, `is_active`, `updated_at` FROM `cj_jackpots`
        WHERE `company_id` = ? ORDER BY `name`]], { company.id }) or {}
    local recent = CJ.Database.Query([[SELECT `type`, `amount`, `created_at` FROM `cj_transactions`
        WHERE `company_id` = ? ORDER BY `created_at` DESC LIMIT 12]], { company.id }) or {}

    normaliseRows(gameSales, { 'sales', 'revenue' })
    normaliseRows(dailySales, { 'sales', 'revenue' })
    normaliseRows(weeklySellerSales, { 'sales', 'revenue' })
    normaliseRows(jackpots, { 'amount' })
    normaliseRows(recent, { 'amount' })

    local sellerSalesById = {}
    for _, row in ipairs(weeklySellerSales) do
        if row.seller_id then sellerSalesById[row.seller_id] = row end
    end

    local sellerSales, configuredSellerIds = {}, {}
    for _, seller in ipairs(Config.Sellers or {}) do
        local row = sellerSalesById[seller.id] or {}
        sellerSales[#sellerSales + 1] = {
            id = seller.id,
            label = seller.label,
            sales = tonumber(row.sales) or 0,
            revenue = tonumber(row.revenue) or 0
        }
        configuredSellerIds[seller.id] = true
    end
    for _, row in ipairs(weeklySellerSales) do
        if row.seller_id and not configuredSellerIds[row.seller_id] then
            sellerSales[#sellerSales + 1] = {
                id = row.seller_id,
                label = row.seller_label or row.seller_id,
                sales = row.sales,
                revenue = row.revenue
            }
        end
    end
    table.sort(sellerSales, function(left, right) return left.label < right.label end)

    local totals = { sales = 0, revenue = 0 }
    for _, row in ipairs(gameSales) do
        totals.sales = totals.sales + row.sales
        totals.revenue = totals.revenue + row.revenue
    end

    return {
        balance = tonumber(company.balance) or 0,
        scratch = { sold = numeric(scratch, 'sold'), revenue = numeric(scratch, 'revenue'), stock = CJ.Stock.GetAll() },
        totals = totals,
        gameSales = gameSales,
        dailySales = dailySales,
        sellerSales = sellerSales,
        jackpots = jackpots,
        recentTransactions = recent
    }
end

CJ.Callbacks.Register('cj:server:getOwnerAnalytics', CJ.Analytics.GetOwnerDashboard)
exports('GetOwnerAnalytics', CJ.Analytics.GetOwnerDashboard)
