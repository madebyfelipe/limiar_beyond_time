# Mapa do Episódio 1 e aba MAP

Data: 13/10/2026. Duas coisas: a **planta do episódio** (oito ambientes, decididos
com o usuário) e a **aba MAP** da tela do inventário, que mostra essa planta
conforme Dylan a descobre. A apresentação foi refeita pelo Codex a partir da
referência: moldura industrial, seleção âmbar, prévia e lista à esquerda, planta
sobre floresta e grade ao centro, legenda, objetivo e visão regional à direita.
O cabeçalho conserva destinos funcionais do jogo: MAP, ITEMS, WEAPONS, AMMO,
RECOVERY e EXIT, em vez das abas fictícias da referência.

## Os oito ambientes

Decisões do usuário em 13/10/2026: **oito ambientes no total** (quatro prontos e
quatro novos) e **final na sala do relé**.

| # | Ambiente | Estado | Papel |
| --- | --- | --- | --- |
| 1 | GUARDHOUSE YARD (estrada e pátio) | pronto | chegada, sem inimigos |
| 2 | GUARDHOUSE | pronto | sala segura A: save, loja, baú |
| 3 | PERIMETER TRAIL | pronto | combate aberto, dois Keleken |
| 4 | RELAY ROOM | pronto | log, apagão e, no fim, o uplink |
| 5 | SERVICE YARD | a construir (hoje é o pátio provisório `perimeter_4`) | hub com quatro saídas |
| 6 | CREW QUARTERS | a construir | sala segura B, cofre |
| 7 | KENNEL BLOCK | a construir | corredor apertado, fusível, atalho para o pátio da guarita |
| 8 | GENERATOR HOUSE | a construir | anel apertado, religar a energia |

O laço que organiza o episódio: pátio da guarita → trilha → relé → pátio de
serviço → canil → pátio da guarita. A porta sul do canil fica na cerca norte do
pátio, atrás da guarita, e só abre por dentro. **Pendente de confirmação do
usuário:** essa porta exige editar a placa pronta do pátio norte.

## Dados — `AreaMap` (`systems/map/area_map.gd`)

Estático, como `MissionState` e `SupplyStock`. A planta usa metros esquemáticos
com o norte para cima (x para leste, y para sul, como x e z nos cenários).

- `ROOMS`: os oito ambientes. Cada um tem os retângulos desenhados (`shapes`) e,
  quando já existe cena, os trechos de chão que eles representam (`parts`:
  retângulo no cenário → retângulo na planta). Ambiente sem cena tem `scene`
  vazio e nenhum `parts`.
- `DOORS`: nove portas, cada uma com a etapa do objetivo que a libera
  (`opens_at`) ou `SEALED` enquanto o ambiente do outro lado não existe.
- `locate(cena, posição)` devolve ambiente e ponto na planta. A estrada (19 m)
  vira um toco de 6 m com a seta **TO ACCESS ROAD**; a trilha (27 m) ocupa 18 m.
  O interior da guarita entra **girado um quarto de volta**: a porta da sala
  fica na parede oeste e a do prédio na face sul.
- Descoberta: `track()` marca como visitado o ambiente em que o jogador está
  (chamado por `LevelOperation` a cada quadro físico). Um ambiente atrás de uma
  porta de um ambiente visitado aparece como contorno **UNEXPLORED**; os demais
  não aparecem. No primeiro minuto o pátio já mostra a guarita, a trilha e o
  canil, este com a porta selada.
- O marcador de objetivo segue `MissionState.stage` (`OBJECTIVE_ROOM`).

### Salvamento

`SaveGame` grava `map` (lista de ids visitados) junto de `supplies`, sem mudar o
`FORMAT`. `restore()` não confia na lista: ids desconhecidos são descartados e
os ambientes que a etapa gravada implica entram de qualquer forma, então um save
anterior ao mapa volta com os ambientes do próprio progresso. NEW GAME zera o
mapa; Reiniciar não.

## Aba MAP — `MapPage` (`ui/map_page.gd`)

Quinta aba do inventário (**Tab** / **L1 R1**), sobre os painéis da maleta.

| Entrada | Efeito |
| --- | --- |
| Setas / direcional ↑↓ | Percorre os ambientes conhecidos |
| R / □ (ação `reload`) | Zoom ×2 no ambiente selecionado |
| Enter / ✕ | Volta ao ambiente em que Dylan está |
| Mouse | Clica numa linha da lista ou num ambiente da planta |
| Arrastar com o botão esquerdo / analógico direito | Move a planta para olhar ao redor, até 8 m além dos ambientes conhecidos |
| Esc / ○ / I | Fecha a maleta |

O deslocamento (`MapPage.pan`, em metros da planta) volta a zero ao escolher um
ambiente na lista, ao dar zoom e ao confirmar. Um ambiente clicado na própria
planta é selecionado sem mexer a vista, porque o clique pode ser o começo de um
arrasto. O probe `mapa` cobre arrasto, analógico, limite e seleção no lugar
(341 ticks, zero falhas; três defeitos reintroduzidos e acusados).

Mostra: lista numerada dos oito ambientes (nome, `UNEXPLORED` ou traços), prévia
do ambiente selecionado (a placa do cenário, só depois de visitado), planta com
portas verdes (abertas) e vermelhas (seladas), ponto de save, objetivo, posição
e rumo de Dylan, legenda, texto do objetivo e contagem `EXPLORED n / 8`.

