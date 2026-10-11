# Correção do poste de luz — vista 2 do exterior

Pela diretriz "exatidão geométrica só onde o jogador interage", só a **vista 2** precisa da correção. O poste tem colisor no pátio, área que o jogador alcança nessa vista. Na vista 1, o jogador fica na estrada (z ≥ 14) e o poste (z = 8,9) está sempre atrás dele; a vista 3 não mostra o poste.

## Entradas para gerar a imagem

| Imagem | Arquivo | Papel |
| --- | --- | --- |
| IMAGE 1 | `assets/backgrounds/env_1/exterior_authored/art_cam02_v02.png` | arte atual a editar |
| IMAGE 2 | `cam02_pole_guide.png` | ciano = posição obrigatória do poste e da luminária; vermelho = única área editável |
| IMAGE 3 | `cam02_geometry_reference.png` | captura da geometria na resolução da arte (autoridade espacial) |
| Máscara (opcional) | `cam02_pole_edit_mask.png` | branco = área editável, para ferramentas de inpainting |

Prompt: `../ART_CAM02_POLE_FIX_PROMPT.txt`. Todas as imagens têm 1672×941, a mesma resolução da arte.

Medidas do alvo, nas coordenadas da arte (1672×941): o topo do fuste fica sob a luminária, em ≈ (1173; 440); o fuste desce inclinado para a esquerda até sumir atrás do muro, em ≈ (1079; 779). Hoje o poste pintado fica de 26 a 50 px (em 1080p) à direita disso e quase vertical.

## Depois de gerar

1. Salvar como `assets/backgrounds/env_1/exterior_authored/art_cam02_v03.png`, mantendo a v02 como histórico.
2. Em `environments/exterior.gd`, trocar `art_cam02_v02.png` por `art_cam02_v03.png` em `ART_FILES`.
3. Verificar o alinhamento: `python tools/calibration/exterior_alignment_overlay.py 2 .local/pole-check.png --zoom 2 1180,440,240,500`. O poste pintado deve cobrir as bordas magenta do poste.
4. Rodar `check_exterior.gd` em headless e gráfico.
