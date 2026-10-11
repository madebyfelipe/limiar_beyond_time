# Evidências visuais versionadas

Capturas reais geradas pelos probes durante a sessão em nuvem de 11/10/2026 (contêiner Linux efêmero). Como esse ambiente é descartado, um subconjunto pequeno foi copiado para cá; as demais capturas e logs continuam locais e ignorados pelo Git, como no resto do projeto.

- Renderizador: Godot 4.7.2 oficial para Linux (mesmo commit `ed1daf0bf` do executável Windows), Forward+/Vulkan sobre Mesa **llvmpipe** (CPU) em Xvfb 1920×1080.
- Renderização por software não mede desempenho. FPS/tempo de quadro visíveis no overlay F3 dessas imagens refletem o llvmpipe e `--fixed-fps 60`, não a RTX 5060 de referência.
- `t10/benchmark-*.txt` são os relatórios do modo `-- --benchmark` na build de release (llvmpipe); servem como formato de referência, não como medida do gate.
- Cada imagem foi inspecionada antes de ser registrada; a descrição e o comando de origem estão em `docs/PROGRESS.md`.

- `exterior/`: sobreposições das bordas da geometria autorada sobre as três artes do exterior e a comparação do poste de luz, da verificação de alinhamento registrada em `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`.
