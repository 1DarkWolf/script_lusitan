# Integração com telefone

O Centro de Jogos disponibiliza os resultados já publicados através deste export de servidor:

```lua
local results = exports['script_lusitan']:GetPublishedLotteryResults()
```

Cada resultado contém `game_id`, `label`, `draw_key`, `result` e `drawn_at`.

O resource de telefone deve usar estes dados para mostrar uma aplicação de Resultados/Lotarias. A compra e o levantamento de prémios continuam sempre a ser processados pelo `script_lusitan`; o telefone apenas divulga os números vencedores.
