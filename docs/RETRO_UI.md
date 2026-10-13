# HUD e terminal de comandos — 11/10/2026

O terminal agora é um computador simulado com comandos, conforme o novo pedido.
Digite `help`, `save`, `shop`, `buy ammo`, `inventory`, `status`, `clear` ou `exit`
no prompt `GUARITA>`. O HUD mantém apenas VITALITY, conforme a referência fornecida.
Interface e barra são controles nativos do Godot. As artes anteriores continuam
como histórico, sem consumo pelo terminal atual.
Fluxo completo e capturas atualizadas: [COMMAND_TERMINAL.md](COMMAND_TERMINAL.md).

## Jogar

Abra `executar-exterior.cmd`, atravesse a porta e vá até a mesa, ou abra diretamente
`executar-sala.cmd`. Pressione **E** perto do computador:

- `save` grava posição, orientação, objetivo e suprimentos.
- `shop` lista produtos e preços; `buy ammo`, `buy medkit` ou `buy weapon` compra.
  Use `save` após comprar para guardar o estoque para a sessão seguinte.
- `help` lista comandos; `inventory` mostra estoque; `status` mostra o registro.
- `exit` ou Esc retoma o jogo. Enter executa, Tab completa e ↑/↓ percorrem histórico.
  Nenhum save é feito apenas por abrir o terminal ou enviar uma linha vazia.

**Esc** durante a exploração abre a pausa CRT: Continuar, Reiniciar, Controles,
Filtro e Sair do jogo. Os controles e os presets de vídeo mantêm as funções já
existentes. A mesma pausa e o HUD também foram ligados ao percurso técnico de F5.

## Dados apresentados

O estoque inicial é 2400 créditos e a maleta vazia; compras vão para o baú da sala
(ver [INVENTORY.md](INVENTORY.md)). O parágrafo abaixo é histórico.
AMMO custa 300 e acrescenta 30 cartuchos; MED KIT custa 500 e acrescenta um kit;
WEAPON custa 1800 e registra a pistola. Créditos insuficientes, limites de estoque
ou uma pistola já adquirida desativam BUY. A aquisição da arma não implementa
combate; disparos, dano e uso de kits continuam pendentes.

O HUD mostra somente VITALITY, sem nome, créditos, estoque, objetivos, molduras ou
avisos de interação. A barra lê `PlayerController.vitality` (0–100), inicialmente
100. Dano/combate ainda não está implementado, portanto a barra permanece cheia
no fluxo atual de exploração. O HUD desaparece durante menus e transições de porta.
Objetivos, interações e estoque continuam funcionando sem esses readouts na tela.
Avisos técnicos e a lista de teclas podem ser exibidos com `--debug-instructions`.
Estoque, saldo e registro aparecem na saída apenas quando os comandos correspondentes
são solicitados. A interface inicial contém o texto de abertura e a linha de entrada.
O preset Windows passou a incluir exterior, sala, suas artes ativas e os recursos
de UI. Uma build já exportada precisa ser regenerada para receber essas mudanças.

`supplies` é um campo opcional no formato 2 do save, portanto registros anteriores
continuam válidos e recebem o estoque inicial. Compras não salvam automaticamente
nem avançam o objetivo; só SAVE bem-sucedido conclui o objetivo do terminal.

## Implementação

- `ui/retro_screen.gd`: escala uniforme; console 1280×720, alinhado à composição.
- `ui/retro_button.gd`: Button nativo com foco, cursor e moldura angular desenhada.
- `ui/terminal_menu.gd`: entrada de comandos, transcript, histórico e autocompletar.
- `ui/game_hud.gd` e `ui/vitality_gauge.gd`: VITALITY sem informações adicionais.
- `ui/pause_menu.gd`: skin CRT, cinco opções e proteção contra outro modal aberto.
- `systems/save/supply_stock.gd`: compras, limites, estoque e restauração.
- `systems/interaction/terminal_interaction.gd`: abertura por E e gravação por SAVE.
- `systems/save/save_game.gd`: persistência do estoque junto do progresso.

## Verificação

Godot 4.7.2: `check_terminal_ui.gd` passou em headless e em execução gráfica
OpenGL Compatibility, com digitação e cliques reais enviados ao viewport.
Cobre comandos, histórico, Tab, argumentos inválidos, falha de save, compras,
rolagem, resize 4:3, retorno por exit/Esc e retomada. Detalhes atuais em
[COMMAND_TERMINAL.md](COMMAND_TERMINAL.md). Persistência e operação dos cenários
também foram reexecutadas após a mudança v04, com zero falhas.

Regressões: `check_save_persistence.gd` (136 ticks), `check_level_operation.gd`
(172 ticks) e `check_operation.gd` passaram com zero falhas.
Na integração anterior, `check_dylan_doors.gd` passou com 1164 ticks, zero falhas.
`check_scenes.gd` validou as 20 cenas com zero falhas. Os testes de terminal usam
exclusivamente `res://.local/save_probe.cfg`. O engine emite avisos
locais de acesso a certificados/cache no sandbox, sem falhas de script nas execuções.

Capturas reais do renderer:

- [Terminal v04](evidence/ui/console-boot-v04.png)
- [Sessão de comandos v04](evidence/ui/console-session-v04.png)
- [HUD na sala v03](evidence/ui/hud-v03.png)
- [Terminal em 4:3 v04](evidence/ui/console-4x3-v04.png)
- [Pausa em 4:3](evidence/ui/pause-4x3.png)

## Verificação solicitada sobre o poste

A v02 da vista 2 ainda é a arte ativa; não existe v03 integrada. O colisor foi
removido anteriormente, mas a geometria continua como oclusor. O desvio da arte
registrado em `calibration/exterior/EXTERIOR_GEOMETRY.md` é de 26–50 px antes do
zoom. Guia, máscara e prompt para corrigir apenas o poste estão em
`calibration/exterior/pole_fix/`. O README dessa pasta conserva a justificativa
histórica de quando havia um colisor; a remoção posterior está na ficha principal.
Esta integração de UI não modifica a arte do poste.
