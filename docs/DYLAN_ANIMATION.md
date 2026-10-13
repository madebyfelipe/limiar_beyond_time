# Dylan animado e transição de porta

11/10/2026. Implementação solicitada: animar Dylan e criar uma passagem de porta com o ritmo dos survival horrors de câmera fixa. Modelo e sons da transição são autorados neste projeto.

## Jogar

Abra `executar-exterior.cmd`. WASD/setas movem; Shift corre. Atravesse a cancela, suba a escada e pressione **E** quando aparecer “Abrir porta e entrar”. Na sala, E junto à entrada mostra a abertura e devolve Dylan ao patamar externo. Também é possível iniciar pelo interior com `executar-sala.cmd`.

R reinicia o ambiente atual; B compara arte/geometria; C na sala abre a câmera técnica. Esc fecha. A sequência bloqueia entrada de gameplay até a chegada; novas pressões de E e repetição de tecla não iniciam transições sobrepostas.

F5 continua no percurso técnico. Esta implementação não alterou o preset de exportação T10 nem criou uma nova build.

## Animação do personagem

**Atualizado em 11/10/2026: os clipes procedurais foram substituídos por captura de movimento do Mixamo.** O texto anterior desta seção descrevia senos autorados à mão e é histórico.

`tools/build_dylan_animations.gd` monta `assets/models/dylan_protagonist/mixamo/dylan_clips.res` a partir das quatro capturas e é o único arquivo lido em execução. `actors/player/dylan_visual.gd` troca a biblioteca do AnimationPlayer importado por essa e mantém a mesma API de antes (`animator`, `skeleton`, `target_height`, `play_door_interaction()`, `end_interaction()`).

| Clipe | Captura Mixamo | Duração | Observação |
| --- | --- | --- | --- |
| idle | Breathing Idle | 9,93 s, loop | Respiração e troca de apoio |
| walk | Standard Walk, *In Place* | 1,17 s, loop | Contato de calcanhar, braços em oposição |
| run | Slow Run, *In Place* | 0,73 s, loop | Tronco à frente, passada longa |
| door_interact | Opening Door Inwards | 0,72 s | Recorte de 2,48 s a 3,20 s da captura de 6,37 s |
| walk_back | Walking Backwards, *In Place* | 1,50 s, loop | Marcha à ré dos controles de tanque; carrega 0,61 m/s |
| turn_left / turn_right | Turning In Place (+ *Mirror*) | 0,52 s, loop | Giro no lugar, sem rotação de raiz |

A captura da porta anda até a porta, abre e atravessa; só a janela do alcance e do empurrão foi mantida, e o deslocamento horizontal do quadril ficou congelado no valor do primeiro quadro, para o corpo não escorregar para fora do ponto de aproximação. A duração do recorte é igual ao estágio de gesto de 0,72 s em `door_transition.gd`. As três de locomoção já vieram sem translado de raiz pela opção *In Place* do Mixamo.

A velocidade real do `CharacterBody3D` escolhe idle/walk/run com o mesmo limiar de antes e regula a cadência pela velocidade que cada captura carrega — **1,48 m/s** na caminhada e **2,73 m/s** na corrida, em `NATIVE_SPEED`. Esses números saem do pé plantado: enquanto o pé está no chão, ele viaja para trás sob o quadril exatamente na velocidade em que o corpo deveria avançar. Medir pela amplitude da passada, como foi feito na primeira versão, errava 24% para cima e era a causa do deslize.

Com a cadência presa à velocidade real, o pé fica parado no chão: `tests/check_foot_contact.gd` mede **0,04 m/s** sob um corpo a 1,80 m/s e **0,36 m/s** sob um corpo a 3,80 m/s. Blends de 0,16 s suavizam as trocas; não há root motion, e o controlador continua dono de movimento e colisão.

Andando de ré, Dylan usa captura própria (`walk_back`), não o ciclo para a frente invertido. A troca acontece quando o deslocamento aponta para trás da frente do corpo, com cosseno abaixo de −0,4 — margem que evita piscar entre os dois clipes enquanto ele gira no esquema de câmera.

