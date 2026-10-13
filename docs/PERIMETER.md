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
aproximação, mesma cinemática — que só abre quando a fase seguinte foi liberada.
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
- Trecho do cercado entre `z = −10` e `z = −19`: postes, viga, cocho, cama de
  palha. É a área de patrulha do Keleken.
- Pinheiro caído em `z = −22,6` deixa passagem só pelo lado leste.
- Galpão do relé fecha o corredor ao norte, com porta lacrada, mastro e degrau.
- Linha de árvores a x = ±12, fora do corredor e das câmeras.

### Câmeras

| Enquadramento | Posição | Alvo | FOV | Cobre |
| --- | --- | --- | --- | --- |
| `perimeter_1` | (7; 7; −11,5) | (0; 1; −4) | 54° | `z` 0,4 … −9,5 |
| `perimeter_2` | (−7,4; 7; −11,5) | (0; 1; −14,5) | 54° | `z` −9,4 … −19,6 |
| `perimeter_3` | (7,4; 7; −17) | (0; 1,2; −24) | 52° | `z` −19,5 … −26,8 |

Cada pose foi escolhida por varredura: precisa conter todo o volume caminhável
da própria zona em 1920 × 1080 com margem, manter Dylan entre ~110 e ~190 px de
altura e deixar o banco e o ombro próximos livres da linha até o meio do corpo.
O probe repete a parte da moldura a cada quadro durante a caminhada.

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
- O conteúdo termina na porta lacrada do relé. `RELAY` é fim de conteúdo, não
  fim de missão.
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
