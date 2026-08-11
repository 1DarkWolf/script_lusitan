# Centro de Jogos

Recurso FiveM para QBCore, desenvolvido para gerir um centro de jogos.

## Dependências

- `qb-core`
- `qb-target`
- `ox_lib`
- `oxmysql`
- `lb-phone`

## Instalação

1. Importe `sql.sql` na base de dados do servidor.
2. Coloque esta pasta nos recursos do seu servidor FiveM.
3. Garanta as dependências antes de `script_lusitan` no `server.cfg`.
4. Adicione `ensure script_lusitan` ao `server.cfg`.

Inicie `lb-phone` antes deste resource. A aplicação Resultados é registada automaticamente e mostra no telefone os números vencedores já publicados.

Consulte `tests/smoke-test.md` antes de começar a desenvolver ou instalar funcionalidades adicionais.

## Empresa

O horário e o Boss Menu são configurados em `Config.Company`. Os pontos de venda são definidos em `Config.Sellers`: copie o exemplo comentado para criar novos NPCs, atribua um `id` único e altere as coordenadas. Cada vendedor abre a mesma loja, mas o servidor valida a proximidade do jogador e regista a venda no respetivo estabelecimento. O Boss Menu só aparece a jogadores cujo cargo QBCore esteja marcado como `isboss`; se usar esta funcionalidade, inicie também `qb-management` antes deste recurso.

## Empregados

Copie a definição de emprego em `docs/qbcore-job.lua` para `qb-core/shared/jobs.lua` e reinicie `qb-core`. Os cargos e permissões do recurso são configurados em `Config.EmployeeRoles`. Contratações, promoções e despedimentos são validadas no servidor e auditadas na tabela `cj_employee_audits`.

## Bilhetes

Copie os itens em `docs/qbcore-items.lua` para `qb-core/shared/items.lua` e copie os PNGs de `docs/item-images/` para a pasta `html/images/` do seu inventário QBCore. Cada bilhete é um item único e contém apenas metadados de identificação; a propriedade, a validade e a utilização única são sempre confirmadas contra `cj_tickets` no servidor.

## Sorteios

Os módulos de jogo registam-se através de `exports['script_lusitan']:RegisterDrawGame(id, definition)`, fornecendo o horário e a função que gera o resultado. O scheduler verifica apenas uma vez por intervalo configurável e grava cada resultado de forma única em `cj_draw_results`.

## Jackpots

Um jogo pode declarar `jackpot = { name = '...', initialAmount = 0 }` ao registar-se no motor de sorteios. Usa `exports['script_lusitan']:AddToJackpot(nome, valor)` para acumular contribuições e devolve `claimJackpot = true` no resultado do sorteio quando deve atribuí-lo. A reclamação usa uma atualização condicional na base de dados, por isso o mesmo jackpot não pode ser entregue duas vezes.

## Raspadinhas

As raspadinhas são configuradas em `Config.ScratchCards`. Os pesos de prémio determinam a probabilidade e são sorteados no servidor no momento da compra; o cliente só recebe o tipo de raspadinha. Cada categoria emite o seu próprio item (`scratch_bronze_ticket`, `scratch_silver_ticket`, `scratch_gold_ticket` ou `scratch_diamond_ticket`). Por defeito, Bronze, Prata, Ouro e Diamante custam respetivamente €100, €500, €1.000 e €3.000. Os pesos somam 10.000 e produzem um retorno médio de 55%, ou seja, uma margem esperada de 45% para a empresa a longo prazo. Prémios acima de `Config.AutoPayLimit` ficam pendentes para validação; o teto de cada raspadinha é `Config.ScratchMaximumPrize`.

## Stock e painel de gestão

As raspadinhas só podem ser vendidas quando existir stock na loja. O stock começa a zero; o dono da empresa deve ter no inventário o item `scratch_blank` e, no painel de gestão, escolher qual tipo de raspadinha pretende repor. Cada unidade entregue consome uma raspadinha em branco. Este é o único item preparado para o futuro sistema de crafting.

