# Menus CRT integrados — 11/10/2026

As quatro artes agora fazem parte das cenas jogáveis. As skins v02 foram editadas
com a ferramenta integrada image_gen para retirar os dados e a seleção fixos;
botões, mensagens, seleção e valores são controles reais do Godot. Os conceitos
v01 e todos os prompts foram preservados em `assets/ui/retro_terminal/`.

## Jogar

Abra `executar-exterior.cmd`, atravesse a porta e vá até a mesa, ou abra diretamente
`executar-sala.cmd`. Pressione **E** perto do computador:

- **SAVE** grava posição, orientação, objetivo e suprimentos no registro existente.
- **SHOP** abre a loja. Escolha um item e **BUY** para comprar; o saldo e o estoque
  mudam imediatamente. **SAVE** após comprar guarda os suprimentos para a sessão seguinte.
- **BACK/Esc** na loja retorna ao terminal. **EXIT/Esc** no terminal retoma o jogo.
- Mouse, setas/Tab e Enter funcionam nas duas telas. O personagem e o mundo param
  enquanto o terminal está aberto. Nenhum save é feito apenas por abrir o terminal.

**Esc** durante a exploração abre a pausa CRT: Continuar, Reiniciar, Controles,
Filtro e Sair do jogo. Os controles e os presets de vídeo mantêm as funções já
existentes. A mesma pausa e o HUD também foram ligados ao percurso técnico de F5.

## Dados apresentados

O estoque inicial é 2400 créditos, 90 cartuchos, zero kits e nenhuma pistola.
AMMO custa 300 e acrescenta 30 cartuchos; MED KIT custa 500 e acrescenta um kit;
WEAPON custa 1800 e registra a pistola. Créditos insuficientes, limites de estoque
ou uma pistola já adquirida desativam BUY. A aquisição da arma não implementa
combate; disparos, dano e uso de kits continuam pendentes.

O HUD usa transparência real e apresenta créditos, kits, cartuchos, aquisição da
pistola, objetivo atual e E apenas quando uma porta ou o terminal estão ao alcance.
No percurso técnico, o objetivo vem do progresso desse percurso. O HUD desaparece
durante os menus e a transição de porta. Avisos temporários ficam no centro superior.
A lista técnica de teclas pode ser exibida com `--debug-instructions`.
Os rótulos do HUD são curtos e maiores para suportar o filtro PSX global atual.
O preset Windows passou a incluir exterior, sala, suas artes ativas e os recursos
de UI. Uma build já exportada precisa ser regenerada para receber essas mudanças.

`supplies` é um campo opcional no formato 2 do save, portanto registros anteriores
continuam válidos e recebem o estoque inicial. Compras não salvam automaticamente
nem avançam o objetivo; só SAVE bem-sucedido conclui o objetivo do terminal.

## Implementação

- `ui/retro_screen.gd`: canvas 1672×941, escala uniforme e barras ao ajustar a janela.
- `ui/retro_button.gd`: Button nativo com foco, cursor e moldura angular desenhada.
- `ui/terminal_menu.gd`: telas SAVE/SHOP, seleção, dados de registro e mensagens.
- `ui/game_hud.gd`: regiões da skin transparente, dados reais e interação próxima.
- `ui/pause_menu.gd`: skin CRT, cinco opções e proteção contra outro modal aberto.
- `systems/save/supply_stock.gd`: compras, limites, estoque e restauração.
- `systems/interaction/terminal_interaction.gd`: abertura por E e gravação por SAVE.
- `systems/save/save_game.gd`: persistência do estoque junto do progresso.

## Verificação

Godot 4.7.2: `check_terminal_ui.gd` passou em headless e em execução gráfica
OpenGL Compatibility, com teclado e cliques reais enviados ao viewport. Cobre
abertura sem gravação, SAVE sem permissão de escrita, personagem imóvel enquanto
o menu está aberto, compras e débitos, créditos insuficientes, aquisição única da
arma, BACK/Esc, hit targets após ajuste para 4:3, retomada do estoque, compatibilidade
com registros antigos, controles/filtro da pausa e atualização do HUD.

Regressões: `check_save_persistence.gd` (136 ticks), `check_level_operation.gd`
(172 ticks) e `check_operation.gd` passaram com zero falhas.
`check_dylan_doors.gd` também passou: 1164 ticks, ida e volta pela porta, zero falhas.
`check_scenes.gd` validou as 20 cenas com zero falhas. Os testes de terminal usam
exclusivamente `res://.local/save_probe.cfg`. O engine emite avisos
locais de acesso a certificados/cache no sandbox, sem falhas de script nas execuções.

Capturas reais do renderer:

- [Terminal](evidence/ui/terminal.png)
- [SHOP](evidence/ui/shop.png)
- [HUD na sala](evidence/ui/hud.png)
- [Terminal em 4:3](evidence/ui/terminal-4x3.png)
- [Pausa em 4:3](evidence/ui/pause-4x3.png)

## Verificação solicitada sobre o poste

A v02 da vista 2 ainda é a arte ativa; não existe v03 integrada. O colisor foi
removido anteriormente, mas a geometria continua como oclusor. O desvio da arte
registrado em `calibration/exterior/EXTERIOR_GEOMETRY.md` é de 26–50 px antes do
zoom. Guia, máscara e prompt para corrigir apenas o poste estão em
`calibration/exterior/pole_fix/`. O README dessa pasta conserva a justificativa
histórica de quando havia um colisor; a remoção posterior está na ficha principal.
Esta integração de UI não modifica a arte do poste.
