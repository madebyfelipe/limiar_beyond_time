# Dylan animado e transição de porta

11/10/2026. Implementação solicitada: animar Dylan e criar uma passagem de porta com o ritmo dos survival horrors de câmera fixa. Modelo e sons da transição são autorados neste projeto.

## Jogar

Abra `executar-exterior.cmd`. WASD/setas movem; Shift corre. Atravesse a cancela, suba a escada e pressione **E** quando aparecer “Abrir porta e entrar”. Na sala, E junto à entrada mostra a abertura e devolve Dylan ao patamar externo. Também é possível iniciar pelo interior com `executar-sala.cmd`.

R reinicia o ambiente atual; B compara arte/geometria; C na sala abre a câmera técnica. Esc fecha. A sequência bloqueia entrada de gameplay até a chegada; novas pressões de E e repetição de tecla não iniciam transições sobrepostas.

F5 continua no percurso técnico. Esta implementação não alterou o preset de exportação T10 nem criou uma nova build.

## Animação do personagem

`actors/player/dylan_visual.gd` gera quatro clipes no AnimationPlayer, usando 33 amostras por clipe e os ossos do rig importado:

| Clipe | Duração | Comportamento |
| --- | --- | --- |
| idle | 3,6 s, loop | Respiração leve e braços relaxados |
| walk | 0,9 s, loop | Pernas alternadas, flexão de joelhos e balanço oposto dos braços |
| run | 0,64 s, loop | Maior passada, braços flexionados e inclinação do tronco |
| door_interact | 0,72 s | Corpo vira para a porta e um braço avança antes do close |

A velocidade real de `CharacterBody3D` seleciona idle/walk/run e regula a velocidade de reprodução. Encostar em um obstáculo deixa de reproduzir deslocamento quando o corpo para. Blends de 0,16 s suavizam as trocas. Não há root motion; o controlador existente continua responsável por movimento/colisão.

Eixos de rotação são convertidos pela orientação já posada dos ancestrais, incluindo o abaixamento dos braços, para evitar flexionar cotovelos no plano errado. GLB, malha e skin não foram alterados. SHA-256 preservado: `AEDBDF9C15EF225481FFA4630963C7F636702A071EB5CA5CC077B72CBE2816B1`.

Exterior e sala instanciam Dylan com altura visual/colisão de 1,8 m, conforme a porta de 2,1 m e as câmeras autoradas. Os ensaios dos renders originais continuam com 2,4 m, escala ampliada anteriormente pelo usuário.

São clipes procedurais de protótipo, sem captura de movimento, IK de pés ou mão presa à maçaneta. A geometria das portas/cenários e os fundos candidatos não foram regenerados.

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

A saída usa abertura no sentido oposto e restaura a câmera próxima da guarita. Não há autoload. O terminal da sala permanece sem salvamento persistente.

Os sons `assets/audio/door_latch.wav` e `door_creak.wav` foram sintetizados deterministicamente por `tools/author_door_audio.py`, sem samples externos. Headless não reproduz áudio; execução gráfica usa AudioStreamPlayer.

## Reprodução e verificação

```powershell
$DylanGodot = '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $DylanGodot --headless --path . --editor --import --quit
& $DylanGodot --headless --path . --fixed-fps 60 --script res://tests/check_dylan_doors.gd
& $DylanGodot --path . --fixed-fps 60 --script res://tests/check_dylan_doors.gd
& $DylanGodot --path . --fixed-fps 60 --script res://tools/preview_dylan_animation.gd
```

O probe percorre o exterior pelo controlador real, confere mudança dos ossos, seleção walk/run e retorno a idle, rejeita E distante/echo e completa entrada e retorno pela porta. Verifica bloqueio de movimento/R durante o gesto, uma única transição, ordem das etapas, preto no momento da troca, controle restaurado, entrada correta e câmera do patamar na saída. A execução gráfica também cobre janela 4:3.

O executor inclui `dylan-portas` e `dylan-portas-grafico`. Logs/capturas em `.local`; relatório consolidado em `TEST_REPORT.md`.

Resultado final nesta sessão Windows: **17 probes, 0 falhas, saída 0**, incluindo ambos os modos da porta, circulação da sala/exterior e renderização do percurso. Probe da porta: **962 ticks, zero falhas**. Imagens de poses e da abertura/chegada foram inspecionadas. Resumo e duas capturas preservados em `docs/evidence/dylan`.
