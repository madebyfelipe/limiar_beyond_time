# Candidatas cam03 — não aprovadas

Ferramenta: imagegen nativa, edição de imagem com a skill imagegen. Os originais permanecem intactos. As duas candidatas foram rejeitadas para uso nas cenas por desalinhamento da base da escada; não são assets calibrados.

- V1: E:\LIMIAR\assets\backgrounds\env_1_candidates\cam03_v1.png
- V2: E:\LIMIAR\assets\backgrounds\env_1_candidates\cam03_v2.png
- Entrada V1: original cam03. Entrada V2: candidata V1.
- Dimensão de ambas: 1672 × 941.
- Avaliação e contexto: E:\LIMIAR\docs\calibration\ENV_1_CONTINUITY.md

## Prompt V1 completo
Use case: precise-object-edit.
Asset type: fixed-camera snowy guardhouse game background, calibration candidate.
Input image 1 is the edit target. Preserve its exact composition, viewpoint, cold nighttime lighting, colors, snowy forest, roof, tower, boxes, barrels, fence, lamp pole, striped barrier and road. No character, UI, text, markers, or added objects.
Make a very local geometric correction ONLY to the front doorway and stair flight immediately below it. Coordinate system is the original 1672 by 941 pixel frame; if output resolution differs scale all coordinates proportionally and preserve full framing.
Door opening four corners should be: upper-left (744.6,319.9), upper-right (811.0,324.7), lower-right (811.8,520.4), lower-left (747.4,508.8). Preserve the dark metal door and small window.
Correct the stairs' bottom outer left support/contact to (817.0,645.5), and bottom outer right support/contact to (966.1,667.7). This intentionally raises the left foot and lowers the right foot relative to the current image, so the bottom crosswise edge slopes slightly down toward the right. Rebuild the short flight, snow-covered treads and metal handrails coherently between that lower crosswise line and the existing raised platform in front of the door. Keep stair count, materials and approximate width. Blend only the small adjacent snowy contact area naturally. This is a precise perspective adjustment, not a new composition or a stylistic reinterpretation. Preserve everything outside this local doorway/stair region as closely as possible. Output a single clean full-frame landscape background, no comparison panels, no annotations.

## Prompt V2 completo

Use case: precise-object-edit. Image 1 is a snowy guardhouse background to correct. Preserve full 1672x941 composition and every detail outside the stair flight. This is a second precision pass, not a redesign.
The bottom edge of the stair flight is still too horizontal and extends too far to the right. Change only the staircase and both lower rail ends: move the LEFT bottom foot/contact UP by 29 pixels to exactly (817,646), and move the RIGHT bottom foot LEFT by 21 pixels to exactly (966,668). The final bottom crosswise stair edge MUST slope DOWN FROM LEFT TO RIGHT about 8.4 degrees, with its left endpoint 22 pixels higher than its right endpoint. Do NOT make the bottom edge horizontal or slope the other way. Rebuild each successive snow-covered tread and the side rails coherently to connect this corrected lower edge to the existing top platform, which stays fixed. Repaint the vacated sliver below/along the old stair base as the same snowy ground. Do not change door, building, barrels, crates, pole, gate, fence, road, snow elsewhere, lighting or camera crop. No annotations or text. Output only the corrected full background at same framing.
