# Fase 2 — trilha do perímetro

Estrutura de fase e o primeiro cenário de continuidade da guarita, criados em
12/10/2026. O Keleken deixou o exterior e passou a viver aqui.

Abra `executar-perimetro.cmd` para entrar direto na trilha, ou jogue a
continuidade: exterior → guarita → terminal (`save`) → portão norte.

## A estrutura de fase

`systems/missions/phase.gd` declara a cadeia de fases. Cada fase diz qual é a
cena de entrada, em que etapa ela é liberada, em que etapa o jogador está dentro
do seu conteúdo e em que etapa ela fecha:

| Fase | Cena de entrada | Libera em | Começa em | Fecha em |
| --- | --- | --- | --- | --- |
| `guardhouse` — Fase 1 | `environments/exterior.tscn` | `ROAD` | `ROAD` | `DONE` |
| `perimeter` — Fase 2 | `environments/perimeter.tscn` | `DONE` | `PERIMETER` | `RELAY` |

A cadeia é **declarada, não descoberta**: acrescentar uma cena em
`environments/` não a coloca na sequência. As etapas continuam vindo de
`MissionState`, que o arquivo de salvamento já guarda; `PERIMETER` e `RELAY`
foram acrescentadas **no fim** do enum, para que um registro antigo continue
retomando a etapa que gravou.

`Phase.rewind()` é o reinício de uma fase: devolve o objetivo ao começo do
próprio conteúdo, sem desfazer as fases que já fecharam e sem tocar no registro
salvo. A trilha usa isso em R / Esc → Reiniciar; o exterior continua reiniciando
a Fase 1 inteira.

## O portão que liga as duas

`systems/interaction/phase_gate.gd` é uma porta comum — mesmo ponto de
aproximação, mesma sequência — que só abre quando a fase seguinte foi liberada.
Desde 13/10/2026 o portão norte tem cinemática própria nos dois sentidos
(`passage = &"gate"`): Dylan ergue a alavanca e empurra as duas folhas, em vez de
abrir a porta de aço (`DYLAN_ANIMATION.md`, "Dylan na cinemática").
Enquanto a Fase 1 não fecha no terminal, o aviso no portão lê **"North gate
bolted"** e E recusa com um aviso na tela, em vez de não fazer nada. Depois do
`save`, o aviso vira **"North gate"** e a viagem acontece.

O portão fica na cerca norte do pátio, no eixo da estrada
(`NORTH_GATE_APPROACH = (0; 0; −5,9)`). Para distinguir as duas chegadas ao
exterior — a porta da guarita e o portão —, `DoorInteraction` passou a nomear a
passagem usada (`entry_id`), e `arrive_from_door()` escolhe posição e
enquadramento a partir desse nome.

## O cenário

`tools/author_perimeter.gd` escreve `environments/perimeter_source.tscn`, as
três definições de câmera em `resources/perimeter/` e as capturas de geometria em
`assets/backgrounds/perimeter/`. Geometria **antes** da arte, como no exterior e
na sala; sem renderizador o mesmo comando regenera geometria e câmeras e apenas
pula as capturas.

- Corredor de 6,4 m entre bancos de neve (x = ±3,2) e ombros de rocha
  (x = ±4,64), do portão em `z = 0` ao galpão do relé em `z = −29`.
- Trecho do cercado entre `z = −10` e `z = −19`, lido pelo que fica junto aos
  bancos e nunca atravessado na trilha: cocho e sacos de ração a leste; a oeste,
  placa de aviso no arame, fardos de feno, abrigo de meia-água sobre a cama de
  palha e poste de luz. É a área de patrulha do Keleken.
- Pinheiro caído em `z = −22,6` deixa passagem só pelo lado leste.
- Galpão do relé fecha o corredor ao norte, com mastro e porta ao nível do chão:
  a trilha chega rente à parede, sem degrau.
- Linha de árvores a x = ±12, fora do corredor e das câmeras.

