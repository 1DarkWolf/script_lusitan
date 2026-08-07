# LB Phone — Resultados

O resource regista automaticamente a app **Resultados** no LB Phone. A app mostra os últimos números vencedores e atualiza quando o jogador toca no botão de atualização. Quando é feito um novo sorteio, os jogadores online recebem uma notificação no telefone.

No `server.cfg`, inicie o telefone antes do Centro de Jogos:

```cfg
ensure lb-phone
ensure script_lusitan
```

Os resultados publicados também continuam disponíveis para outras integrações através deste export de servidor:

```lua
local results = exports['script_lusitan']:GetPublishedLotteryResults()
```

Cada resultado contém `game_id`, `label`, `draw_key`, `result` e `drawn_at`. A compra e o levantamento de prémios continuam sempre a ser processados pelo `script_lusitan`; o telefone apenas divulga os números vencedores.
