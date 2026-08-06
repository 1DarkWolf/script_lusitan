# Centro de Jogos

Recurso FiveM para QBCore, desenvolvido para gerir um centro de jogos.

## Dependências

- `qb-core`
- `qb-target`
- `ox_lib`
- `oxmysql`

## Instalação

1. Importe `sql.sql` na base de dados do servidor.
2. Coloque esta pasta nos recursos do seu servidor FiveM.
3. Garanta as dependências antes de `script_lusitan` no `server.cfg`.
4. Adicione `ensure script_lusitan` ao `server.cfg`.

Consulte `tests/smoke-test.md` antes de começar a desenvolver ou instalar funcionalidades adicionais.

## Empresa

O NPC, o balcão, o blip e o horário são configurados em `Config.Company`. O Boss Menu só aparece a jogadores cujo cargo QBCore esteja marcado como `isboss`; se usar esta funcionalidade, inicie também `qb-management` antes deste recurso.

## Empregados

Copie a definição de emprego em `docs/qbcore-job.lua` para `qb-core/shared/jobs.lua` e reinicie `qb-core`. Os cargos e permissões do recurso são configurados em `Config.EmployeeRoles`. Contratações, promoções e despedimentos são validadas no servidor e auditadas na tabela `cj_employee_audits`.

## Bilhetes

Copie os itens em `docs/qbcore-items.lua` para `qb-core/shared/items.lua` e adicione as respetivas imagens ao inventário. Cada bilhete é um item único e contém apenas metadados de identificação; a propriedade, a validade e a utilização única são sempre confirmadas contra `cj_tickets` no servidor.

## Sorteios

Os módulos de jogo registam-se através de `exports['script_lusitan']:RegisterDrawGame(id, definition)`, fornecendo o horário e a função que gera o resultado. O scheduler verifica apenas uma vez por intervalo configurável e grava cada resultado de forma única em `cj_draw_results`.

## Jackpots

Um jogo pode declarar `jackpot = { name = '...', initialAmount = 0 }` ao registar-se no motor de sorteios. Usa `exports['script_lusitan']:AddToJackpot(nome, valor)` para acumular contribuições e devolve `claimJackpot = true` no resultado do sorteio quando deve atribuí-lo. A reclamação usa uma atualização condicional na base de dados, por isso o mesmo jackpot não pode ser entregue duas vezes.

## Raspadinhas

As raspadinhas são configuradas em `Config.ScratchCards`. Os pesos de prémio determinam a probabilidade e são sorteados no servidor no momento da compra; o cliente só recebe o tipo de raspadinha. Configure prémios até `Config.AutoPayLimit` para pagamento imediato.

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
