# Verificação de arranque

1. Importe `sql.sql` na base de dados do servidor.
2. Garanta `oxmysql`, `ox_lib`, `qb-core` e `qb-target` antes de `script_lusitan` no `server.cfg`.
3. Arranque o servidor e confirme a linha `Centro Jogos ... Recurso iniciado com sucesso.` na consola.
4. Confirme que não existem erros de carregamento Lua ou de dependências.
5. Altere temporariamente `Config.Locale` para `en`, reinicie o recurso e confirme a mensagem em inglês.
6. Deixe os webhooks vazios para confirmar que o arranque não tenta enviar pedidos Discord.