A planta cabe inteira no painel: a escala se ajusta aos ambientes conhecidos,
com teto de 16 px por metro. Contornos têm 3 px porque linhas mais finas caem
entre as amostras do filtro retro.

### O que foi tocado nos arquivos de UI

Mudanças mínimas, para o Codex reconhecer ao refazer a interface:

- `ui/inventory_menu.gd`: `"MAP"` em `TAB_NAMES`/`TAB_KINDS`, `MAP_TAB`,
  `map_page` criado em `_ready`, mostrado em `_select_tab`, escondido em
  `open()`, e duas entregas de entrada (`_input` e `_click`) quando a aba é MAP.
- `ui/inventory_console.gd`: `tab_rect(index, count)` divide a barra pelo número
  de abas (com quatro, o resultado é o de antes).
- `ui/main_menu.gd`: `AreaMap.reset()` em NEW GAME.

Contrato para a nova interface: `MapPage` só lê `AreaMap`, `MissionState` e o
jogador; quem redesenhar a tela pode trocar todo o `_draw` mantendo `enter()`,
`handle()`, `click()`, `selected`, `zoomed`, `here` e `plan_view()`, que são o
que o probe usa.

## Verificação

`tests/check_area_map.gd` (probe `mapa`): **73 ticks, zero falhas**. Dados
(oito ambientes, portas na parede dos dois ambientes que ligam, cenas e prévias
existentes), posição nos quatro cenários, descoberta, portas e objetivo por
etapa, save (lista adulterada, registro antigo) e a aba no pátio real: I, quatro
Tabs, setas só pelos conhecidos, zoom, cliques na lista e na planta, Esc.

Três asserções foram testadas contra o próprio defeito: guarita sem o quarto de
volta (2 falhas, 3,68 m da porta), cenário que não chama `track()` (11 falhas)
e porta selada que abre com o progresso (5 falhas).

Regressões na mesma execução, todas com zero falhas: `inventario` (agora com a
quinta aba no ciclo do Tab), `salvamento`, `operacao-cenarios`, `dylan-portas`,
`perimetro`, `rele`, `terminal-ui`, `menu-inicial`, `cenas`, `unidades`,
`exterior-geometria`, `sala-geometria`, `combate-inimigo`.

`tools/preview_area_map.gd` captura a aba em `.local/ui-map-*.png` (início,
depois do apagão, zoom e 720p). As quatro capturas foram inspecionadas.

## Limites

- A composição segue a referência, mas a planta continua sendo a geometria real
  do episódio (mais vertical). A floresta é decorativa; não introduz salas,
  caminhos, rios ou escadas nos dados do mapa.
- Sem atalho próprio: o mapa abre pela maleta e pelo Tab. Uma ação `map`
  remapeável mexe em `InputBindings` e nas telas de controles.
- A planta é esquemática e alta; sobra largura no painel.
- A porta da frente do relé fica em x = 0 na trilha e em x = 1,8 na sala, então
  a seta de Dylan não coincide com a marca da porta ao entrar. A diferença está
  na geometria das duas cenas.
- Os quatro ambientes novos existem só como dados. Quando cada cena nascer:
  preencher `scene`, `preview` e `parts`, e trocar `SEALED` pela condição real.
  Portas que dependem de item ou de energia pedem mais que uma etapa do
  objetivo; hoje `opens_at` só conhece `MissionState.Stage`.
- Suíte completa e probes gráficos não foram rodados; só os listados acima.

## Redesenho visual — Codex, 13/10/2026

- `ui/map_page.gd`: nova composição, recorte proporcional das prévias, grade em
  metros, bússola, escala, cantos âmbar da área selecionada, minimapa com o
  retângulo da vista e texto do objetivo com quebra de linha e ajuste de tamanho.
- `ui/map_atlas.gd`: molduras e tipografia próprias da tela. A textura está em
  `assets/ui/map/snow_forest_atlas_v02.png`; origem e prompt no README dessa pasta.
- A miniatura regional tira o zoom ao clicar. Os botões superiores levam às
  quatro categorias existentes do inventário; EXIT fecha a maleta. Tab/L1/R1
  continuam no ciclo original, com MAP como quinta aba.
- Em `ui/inventory_menu.gd`, só o despacho do clique da aba MAP foi antecipado
  nesta etapa, para respeitar o novo cabeçalho. Preservadas as integrações de
  Claude, a divisão dinâmica de abas do console e o reset de NEW GAME.
- Mantidos os métodos públicos e os dados de `AreaMap`. Nenhuma alteração de
  descoberta, colisão, portas, objetivo, geometria de cenário ou save.
- Regressões finais: `mapa` (73 ticks), `inventario` (523), `salvamento` (136) e
  `menu-inicial`: zero falhas, runner `executed=4 failed=0`. O probe do mapa
  também verifica os quatro destinos do cabeçalho, EXIT e clique na visão geral.
- Capturas verificadas: início, apagão, zoom, 1280×720, 1024×768 com letterbox,
  1920×1080 sem filtro e seleção de área inexplorada. O preview não grava
  preferências de vídeo. Evidências finais em `docs/evidence/ui/map-*-v01.png`.

### Região nevada

A pedido do usuário, o atlas agora mostra neve no solo e nas árvores, com
pinheiros e abetos em tons frios. A mesma textura atualiza o mapa principal e
o minimapa. Planta e marcadores preservados. Importação e captura gráfica sem
erros; conferidas as capturas nativa e 720p com filtro retrô. Evidências:
`docs/evidence/ui/map-snow-native-v02.png` e `map-snow-720-v02.png`.
