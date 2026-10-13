# Arte, portas e menus — 12/10/2026

Base atualizada por `git pull`: `6545f30` → `23f98d6` (main, fast-forward).
Geração e edições com image_gen integrado; prompts completos preservados.

## Assets ativos

| Asset | Prompt final |
| --- | --- |
| `assets/backgrounds/env_1/exterior_authored/art_cam02_v04.png` | `ART_CAM02_CLEAN_PROMPT.txt` no mesmo diretório; adição do portão em `ART_CAM02_GATE_PROMPT.txt` |
| `assets/backgrounds/env_1/exterior_authored/art_cam03_v02.png` | `ART_CAM03_CLEAN_PROMPT.txt` no mesmo diretório |
| `assets/backgrounds/env_1/exterior_authored/art_cam04_v02.png` | `ART_CAM04_CLEAN_PROMPT.txt` no mesmo diretório |
| `assets/backgrounds/perimeter/authored/art_cam01_v02.png` | `ART_CAM01_CLEAN_PROMPT.txt` no mesmo diretório |
| `assets/backgrounds/perimeter/authored/art_cam02_v02.png` | `ART_CAM02_CLEAN_PROMPT.txt` no mesmo diretório |
| `assets/backgrounds/perimeter/authored/art_cam03_v02.png` | `ART_CAM03_CLEAN_PROMPT.txt` no mesmo diretório |
| `assets/textures/doors/painted_steel_v01.png` | `painted_steel_v01.prompt.txt` no mesmo diretório |
| `assets/ui/retro_terminal/pause_menu_skin_v03.png` | `pause_menu_skin_v03.prompt.txt` no mesmo diretório |

Direção compartilhada em `assets/backgrounds/perimeter/authored/ART_DIRECTION.txt`:
materiais consistentes entre câmeras, neve contínua, menos ruído e manchas,
construção coerente dos objetos e pixelização deixada ao filtro do jogo.
O galpão agora tem uma só luminária retangular e a mesma placa opaca na porta
nas duas vistas. Câmeras, colisores e geometria jogável foram preservados.
Na revisão complementar da vista próxima da guarita, `art_cam03_v02.png`
substitui a v01: inclui o portão conforme `geometry_cam03_gate.png` e iguala
concreto, neve e janela frontal à vista 2. A referência é reproduzida com
`tools/capture_north_yard.gd -- --guardhouse`.
São placas candidatas; não há certificação de correspondência em pixels.

## Integração

- O portão norte aparece na arte da vista da cancela e na vista próxima.
- A porta animada recebe textura em projeção local, sem deslizar ao girar.
- Todas as quatro travessias informam a região de destino durante a abertura.
- Pausa, configurações e remapeamento usam a skin limpa; títulos e rodapés são
  textos reais, sem retângulos sólidos apagando partes da moldura.
- `tools/preview_door_menu.gd` reproduz capturas de porta e menus em 16:9 e 4:3
  sem modificar salvamentos.

## Validação

- `check_exterior.gd`: headless, 4100 ticks, zero falhas, geometria e arte.
- `check_dylan_doors.gd`: headless e Forward+, 1164 ticks, zero falhas;
  ida/volta, textura, nome de destino, animação e retorno do controle.
- `check_settings.gd`: headless e Forward+, zero falhas; teclado, mouse,
  gamepad, remapeamento e persistência, incluindo 4:3.
- `check_perimeter.gd`: headless e Forward+, 2352 ticks, zero falhas;
  a execução gráfica final com as cinco placas revisadas também passou.
  Capturas finais e log em `.local/final-art-perimeter.*`; o portão foi
  conferido em `.local/perimeter-art-yard-approach.png` na câmera enviada.
- Importação sem erros de script/shader; `git diff --check` sem erros.

Capturas locais: `.local/review-*.png`, `.local/settings-*.png`,
`.local/dylan-door-*.png` e `.local/perimeter-art-*.png`.
Sem exportação de build, benchmark ou execução da suíte completa.
