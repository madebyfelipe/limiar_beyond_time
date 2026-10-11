# Evidências visuais versionadas

`retro/`: imagens originais do renderer nos modos Original, PSX e PSX + CRT (`tests/check_retro_filter.gd`), porta com CRT (`tests/check_dylan_doors.gd`) e resumo das sete regressões aprovadas no Windows/RTX 4050 Laptop GPU em 11/10/2026. São evidências visuais e funcionais, sem medição de desempenho.

Atualização local: `dylan/` contém capturas da abertura da porta e chegada à sala, mais resumo das 17 regressões aprovadas em 11/10/2026 no Windows, Godot 4.7.2/Forward+/RTX 4050 Laptop GPU. São imagens do renderer, inspecionadas nesta integração; não representam medição de desempenho nem a GPU de referência. Origem: `tests/check_dylan_doors.gd`, execução gráfica. O restante deste índice descreve as evidências históricas.

Capturas reais geradas pelos probes durante a sessão em nuvem de 11/10/2026 (contêiner Linux efêmero). Como esse ambiente é descartado, um subconjunto pequeno foi copiado para cá; as demais capturas e logs continuam locais e ignorados pelo Git, como no resto do projeto.

- Renderizador: Godot 4.7.2 oficial para Linux (mesmo commit `ed1daf0bf` do executável Windows), Forward+/Vulkan sobre Mesa **llvmpipe** (CPU) em Xvfb 1920×1080.
- Renderização por software não mede desempenho. FPS/tempo de quadro visíveis no overlay F3 dessas imagens refletem o llvmpipe e `--fixed-fps 60`, não a RTX 5060 de referência.
- `t10/benchmark-*.txt` são os relatórios do modo `-- --benchmark` na build de release (llvmpipe); servem como formato de referência, não como medida do gate.
- Cada imagem foi inspecionada antes de ser registrada; a descrição e o comando de origem estão em `docs/PROGRESS.md`.

- `exterior/`: sobreposições das bordas da geometria autorada sobre as três artes do exterior e a comparação do poste de luz, da verificação de alinhamento registrada em `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`.
