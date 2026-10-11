# Diagnósticos exploratórios ENV_1

Python 3 com NumPy. São diagnósticos opcionais; o projeto Godot não depende de Python.

```powershell
python tools/calibration/env1_pose_diagnostic.py
python tools/calibration/env1_layout_diagnostic.py
```

Os scripts comparam poses candidatas e hipóteses explicitamente declaradas. Não escrevem recursos, malhas ou imagens. Resultados de buscas locais não comprovam impossibilidade de calibrar os renders. Contexto e limites em `docs/calibration/ENV_1_CONTINUITY.md`.

## Exterior autorado — alinhamento arte × geometria

Requer Pillow. Sobrepõe as bordas da captura de geometria à arte ativa escalada para 1920×1080 e, opcionalmente, gera recortes ampliados com grade de 10 px para leitura manual dos deslocamentos. Não altera assets.

```powershell
python tools/calibration/exterior_alignment_overlay.py 2 .local/exterior-overlay-cam02.png
python tools/calibration/exterior_alignment_overlay.py 2 .local/exterior-pole-cam02.png --zoom 2 1180,440,240,500
```

Resultados e veredito em `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`.
