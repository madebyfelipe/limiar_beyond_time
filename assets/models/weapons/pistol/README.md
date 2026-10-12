# Pistola LIMIAR — protótipo original

Modelo visual de pistola para o estilo PSX do projeto, criado em 12/10/2026.

- `pistol_lowpoly.glb`: 756 triângulos, uma malha e seis materiais PBR embutidos; sem texturas externas, rig ou animação.
- `source/pistol.blend`: fonte Blender editável, com câmera e luzes apenas para prévia; o diretório é ignorado pelo importador Godot.
- `pistol_preview.png`: render do modelo efetivamente exportado.
- `pistol_concept_v01.png`: referência visual gerada com a ferramenta image_gen integrada. Não é textura nem reconstrução automática do GLB.
- `manifest.json`: orientação, unidades e contagem da geometria.

A geometria foi autorada por código em `tools/build_pistol.py`, com primitivas e perfis externos originais, usando a referência gerada como direção visual. Não foram baixadas malhas de terceiros. Modelo de protótipo, sem aprovação canônica implícita e sem mecanismo interno funcional.

Godot: metros, frente −Z, cima +Y, origem na empunhadura. O nó `Muzzle` marca a ponta visual para o traçador. O adaptador `actors/player/dylan_visual.gd` ajusta escala à altura do Dylan e posiciona a arma após a pose de mira; ela aparece enquanto a arma está erguida e some ao abaixar ou interagir.

O GLB já é usado no exterior, sala e estande pelas instâncias de Dylan. Abra `executar-estande.cmd` para experimentar; segure a mira. A pose dos braços e dedos continua procedural, sem clipes dedicados de disparo ou recarga.

Para regenerar fonte, GLB, manifesto e prévia:

```powershell
& '.tools/blender-4.5.3/blender-4.5.3-windows-x64/blender.exe' --background --factory-startup --python-exit-code 1 --python tools/build_pistol.py
```

O gerador substitui esses derivados. Para preservar edições manuais, salve uma cópia da fonte antes de regenerar.

Validação: importação no Godot, combate/cenas/portas/gamepad headless (quatro probes, zero falhas), combate gráfico e captura de empunhadura. O teste de combate confere a malha importada, associação do marcador, direção do cano, posição da ponta e proximidade à mão. Build exportada ainda não validada.
