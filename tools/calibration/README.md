# Diagnósticos exploratórios ENV_1

Python 3 com NumPy. São diagnósticos opcionais; o projeto Godot não depende de Python.

```powershell
python tools/calibration/env1_pose_diagnostic.py
python tools/calibration/env1_layout_diagnostic.py
```

Os scripts comparam poses candidatas e hipóteses explicitamente declaradas. Não escrevem recursos, malhas ou imagens. Resultados de buscas locais não comprovam impossibilidade de calibrar os renders. Contexto e limites em `docs/calibration/ENV_1_CONTINUITY.md`.
