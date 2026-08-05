# Centro de Jogos

Recurso FiveM para QBCore, desenvolvido para gerir um centro de jogos.

## Dependências

- `qb-core`
- `qb-target`
- `ox_lib`
- `oxmysql`

## Instalação

1. Coloque esta pasta nos recursos do seu servidor FiveM.
2. Garanta as dependências antes de `script_lusitan` no `server.cfg`.
3. Adicione `ensure script_lusitan` ao `server.cfg`.

## Idiomas

O recurso inclui Português (`pt`) e Inglês (`en`). Defina o idioma em `Config.Locale` no ficheiro `config.lua`.

## API pública

No servidor, outros recursos podem usar `exports['script_lusitan']:RegisterCallback(nome, handler)` para expor callbacks ao cliente. No cliente, use `exports['script_lusitan']:AwaitCallback(nome, ...)` ou `CallCallback(nome, callback, ...)`.

## Base de dados e cache

As consultas passam por `server/database.lua`. Registe SQL fixo com `CJ.Database.Prepare(nome, sql)` e execute-o com `CJ.Database.Execute(nome, parametros)`. O cache em memória disponibiliza `Get`, `Set`, `GetOrSet`, `Remove` e `Clear`; a duração padrão recomendada está em `Config.CacheDefaultTtl`.

## Registos

`CJ.Log.Write(nível, mensagem)` escreve no console do servidor. Para Discord, preencha o webhook em `Config.Webhooks` e use `CJ.Log.Discord(canal, título, descrição, campos, cor)`; não é feita qualquer chamada externa quando o webhook estiver vazio.

## Segurança

Registe eventos cliente-servidor através de `CJ.Security.RegisterEvent(nome, handler)`. Cada pedido valida a origem, aplica o limite configurado em `Config.Security` e regista bloqueios. O `handler` recebe sempre o `source` validado como primeiro argumento.