O NPC de gestão é configurado em `Config.OwnerDashboard.Npc`. Apenas o cargo QBCore da empresa com `isboss = true` consegue abrir a central de gestão. O painel tem separadores para consultar métricas, gerir o stock diretamente com `scratch_blank`, ver vendas e lojas, e depositar ou levantar dinheiro da conta da empresa. O painel mostra saldo da empresa, unidades e receita de raspadinhas, stock por tipo, jackpots, vendas por jogo, vendas dos últimos sete dias, movimentos recentes e a faturação semanal de cada NPC configurado. Importe novamente `sql.sql` após atualizar para criar a tabela `cj_store_stock`.

## Euromilhões

O jogo está configurado em `Config.Euromillions`: preço, dias/horário do sorteio e escalões de prémio. O jogador pode escolher cinco números e duas estrelas ou usar Quick Pick; a seleção, a chave vencedora e o cálculo dos acertos são todos validados no servidor.

## Totoloto

`Config.Totoloto` define o preço, sorteios e prémios. Cada aposta usa cinco números de 1 a 49 e um número da sorte de 1 a 13; a compra, o sorteio e a conferência do bilhete são integralmente validados no servidor.

## EuroDreams

O EuroDreams usa seis números de 1 a 40 e um número Dream de 1 a 5. Preço, horário e escalões de prémio são definidos em `Config.EuroDreams`.

## Joker

O Joker gera um código de seis dígitos para cada bilhete e compara-o com o código do sorteio diário. Os prémios por posições acertadas são configurados em `Config.Joker.prizes`.

## Lotarias

`Config.Lotteries` configura a Lotaria Clássica, Popular e Instantânea. As duas primeiras emitem números únicos para o próximo sorteio; a Instantânea define o prémio no servidor na compra e revela-o ao utilizar o bilhete.

## Fidelização

`Config.Loyalty` define os pontos por valor gasto e os níveis. As compras de jogos acumulam pontos automaticamente; os perfis guardam também o total gasto e o total de prémios recebidos.

## Administração

Os comandos requerem uma permissão listada em `Config.AdminPermissions`: `/drawnow`, `/resetdraw`, `/addjackpot`, `/setjackpot`, `/resetjackpot`, `/addmoney`, `/giveticket`, `/removeticket` e `/lotteryreload`.

## Prémios grandes

Prémios acima de `Config.AutoPayLimit` são registados em `cj_prize_claims` e ficam pendentes. Funcionários com a permissão `validate_prizes` podem aprová-los no separador Empresa do painel NUI quando o jogador estiver online.

## Idiomas

O recurso inclui Português (`pt`) e Inglês (`en`). Defina o idioma em `Config.Locale` no ficheiro `config.lua`.

## API pública

No servidor, outros recursos podem usar `exports['script_lusitan']:RegisterCallback(nome, handler)` para expor callbacks ao cliente. No cliente, use `exports['script_lusitan']:AwaitCallback(nome, ...)` ou `CallCallback(nome, callback, ...)`.

## Base de dados e cache

As consultas passam por `server/database.lua`. Registe SQL fixo com `CJ.Database.Prepare(nome, sql)` e execute-o com `CJ.Database.Execute(nome, parametros)`. O cache em memória disponibiliza `Get`, `Set`, `GetOrSet`, `Remove` e `Clear`; a duração padrão recomendada está em `Config.CacheDefaultTtl`.

## Conta da empresa

Chefias do emprego configurado em `Config.CompanyJob` podem consultar o saldo, depositar e levantar dinheiro através do balcão de gestão. O servidor confirma o cargo, o valor, o saldo e o limite definido em `Config.Company.Finance.maxTransaction`, e guarda cada operação em `cj_transactions`.

## Registos

`CJ.Log.Write(nível, mensagem)` escreve no console do servidor. Para Discord, preencha o webhook em `Config.Webhooks` e use `CJ.Log.Discord(canal, título, descrição, campos, cor)`; não é feita qualquer chamada externa quando o webhook estiver vazio.

## Segurança

Registe eventos cliente-servidor através de `CJ.Security.RegisterEvent(nome, handler)`. Cada pedido valida a origem, aplica o limite configurado em `Config.Security` e regista bloqueios. O `handler` recebe sempre o `source` validado como primeiro argumento.