**Geometria revista em 13/10/2026 (tarde).** Saíram o degrau de 0,2 m diante da
porta do galpão, que a cápsula não subia e parava Dylan em `z = −25,77`, a 1,1 m
da porta, e as duas cercas (postes e viga a 1,4 m) que cruzavam a trilha em
`z = −10` e `z = −19` sem colisão. A porta desceu ao chão e a fundação deixou de
aparecer na fachada (termina 1 cm atrás da parede frontal), então Dylan encosta
em `z = −26,6`; `RELAY_APPROACH` e `RELAY_ARRIVAL` avançaram 0,5 m para
acompanhar. Dos adereços novos, só o fardo de baixo e os sacos são sólidos, e
tudo que passa da altura do banco está a oeste, atrás do ator nas três câmeras.

As capturas `geometry_cam0{1,2,3}.png` e `cameras.json` foram regeneradas.
As placas anteriores a esta geometria foram preservadas como histórico.
**Conjunto atual: Dino Crisis 2 (2000) / PSX**, em
`assets/backgrounds/dc2_psx/perimeter_cam0{1,2,3,4}.png`, com prompts completos
no mesmo diretório em `prompts/`. As quatro referências atuais de runtime
estão em `perimeter/revised_geometry/`; `capture_perimeter_art.gd` reproduz
as vistas sem regenerar fonte ou câmeras. A trilha permanece livre das antigas
travessas e a porta frontal não tem degrau. Inventário e verificação final em
`DC2_PSX_ART_2026-10-13.md` (também cobre os demais espaços jogáveis).

### Câmeras

| Enquadramento | Posição | Alvo | FOV | Cobre |
| --- | --- | --- | --- | --- |
| `perimeter_1` | (7; 7; −11,5) | (0; 1; −4) | 54° | `z` 0,4 … −9,5 |
| `perimeter_2` | (6; 8; −6) | (1; 1; −13) | 48° | `z` −9,4 … −19,6 |
| `perimeter_3` | (7,4; 7; −17) | (0; 1,2; −24) | 52° | `z` −19,5 … −26,8 |

Cada pose foi escolhida por varredura: precisa conter todo o volume caminhável
da própria zona em 1920 × 1080 com margem, manter Dylan entre ~110 e ~190 px de
altura e deixar o banco e o ombro próximos livres da linha até o meio do corpo.
O probe repete a parte da moldura a cada quadro durante a caminhada.

**`perimeter_2` girada em 13/10/2026.** A pose original, em (−7,4; 7; −11,5), olhava
o corredor de lado: subir a trilha era "baixo" na vista 1, "esquerda" na 2 e "cima"
na 3, e quem soltava o direcional depois do corte perdia o rumo. A nova pose fica
a sudeste do cercado e olha trilha acima, a 35,5° de guinada, perto dos 46,6° da
vista 3: na 2 e na 3, cima é cima. Dylan fica entre 121 e 157 px em toda a zona.
O corte 1 → 2 continua sendo o contraplano clássico (a vista 1 olha para o portão),
amortecido pelo direcional travado enquanto segurado. `check_perimeter.gd` exige
que a 2 olhe para o norte e concorde com a 3.

A placa `art_cam02_v02.png` pertence à pose antiga e saiu de `ART_FILES`: a vista 2
mostra geometria até a nova placa existir (`authored/ART_CAM02_V03_PROMPT.txt`,
referência `geometry_cam02.png`).

**Arte integrada em 12/10/2026.** As três placas em
`assets/backgrounds/perimeter/authored/art_cam0{1,2,3}_v02.png` são carregadas
por `ART_DIR`/`ART_FILES` em `environments/perimeter.gd`. B alterna arte e
geometria. Foram geradas com image_gen integrado, usando cada captura de
geometria como referência de composição e o exterior existente como referência
de materiais e clima. Prompts completos em `authored/ART_CAM0{1,2,3}_PROMPT.txt`.
As câmeras, colisores e geometria de origem permanecem os mesmos.

A revisão v02 usa uma direção comum em `authored/ART_DIRECTION.txt`: neve
contínua, menos granulação artificial, materiais e exposição consistentes,
sem pixelização pintada (o filtro do jogo cuida disso). A vista final do galpão
foi usada como referência da vista central, eliminando a luminária duplicada
e igualando a placa da porta, o tambor e os materiais. Prompts finais em
`authored/ART_CAM0{1,2,3}_CLEAN_PROMPT.txt`.

