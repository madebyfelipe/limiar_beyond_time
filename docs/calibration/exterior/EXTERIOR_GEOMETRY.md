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

## Verificação independente de alinhamento arte × geometria — sessão em nuvem, 11/10/2026

Pedido do usuário: verificar o exterior gerado a partir da geometria. Nenhum asset, cena ou ficha foi alterado nesta verificação.

**Método.** Cada arte ativa (1672×941) foi escalada para 1920×1080, como o `TextureRect` e o shader de oclusão a apresentam, e as bordas de silhueta da captura `geometry_camNN.png` correspondente foram sobrepostas (`tools/calibration/exterior_alignment_overlay.py`). Em seguida, recortes ampliados (2–3×) com grade de 10 px foram lidos à mão por estrutura. Os cantos 3D foram projetados pelas fichas `shot_*.tres` com `Camera3D.unproject_position`; o centro da porta reproduziu exatamente o `cameras.json` (1161,151; 135,337). Uma correlação automática de gradientes foi testada e descartada: a textura da IA gerou picos falsos (confiança 0,15–0,50), então a leitura final é visual, com precisão aproximada de ±3 px. A anisotropia da escala 1672×941 → 1920×1080 é de 0,05% (≤ 0,3 px).

| Estrutura | Vista 1 (estrada) | Vista 2 (cancela) | Vista 3 (guarita) |
| --- | --- | --- | --- |
| Paredes, quinas e telhado da guarita | ≤ 5 px | ≤ 5 px | ≤ 10 px (a arte engrossa o telhado com neve) |
| Porta, visor e janelas | ≤ 5 px | ≤ 5 px | ≤ 5 px |
| Escada, plataforma e corrimãos | ≤ 5 px | ≤ 5 px | 2–5 px |
| Caixas | ≤ 5 px | ≤ 5 px | 2–5 px |
| Braço da cancela | ≤ 5 px | 5–10 px | — |
| Guard rails e postes da estrada | 2–5 px, todos os postes | ≈ 5 px | — |
| Base/plinto e marcas de pneu | ≈ 10 px | ≈ 10 px | 5–10 px |
| **Poste de luz** | **≈ 75 px** (coluna à esquerda; luminária ≈ 20 px) | **15 px no topo, 26–50 px no fuste e ≈ 45 px na base** | fora do quadro |
| Pinheiros | decorativos, formas diferentes; na vista 1 a árvore próxima da direita cobre muro e poste que a arte mostra | decorativos | decorativos |

**Leitura.** Tudo o que o jogador toca no trajeto (estrada, guard rails, cancela, escada, corrimãos, plataforma, porta e caixas) coincide com a geometria dentro de ~10 px, e na maior parte dentro de 5 px. A exceção é o poste de luz: a geometria projeta um poste vertical com a convergência de uma câmera que olha para baixo (inclinado na imagem), enquanto a IA o desenhou quase vertical e mais grosso. Na vista 2, o fuste medido na arte (coluna mais escura por linha) fica de 26 a 50 px à direita do eixo projetado, cerca de 1 m no chão perto da base. Consequência no jogo: o colisor e o oclusor do poste ficam deslocados do poste pintado. O jogador pode bater num poste invisível ou ser recortado por um "poste" que mostra neve, mas só ao andar no canto sudeste do pátio, fora do trajeto estrada → cancela → escada. A diferença dos pinheiros na vista 1 não atinge a estrada: o raio câmera → estrada passa à esquerda dos cones.

**Veredito.** O gate de ≤ 8 px por vista **não passa como conjunto** por causa do poste de luz (vistas 1 e 2) e da tolerância um pouco maior do telhado e do plinto. As estruturas jogáveis do trajeto estão alinhadas. Correção recomendada: editar ou regenerar o poste nas artes 1 e 2 seguindo a inclinação projetada da captura de geometria, sem mexer no resto da imagem. Mover o poste 3D não resolve, porque um poste desenhado vertical na imagem não corresponde a nenhuma posição 3D nas duas vistas ao mesmo tempo.

**Reprodução e testes desta sessão (Linux, Godot 4.7.2 oficial, Mesa llvmpipe).** `check_exterior.gd` headless: 3488 ticks, 99,41 m, 0 falhas; gráfico: 3498 ticks, 99,47 m, 0 falhas, cortes 1→2→3→2→1 em geometria e arte. Os números são idênticos aos do Windows. Capturas de jogo em modo arte inspecionadas: ator sobre a estrada, junto à cancela, na base da escada e na porta, mais barras 4:3. Sobreposições versionadas em `docs/evidence/exterior/overlay-cam0{1,2,3}.jpg` e comparação do poste em `docs/evidence/exterior/light-pole-geometry-vs-art.jpg`.

### Reavaliação pela diretriz "exatidão só onde o jogador interage"

Em 11/10/2026 o usuário definiu que a exatidão geométrica só deve preocupar nas áreas em que o jogador interage. Aplicando a diretriz à medição acima:

- **Dentro da meta:** estrada e guard rails (2–5 px), cancela (≤ 5 px na vista 1, 5–10 px na vista 2, no limite), escada, corrimãos, plataforma e porta (≤ 5 px), caixas (≤ 5 px), muros do perímetro que limitam o pátio (≈ 5–10 px no plinto). O trajeto estrada → cancela → escada → porta atende à exigência.
- **Isentos:** pinheiros, telhado (≤ 10 px, inalcançável), floresta e céu, e a árvore próxima da vista 1, que não cruza a estrada.
- **Único ponto pendente:** o poste de luz. Ele é decorativo, mas tem colisor no canto sudeste do pátio, área que o jogador alcança. Pela diretriz há duas saídas: remover o colisor/oclusor do poste (ou bloquear aquele canto), deixando-o como fundo, ou corrigir o poste pintado nas artes 1 e 2. Nenhuma das duas foi aplicada; aguarda decisão do usuário.

**Decisão do usuário (11/10/2026): corrigir a arte.** Só a vista 2 precisa ser editada, pelo critério de interação. Material para a geração em `pole_fix/` (guia com o poste-alvo em ciano, máscara de edição e referência de geometria na resolução da arte) e prompt em `ART_CAM02_POLE_FIX_PROMPT.txt`. A arte v02 continua ativa até a nova versão ser gerada, integrada e verificada.