**Giro no lugar.** A captura `Turning In Place` é um giro único de 110° em 4 s, não um ciclo, e por isso passa por três operações em `build_dylan_animations.gd`:

1. **Janela** 1,80–2,50 s, escolhida por busca: é o trecho cuja pose final mais se aproxima da inicial, entre todas as janelas de 0,7 a 1,8 s com giro aproveitável.
2. **Guinada cancelada** (`unturn`): quem gira o corpo é o controlador, então da captura fica só o trabalho de pés. O cancelamento é absoluto, não relativo ao início da janela — ver a correção de 11/10/2026 abaixo. Guinada medida depois: **0,0°**, contra 10,4° de oscilação natural do idle.
3. **Emenda costurada** (`stitch` 0,25): o fim é cruzado sobre o começo com interpolação esférica, o que fecha o loop. A emenda caiu de **109° para 1°**, somados onze ossos.

`turn_a` gira para a direita e `turn_b`, espelhado, para a esquerda — medido pela direção que o quadril aponta, não pelo nome do arquivo. Desde 12/10/2026, `tank_turn_speed` vale **3 rad/s** (antes 1,5), por pedido de giro mais rápido: meia-volta em 1,05 s. A cadência segue `turn_input`, com 0,887 rad/s de giro próprio da captura e reprodução de 3,38x em entrada máxima; o limite exclusivo dos clipes de pivô passou de 2x para 4x. Caminhada e corrida mantêm seus limites. O probe compara a base dos pés no espaço do corpo para distinguir deslocamento lateral da rotação legítima de uma postura fora do eixo.

**Correção de 11/10/2026 — o pivô jogava o corpo para o lado.** O usuário relatou que, ao girar no modo tanque, o boneco saltava para a esquerda. Eram dois defeitos somados, ambos de recortar uma janela do meio de uma captura:

- A primeira versão do `unturn` zerava a *variação* de guinada, preservando a guinada do primeiro quadro da janela. Como a janela começa em 1,8 s de um giro de 110°, o corpo entrava no clipe já **72,6° virado** e girava a partir dali. Agora a guinada é cancelada em termos absolutos.
- O `plant` congelava o quadril na posição que ele tinha naquele instante, e o ator já havia se deslocado. O corpo saltava **0,18 m para trás** e a base dos pés ia a ±0,15 m do lado. Entrou um passo de recentragem (`_recentre`): cada clipe plantado é deslizado até a média dos seus pés coincidir com a do idle. Correções aplicadas: `turn_right` (−0,039; +0,084), `turn_left` (−0,004; +0,084) e `door_interact` (−0,029; −0,148).

O gesto da porta tinha o mesmo defeito de posição e saltava 0,27 m à frente ao começar; passava despercebido porque o corte para preto vem logo depois.

A suíte passava com os dois defeitos presentes — nenhum probe olhava para onde o corpo apontava. `check_tank_controls.gd` ganhou duas medidas durante o pivô: o ângulo entre a frente renderizada e a direção comandada (limite 15°) e o salto da base dos pés (limite 0,15 m). A asserção foi conferida reintroduzindo o defeito no builder: reprova com **72,6 deg away from its heading** e volta a passar com a correção.

**Velocidades do jogo.** `walk_speed` passou de 2,5 para **1,8 m/s** e `run_speed` de 5,0 para **3,8 m/s** em `player_config.gd`, a pedido de corrigir a sensação de patinação. Nessas velocidades a reprodução fica em 1,22x e 1,39x — cadência natural. Aceleração e desaceleração foram firmadas de 15/20 para **26/40 m/s²**, o que encurta a derrapagem após soltar a tecla para menos de 0,25 m, medido em `tests/check_tank_controls.gd`. Os probes de distância e locomoção agora derivam a expectativa do `PlayerConfig`, em vez de constantes fixas.

