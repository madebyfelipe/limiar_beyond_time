# Exterior ENV_1 — espaço autorado antes da arte

11/10/2026. O usuário solicitou aplicar ao exterior o fluxo aprovado da sala: geometria, câmeras, circulação, capturas e geração de arte. Autorizou novos assets e commit/push para main antes e depois. A sala foi publicada primeiro no commit `e546081`.

## Fonte espacial

`tools/author_exterior.gd` constrói `environments/exterior_source.tscn`. Todos os enquadramentos usam essa mesma fonte, em metros. Não se trata de reconstrução dos renders antigos.

- Estrada de serviço com largura visual de 5 m, neve nas margens, duas marcas de pneu e guard rails. Início do percurso: (0; 0,06; 22).
- Cancela aberta na estação z=10, volume físico e cercamento sólido. A IA recebe instrução de manter painéis opacos, compatíveis com os volumes de oclusão.
- Guarita com interior nominal 6 × 5 m, paredes de 3,1 m e plataforma a y=0,6. Origem do interior: (−5; 0,6; 0), giro de 90° em Y. A planta corresponde ao estudo da sala; ainda não há transição jogável entre as duas cenas.
- Seis degraus visuais de 0,1 m, com rampa física contínua de 0,6 m em 1,8 m para o controlador existente, patamar, corrimãos, duas caixas, poste, antena e pinheiros autorais de primitivas.
- 56 corpos físicos independentes da apresentação. O shader existente reproduz a imagem nas malhas mantendo profundidade; alternar arte/geometria não desloca corpos ou câmeras.

As posições e as seis projeções de referência por câmera estão em `assets/backgrounds/env_1/exterior_authored/cameras.json`. Essas projeções descrevem a fonte 3D; não são observações independentes nos novos PNGs.

| Vista | Posição da câmera | Alvo | FOV vertical |
| --- | --- | --- | --- |
| estrada / exterior_1 | (6; 8; 27) | (0; 0,7; 18) | 52° |
| cancela / exterior_2 | (9; 10; 16) | (−1; 1; 7) | 52° |
| guarita / exterior_3 | (2; 7,5; 12) | (−4,8; 1,2; 3,4) | 50° |

As fichas `resources/exterior/shot_*.tres` guardam poses exatas. As zonas usam prioridade 0/1/2, permanência de 0,2 s e CameraDirector/MovementReference existentes. Cortes não teleportam o jogador.

## Capturas e arte

As três capturas `geometry_cam01.png` a `geometry_cam03.png`, de 1920×1080, foram produzidas e inspecionadas antes da geração. Depois de testar ida/volta, image_gen recebeu cada captura como referência estrutural principal e o exterior antigo como referência de clima/material. A vista 1 nova também serviu de referência de estilo para 2 e 3.

Assets ativos na prévia, em `assets/backgrounds/env_1/exterior_authored/`:

- `art_cam01_v01.png`: aproximação pela estrada.
- `art_cam02_v02.png`: entrada/cancela; revisão que remove o poste adicional inventado na geração v01.
- `art_cam03_v01.png`: entrada da guarita, escada e patamar.

Prompts completos e correção estão nos arquivos `ART_CAM01_PROMPT.txt`, `ART_CAM02_PROMPT.txt`, `ART_CAM03_PROMPT.txt` e `ART_CAM02_FIX_PROMPT.txt`, neste diretório. Ferramenta integrada image_gen; sem CLI/API externa. Os originais ENV_1 e suas fichas permanecem separados deste estudo. A v01 da vista 2 é histórico e não é consumida pela cena.

## Abrir e reproduzir

`executar-exterior.cmd`, ou F6 em `environments/exterior.tscn`. Começa com arte quando as três imagens foram importadas. WASD/setas movem; Shift corre; B alterna arte e geometria; R reinicia; Esc fecha. Subir a escada leva até a porta, sem carregar automaticamente a sala. A cena principal e o preset do percurso técnico continuam próprios da T07/T10.

```powershell
$ExteriorGodot = '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $ExteriorGodot --path . --script res://tools/author_exterior.gd
& $ExteriorGodot --headless --path . --editor --import --quit
& $ExteriorGodot --headless --path . --fixed-fps 60 --script res://tests/check_exterior.gd
& $ExteriorGodot --path . --fixed-fps 60 --script res://tests/check_exterior.gd
```

Regenerar a fonte com mudanças de câmera ou geometria invalida a correspondência com as imagens. Não regenerar arte a partir de capturas com jogador/UI.

## Verificação e limites

O probe usa Input e controlador reais, sem teleporte nas idas e voltas. Confere pés/cabeça enquadrados, contato com chão/rampa/patamar, distância por tick, manutenção da referência durante cortes e troca sincronizada de imagem/câmera. Repete em geometria e arte. Desafios separados empurram contra neve da margem, limite da estrada, parede e porta. Captura as três vistas e a composição em janela 4:3.

Resultados: geometria antes da arte, 2048 ticks/53,31 m em headless, zero falhas; gráfico, 2058 ticks/53,37 m, zero falhas. Após aplicar os fundos, headless: 3488 ticks/99,41 m; gráfico: 3498 ticks/99,47 m, zero falhas. Cortes de cada ida/volta: 1→2→3→2→1. A primeira câmera da guarita cortava os pés na entrada; foi corrigida e as capturas finais geradas da nova pose.

Capturas reais em `.local/exterior-{geometry,art}-{road,out-2,out-5,out-8,returned}.png` e `.local/exterior-4x3.png` foram inspecionadas. O executor ganhou os probes da sala e do exterior em headless/gráfico; logs por probe em `.local/tests/`.

Verificação final após a correção v02 e abertura padrão com arte: seleção de oito probes (`cenas,percurso,operacao,calibracao-estudos,sala-geometria,exterior-geometria,sala-grafica,exterior-grafico`) passou com zero falhas. O carregamento percorreu as 20 cenas; os resultados do exterior permaneceram iguais. Esta foi uma seleção pertinente ao conteúdo novo, não uma reexecução da suíte completa da T10.

A arte mantém a composição geral e o percurso pôde ser conferido visualmente, mas está identificada como candidata. Ainda falta um gate independente de correspondências para declarar erro máximo ≤8 px nos novos fundos. Ramos de pinheiros, neve, molduras e detalhes adicionados pela IA não são malhas físicas; a oclusão atual usa os volumes autorados. A janela frontal recebeu tratamento diferente entre vistas e merece continuidade de materiais. Não há sombras dinâmicas de contato, exploração humana prolongada ou medição de desempenho deste novo cenário. Não foi feita exportação do exterior.
