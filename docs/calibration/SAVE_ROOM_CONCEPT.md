# Guarita — conceito de sala de salvamento

Data: 11/10/2026. Solicitado pelo usuário: interior da casinha do ENV_1, sala de salvamento estilo Dino Crisis.

- Imagem: `assets/backgrounds/env_1/concepts/save_room_v01.png`.
- Referência arquitetônica/atmosférica: `assets/backgrounds/env_1/env01_cam03_bg.png.png`.
- Gerada com a ferramenta integrada `image_gen`, sem CLI/API externa.
- Estado: conceito visual; não integrado às cenas, sem câmera, medidas, colisões ou oclusores calibrados. Não representa aprovação de continuidade geométrica com o exterior.
- Próximo passo proposto: estabelecer planta e escala da guarita, criar geometria simples e câmera fixa, validar circulação e produzir uma nova passagem de arte a partir da captura 3D. Porta e objetos interativos precisam de tratamento separado na implementação.

Atualização: esse fluxo foi executado em `SAVE_ROOM_GEOMETRY.md`, com fonte espacial, câmera próxima de interior, teste de circulação e nova arte derivada da captura. Esta imagem inicial permanece apenas como conceito histórico.

## Prompt usado

```text
Use case: stylized-concept. Create one 16:9 game environment concept background showing the INTERIOR of the small concrete guardhouse / radio outpost in the supplied exterior reference. The reference is architectural and atmospheric context only: generate an entirely new indoor viewpoint, not an edit of the exterior. It is a compact survival-horror SAVE ROOM, PSX / PlayStation 1 era aesthetic inspired by Dino Crisis and Dino Crisis 2. A believable small rectangular utilitarian room consistent with that weathered concrete snowy-forest outpost, not a mansion or large laboratory. Fixed high three-quarter camera from an upper corner, perspective projection rather than isometric, looking down across the room; the ceiling is out of frame. Broad clearly readable walkable central floor, with a continuous unobstructed route from the closed steel entrance door to the saving terminal. Furnishings placed against walls: a modest metal desk with a chunky CRT computer glowing muted green as the save station, keyboard and old radio equipment; a practical swivel chair tucked in, steel storage locker and modest supply chest, exposed electrical conduit. Weathered concrete walls, worn utilitarian square floor tiles, an appropriate narrow window showing dark snowy pine trees outside, simple industrial light with a quiet warm pool near the desk contrasting cold blue-gray outdoor light. Mood: a lonely safe refuge inside a dangerous abandoned snowy research perimeter, restrained atmosphere, detailed but spatially legible. Render like an evocative late-1990s survival-horror game background: visibly low-poly forms, low-resolution textured surfaces, restrained palette and subtle dithering, baked lighting and crisp silhouettes; not modern glossy photorealism, not cartoon, not extreme pixelation that obscures navigation. Strong single coherent perspective, plausible human scale, clearly defined door threshold and floor-wall contacts. No people, creatures, text, readable labels, logos, HUD, captions, watermarks, image borders or collage. This is visual concept art, not a claim of geometry-calibrated production output.
```