**Câmera 3 refeita em 13/10/2026.** `art_cam03_v03.png` substitui a v02
na apresentação do galpão. A captura `geometry_cam03_current.png`, feita por
`tools/capture_perimeter_cam03.gd` diretamente da cena jogável, orienta a
composição; a câmera 2 v03 orienta somente materiais e iluminação. A nova
arte aproxima o prédio, tronco, arame lateral e massas rochosas da geometria,
preservando a passagem à direita do tronco. Prompt em
`authored/ART_CAM03_V03_PROMPT.txt`. As versões anteriores estão preservadas.
`check_perimeter.gd` gráfico: 2370 ticks, zero falhas; capturas da passagem e
da porta inspecionadas. A validação cobre circulação e composição visual,
sem certificação de alinhamento de todos os contornos em pixels.

## O Keleken

Saiu do exterior. `KelekenWander` ganhou `home_position`, então a patrulha é
configurada pelo cenário em vez de ficar presa a coordenadas da estrada:

- casa em (0,6; 0,06; −14,5), limites `x` −2,3 … 2,3 e `z` −19 … −10,5;
- `combat_enabled` continua ligado: percepção, perseguição, bicada e morte são
  os mesmos descritos em `COMBAT.md`;
- Reiniciar devolve o animal ao cercado e Dylan à entrada da trilha.

O exterior ficou sem inimigo. A caminhada autoral de `check_exterior.gd`, que
antes desligava o bicho para não ser interrompida, agora exige que ele **não**
esteja lá.

## Testes

| Probe | O que cobre |
| --- | --- |
| `perimetro` (`tests/check_perimeter.gd`) | cadeia declarada, portão trancado/liberado, viagem nos dois sentidos, chegada, moldura das três câmeras, paredes do corredor, fim de fase no galpão, reinício de fase e registro intacto |
| `combate-inimigo` | mesmo combate de antes, agora dirigido na trilha |
| `keleken-wander` | patrulha dentro do cercado, sem provocar cortes de câmera |
| `exterior-geometria` | o exterior segue íntegro com o quarto enquadramento e sem inimigo |

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_all.gd -- --only=perimetro,combate-inimigo,keleken-wander,exterior-geometria
```

## Limites

Validação da integração: `check_perimeter.gd` passou em headless e Forward+
na RTX 5060 (2352 ticks, zero falhas), com imagens sincronizadas nos cortes,
ida/volta pelo portão e alternância arte/geometria. Capturas em
`.local/perimeter-art-*.png` inspecionadas nas três vistas e no pátio norte.
`check_exterior.gd` headless também passou (4100 ticks, zero falhas).

- Sem áudio e sem ponto de salvamento na trilha: o registro continua
  sendo feito no terminal da guarita, antes do portão.
- **Desde 14/10/2026 o pátio provisório saiu da trilha**: a porta dos fundos do
  relé leva ao pátio de serviço (`SERVICE_YARD.md`), e a trilha voltou a três
  enquadramentos. O que segue sobre `perimeter_4` é histórico.
- Desde 12/10/2026 (noite) a porta do relé abre para a Fase 3 (`RELAY_ROOM.md`),
  e a saída pelos fundos do galpão leva ao enquadramento provisório `perimeter_4`,
  com limites invisíveis e placa `art_cam04_v01.png` desde 13/10/2026.
  O conteúdo termina ali (`REAR_YARD`). A câmera reposicionada `perimeter_2`
  usa agora `art_cam02_v03.png`; inventário em `RELAY_ART_2026-10-13.md`.
- O quarto enquadramento do exterior (`exterior_4`, o pátio norte até o portão)
  usa `assets/backgrounds/env_1/exterior_authored/art_cam04_v02.png`, com prompt
  ao lado. `tools/capture_north_yard.gd` captura a fonte/câmera atuais sem
  regenerá-las. A primeira tentativa mudou a perspectiva e foi descartada;
  a versão integrada preserva o enquadramento elevado.
- A vista da cancela usa `art_cam02_v04.png`: o trecho da parede de fundo agora
  mostra o portão norte na projeção da geometria atual, também dentro do crop
  existente. Prompts `ART_CAM02_GATE_PROMPT.txt` e `ART_CAM02_CLEAN_PROMPT.txt`.
  `capture_north_yard.gd -- --yard` reproduz a referência sem crop para edição.
- As placas são candidatas: a inspeção visual não equivale a uma medição
  independente de erro em pixels. Neve, galhos e rochas têm contornos que podem
  diferir dos volumes de oclusão. Não houve exportação, benchmark nem soak.