O esqueleto agora é o `mixamorig_*` de 65 ossos do auto-rigger, no lugar dos 26 ossos Tripo. O GLB original não foi alterado nem reexportado e seu SHA-256 continua `AEDBDF9C15EF225481FFA4630963C7F636702A071EB5CA5CC077B72CBE2816B1`; procedência, licença, escala e orientação estão em `assets/models/README.md`.

Continua sem IK de pés em degraus e sem a mão presa à maçaneta: a mão faz o gesto de empurrar, mas não acompanha a folha da porta.

## Sequência da porta

`systems/interaction/door_interaction.gd` exige proximidade horizontal de 0,85 m do ponto de aproximação e diferença de altura inferior a 0,25 m. E carrega o destino, interrompe o movimento e inicia o gesto.

`door_transition.gd` cria uma camada temporária que sobrevive à troca de cena:

1. Gesto de Dylan por 0,72 s.
2. Fade para preto e revelação de uma porta metálica 3D isolada, em composição 16:9.
3. Giro da maçaneta por 0,22 s com estalo da trava.
4. Abertura da folha por 1,35 s e aproximação da câmera, com som da dobradiça.
5. Avanço da câmera por 0,65 s e novo fade para preto.
6. Troca do ambiente sob preto, posicionamento na entrada e fade de chegada por 0,3 s.
7. Retorno do controle e liberação da camada, câmera, malhas e áudio temporários.

A saída usa abertura no sentido oposto e restaura a câmera próxima da guarita. Não há autoload. O terminal da sala passou a salvar progresso na mesma data; ver `SAVE_SYSTEM.md`.

Os sons `assets/audio/door_latch.wav` e `door_creak.wav` foram sintetizados deterministicamente por `tools/author_door_audio.py`, sem samples externos. Headless não reproduz áudio; execução gráfica usa AudioStreamPlayer.

## Reprodução e verificação

```powershell
$DylanGodot = '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $DylanGodot --headless --path . --editor --import --quit
& $DylanGodot --headless --path . --script res://tools/build_dylan_animations.gd
& $DylanGodot --headless --path . --fixed-fps 60 --script res://tests/check_dylan_doors.gd
& $DylanGodot --path . --fixed-fps 60 --script res://tests/check_dylan_doors.gd
& $DylanGodot --path . --fixed-fps 60 --script res://tools/preview_dylan_animation.gd
```

O probe percorre o exterior pelo controlador real, confere mudança dos ossos, seleção walk/run e retorno a idle, rejeita E distante/echo e completa entrada e retorno pela porta. Verifica bloqueio de movimento/R durante o gesto, uma única transição, ordem das etapas, preto no momento da troca, controle restaurado, entrada correta e câmera do patamar na saída. A execução gráfica também cobre janela 4:3.

O executor inclui `dylan-portas` e `dylan-portas-grafico`. Logs/capturas em `.local`; relatório consolidado em `TEST_REPORT.md`.

Resultado final nesta sessão Windows: **17 probes, 0 falhas, saída 0**, incluindo ambos os modos da porta, circulação da sala/exterior e renderização do percurso. Probe da porta: **962 ticks, zero falhas**. Imagens de poses e da abertura/chegada foram inspecionadas. Resumo e duas capturas preservados em `docs/evidence/dylan`.

Reexecução após a troca para captura de movimento, 11/10/2026: **29 probes, 0 falhas** em `tests/run_all.gd`, com `dylan-portas` e `dylan-portas-grafico` de novo em 962 ticks e zero falhas. `check_env1_continuity.gd` passou a exigir 65 ossos e `check_dylan_doors.gd` observa `mixamorig_RightUpLeg` no lugar do osso Tripo. Novas capturas de idle/walk/run/door_interact em `.local`, conferidas uma a uma; a altura e a direção dentro do cenário foram checadas em `.local/dylan-exterior-door.png`. Após trocar qualquer FBX, rode `tools/build_dylan_animations.gd` antes dos probes.
