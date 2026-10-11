# Sala da guarita — geometria antes da arte

Atualização de 11/10/2026: a sala agora recebe Dylan animado de 1,8 m, abre com a arte aplicada e se conecta ao exterior por **E** junto à porta, com transição de abertura em 3D. Os resultados anteriores com cápsula permanecem históricos. Não foi implementada persistência de salvamento. Ver `../DYLAN_ANIMATION.md`.

Data: 11/10/2026. Fluxo autorizado: geometria simples → câmera → teste de circulação → captura 3D → arte com imagegen. A câmera foi aproximada a pedido do usuário antes da última geração.

## Entregas

- Fonte espacial editável: `environments/save_room_source.tscn`, autorada por `tools/author_save_room.gd`.
- Cena de inspeção jogável: `environments/save_room.tscn`; abrir com `executar-sala.cmd` ou F6.
- Sala de trabalho: 6 × 5 m, paredes de 3,1 m; cápsula de 1,8 m. São medidas propostas para o interior, ainda sem alinhamento com a geometria externa ENV_1.
- Porta, piso, quatro limites físicos, mesa, cadeira, armário, estante/cabinete e baú. Dez corpos estáticos copiados da mesma fonte espacial. Não existe persistência de salvamento neste estudo.
- Câmera de interior: posição (2,8; 2,9; 2,35), alvo (−0,5; 0,9; −0,7), FOV vertical de 45°. Pose exata em `resources/save_room/shot_01.tres` e `assets/backgrounds/env_1/save_room/camera.json`.
- Captura 3D autoritativa de 1920×1080: `assets/backgrounds/env_1/save_room/geometry_cam01.png`. Sem bordas externas da sala; piso e paredes ocupam o quadro.
- Arte derivada dessa captura, gerada pela ferramenta integrada image_gen: `assets/backgrounds/env_1/save_room/art_cam01_close_v01.png`. Imagem anterior com a câmera ampla: `art_cam01_v01.png`.
- Prompt completo da geração próxima: `docs/calibration/SAVE_ROOM_CLOSE_PROMPT.txt`. O conceito inicial sem geometria continua separado em `concepts/save_room_v01.png`.

## Controles e alcance

WASD/setas movem; Shift corre; R reinicia; Esc fecha. B compara geometria e arte candidata, com câmera e colisores compartilhados. C alterna interior e visão técnica ampla, que permite inspecionar toda a sala e desliga a arte.

A vista próxima cobre o trajeto entrada → terminal → entrada. A região da sala próxima da posição da própria câmera sai desse enquadramento; a inspeção completa usa C. Uma versão de produção precisa de enquadramentos adicionais e zonas de corte para cobrir essa região. Não foram criados cortes automáticos neste estudo.

## Verificação

`check_save_room.gd` usa controlador e entrada reais. Percorre a rota da vista próxima sem teleportes e confere corpo inteiro dentro do quadro; na câmera de inspeção percorre o restante da sala e empurra contra quatro paredes e móveis. Verifica chão, limites, reinício e alternância de arte/geometria, incluindo ida ao terminal e retorno com a arte aplicada. Resultado final: 2205 ticks, 42,00 m acumulados, zero falhas em headless e gráfico; captura final da composição com arte em `.local/save-room-art.png`.

Primeiro estudo amplo: 1420 ticks, 23,16 m, zero falhas. Após aproximar, o teste detectou saída do enquadramento em (1,082; 0,001; 0,118). A cobertura da vista próxima foi delimitada explicitamente e a visão ampla ficou disponível como ferramenta de inspeção. Não se declarou cobertura de toda a sala pela câmera próxima.

Os renders e a composição foram inspecionados visualmente. A arte mantém a composição geral, mas ainda é candidata: imagegen acrescentou detalhes de cadeira, molduras e superfícies; não há medição independente de seis correspondências ou gate de 8 px aprovado para a imagem final. Colisões aprovadas no 3D não comprovam alinhamento exato dos contornos da arte. A prévia identifica esse estado na tela.

## Reprodução

```powershell
$RoomGodot = '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $RoomGodot --path . --script res://tools/author_save_room.gd
& $RoomGodot --headless --path . --editor --import --quit
& $RoomGodot --headless --path . --fixed-fps 60 --script res://tests/check_save_room.gd
& $RoomGodot --path . --fixed-fps 60 --script res://tests/check_save_room.gd
```

Regenerar a fonte/captura invalida a correspondência com a arte se câmera ou objetos mudarem. A cena principal e o preset do percurso técnico continuam apontando para T07/T10; esta sala é um estudo isolado.
