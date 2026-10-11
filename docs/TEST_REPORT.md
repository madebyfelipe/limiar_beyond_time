# Relatório de testes — percurso técnico (T09)

## PSX/CRT — Windows, 11/10/2026

Godot 4.7.2/Forward+/Vulkan, NVIDIA RTX 4050 Laptop GPU. **7 probes, zero falhas, saída 0**: composição, oclusão, renderização, operação, portas headless/gráficas e filtro retrô. Resumo em `docs/evidence/retro/regression-summary.txt`.

`check_retro_filter.gd` verifica eventos F4/repetição, diferenças visíveis entre os modos, restauração exata da imagem original e seleção mantida ao recriar o ambiente. Pixels virtuais sem variação interna em 1280×720, 1920×1080 e 1280×960; barras pretas intactas. Teste de portas agora verifica CRT tanto no close quanto nas duas chegadas. Regressões de composição/oclusão mantêm zero emendas. Imagens dos três modos e da porta inspecionadas; detalhes em `RETRO_FILTER.md`. Não é benchmark ou teste de nova build.

## Dylan animado e porta — Windows, 11/10/2026

Godot `4.7.2.stable.official.ed1daf0bf`, Forward+/Vulkan, NVIDIA RTX 4050 Laptop GPU. Seleção final do executor: **17 probes, 0 falhas, saída 0**, sem linhas de erro do engine. Resumo preservado em `docs/evidence/dylan/regression-summary.txt`.

Seleção: unidades, cenas, locomocao, cameras, referencia, calibracao-estudos, percurso, operacao, env1-estrada, env1-continuidade, sala-geometria, exterior-geometria, dylan-portas, renderizacao, sala-grafica, exterior-grafico e dylan-portas-grafico. Carregamento das 20 cenas aprovado. Esta seleção cobre o conteúdo afetado; não é uma reexecução do benchmark ou do soak de dez minutos.

`check_dylan_doors.gd`: **962 ticks, zero falhas** em headless e gráfico. Controlador/entrada reais na aproximação da porta; ossos animados, walk/run conforme velocidade, idle após desaceleração, rejeição de E distante/echo, bloqueio de movimento e R durante gesto, ausência de transições duplicadas, oito etapas da sequência, troca sob preto, ida/volta, posição de chegada, câmera e reinício após retorno. Novo probe incorporado ao executor em ambos os modos.

Inspeção visual dos clipes e das capturas: personagem sobre o piso no exterior/interior, gesto para a porta, maçaneta/folha animadas, câmera avançando no vão, sala revelada após o fade, câmera do patamar restaurada na saída e proporção mantida em janela 4:3. Evidências: `docs/evidence/dylan/door-opening.png` e `room-arrival.png`; demais imagens locais por `tools/preview_dylan_animation.gd` e pelo probe novo. Detalhes/limites em `DYLAN_ANIMATION.md`.

## Regressão local de conteúdo — sala e exterior, 11/10/2026

Após criar a sala e o exterior por geometria autorada, a seleção `--only=cenas,percurso,operacao,calibracao-estudos,sala-geometria,exterior-geometria,sala-grafica,exterior-grafico` passou no Windows/RTX 5060: **8 probes, 0 falhas, saída 0**. Carregamento cobriu 20 cenas. Exterior: 3488 ticks/99,41 m em headless e 3498 ticks/99,47 m em gráfico, ida/volta em geometria e arte, quatro cortes por volta e 56 colisores. Sala: 2205 ticks/42,00 m, sem falhas em ambos os modos. Logs em `.local/tests/`.

Capturas gráficas das três vistas externas e da janela 4:3 foram inspecionadas após a correção da vista 2. O teste automático confere movimento, contato com chão/rampa/patamar, câmera/imagem sincronizadas e obstáculos; a aprovação técnica não mede o erro de correspondência dos contornos da imagem. Arte continua candidata, com gate fino de calibração pendente. Fichas e prompts: `docs/calibration/SAVE_ROOM_GEOMETRY.md` e `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`. Os resultados históricos da T09/T10 abaixo pertencem ao percurso técnico e às sessões anteriores.

Data: 11/10/2026. Escopo: percurso técnico T07 com a operação T08. Este relatório separa o que foi **verificado automaticamente** do que foi **inspecionado visualmente** e do que **não foi verificado**. Evidências versionadas em `docs/evidence/`; demais capturas/logs ficam em `.local/` e `user://`, ignorados pelo Git.

## Ambiente

| Item | Valor |
| --- | --- |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf (Linux x86_64 oficial; mesmo commit do executável Windows de referência) |
| Máquina | Contêiner em nuvem Ubuntu 24.04, 4 vCPU, 15 GiB, **sem GPU** |
| Renderizador | Forward+ / Vulkan 1.4.318 sobre Mesa **llvmpipe** (CPU), Xvfb 1920×1080 |
| Áudio | `--audio-driver Dummy` |

Renderização por software reproduz imagem e profundidade, mas não mede desempenho; a máquina de referência (Ryzen 5 5600 + RTX 5060, Windows) não estava disponível nesta sessão.

## Regressões automatizadas

Executor: `tests/run_all.gd` (GDScript puro, sem plugin). Cada probe roda em processo filho do mesmo executável e só passa com **código de saída 0, linha-resumo esperada e nenhuma linha `ERROR:`/`SCRIPT ERROR:`/`USER ERROR:`/`Parse Error`** na saída. Falhas fazem o executor sair com 1. Logs por probe e `summary.txt` em `.local/tests/`.

```powershell
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd                    # tudo (abre janelas para os gráficos)
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd -- --headless-only  # só headless
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd -- --only=operacao,unidades
```

No Windows, `executar-testes.cmd` faz a primeira chamada e mantém a janela aberta no final.

Execução completa nesta sessão (`xvfb-run … --headless --path . --script res://tests/run_all.gd`), **20 executados, 0 falhas, saída 0**:

| Probe | Modo | Tempo real | Resumo |
| --- | --- | --- | --- |
| unidades | headless | 0,3 s | T09 units failures=0 |
| cenas | headless | 0,7 s | 16 cenas, failures=0 |
| locomocao | headless | 0,4 s | caminhada 2,5 / diagonal 2,5 / corrida 5,0 m/s, failures=0 |
| cameras | headless | 0,9 s | 20 travessias por sentido, 41 trocas, failures=0 |
| referencia | headless | 0,3 s | T05 failures=0 |
| calibracao-estudos | headless | 0,5 s | gate de aceite dos estudos, failures=0 |
| calibracao-ferramentas | headless | 0,4 s | ferramentas T06, failures=0 |
| percurso | headless | 0,9 s | T07 failures=0 |
| operacao | headless | 2,3 s | T08 failures=0 |
| env1-estrada | headless | 0,7 s | 1748 ticks, failures=0 |
| env1-continuidade | headless | 0,9 s | 1551 ticks, failures=0 |
| cena-principal | headless | 0,5 s | 30 quadros sem erro |
| composicao | gráfico | 2,8 s | T01 failures=0 |
| oclusao | gráfico | 6,4 s | T02 failures=0 |
| distancia-30/60/144 | gráfico | 4,0 s cada | 4,81247 m em 120 ticks nos três limites (esperado 4,8125) |
| renderizacao | gráfico | 8,1 s | T07 rendering failures=0 |
| percurso-grafico | gráfico | 129,5 s | T07 failures=0 |
| operacao-grafica | gráfico | 224,9 s | T08 failures=0 |

Tempos gráficos longos refletem renderização por CPU com `--fixed-fps 60`.

Execução final após a T10 e a revisão de código (mesmo comando, log `.local/final-runner-full.out`): **22 executados, 0 falhas, saída 0** — os 20 acima mais `robustez-10min` (605,6 s de jogo, 27 voltas, 0 falhas) e `benchmark-funcional` (piloto automático da cena principal, 1 volta, 0 erros).

Casos obrigatórios do plano e onde são cobertos:

| Caso | Probe |
| --- | --- |
| Normalização da entrada (diagonal ≤ 1, oposição cancela, magnitude analógica) | `check_units.gd`; velocidade diagonal real em `check_locomotion.gd` |
| Referência de movimento (trava, ignora troca de câmera enquanto segurada, libera, sem câmera usa eixos do mundo; pausa interrompe) | `check_units.gd`, `check_movement_reference.gd`, `check_operation.gd` |
| Câmera (prioridade, empate, último válido, permanência, 20 travessias por sentido, troca atômica, `reset_to`) | `check_cameras.gd`, `check_units.gd`, `check_technical_route.gd` |
| Carregamento de cenas (16 cenas do projeto instanciadas por 5 quadros, erros capturados por `Logger`) | `check_scenes.gd` |
| Operação T08 (pausa, reinício, F3, foco, conclusão, recuperação) | `check_operation.gd`, `check_units.gd` |

Os testes usam as classes e cenas reais. Verificação de sensibilidade do executor: alterar temporariamente a velocidade padrão de caminhada para 2,6 m/s fez `unidades` e `locomocao` falharem (saída 1) e o executor retornar 1; a alteração foi revertida. Uma cena quebrada temporária (script ausente) fez `check_scenes.gd` falhar com três erros capturados; removida em seguida.

Fora do executor por decisão: o gate de aceite dos renders ENV_1 (`check_calibration.gd -- --acceptance`) continua retornando 1 por desenho (cam02/cam03 acima de 8 px); ele documenta uma pendência de arte, não uma regressão.

## Inspeção visual manual

Capturas geradas por `tests/capture_visual_report.gd` (gráfico, controlador real no trajeto; poses estáticas só para oclusão/resolução) e pelos probes T07/T08. Todas as imagens citadas foram abertas e examinadas.

### Colisão — `docs/evidence/t09/t09-collision.jpg`

| Situação | Observação | Resultado |
| --- | --- | --- |
| Empurrar contra a face frontal do caixote (vista 1) | Cápsula encosta na face, sem interpenetração visível; mesmo limite numérico do T07 (z 6,39–6,60) | aprovado |
| Empurrar contra a parede externa direita (vista 1) | Cápsula para na face interna; seta de direção aponta para a parede | aprovado |
| Meio da rampa (vista 2) | Pés sobre a superfície inclinada, sem flutuar | aprovado |
| Empurrar contra a mureta lateral da rampa (vista 2) | Contato lateral, corpo permanece sobre a rampa | aprovado |
| Passagem de 1,6 m entre estante e barreira (vista 3) | Cápsula cabe na abertura, entre a ponta da estante e a barreira marrom | aprovado |
| Marca dourada (vista 3) | Cápsula sobre o pad; legenda e aviso mudam para o retorno | aprovado |

### Oclusão — `docs/evidence/t09/t09-occlusion.jpg`

| Situação | Observação | Resultado |
| --- | --- | --- |
| Atrás do caixote, vista 1 | Com oclusores: ator totalmente oculto. Sem oclusores: cápsula desenhada sobre o caixote. Diferença medida > 100 pixels | aprovado |
| Atrás da estante, vista 3 | Com oclusores: só o topo da cabeça aparece acima da borda da estante, coerente com a altura (estante 2,4 m; ator 1,8 m; câmera elevada). Sem oclusores: cápsula inteira sobre a estante | aprovado |
| Emendas de cor dos oclusores | `check_route_rendering.gd`: 0 canais com diferença > 2/255 nas 3 vistas × 3 resoluções | aprovado |

### Resolução — `docs/evidence/t09/t09-resolution.jpg`

Três vistas em 1920×1080, 1280×720 e janela 1280×960. Mesmo enquadramento, ator na mesma posição relativa, legenda e aviso proporcionais; em 4:3, barras pretas superior/inferior sem esticar ou recortar a área 16:9. Menu de pausa em 4:3 cobre a janela inteira (`docs/evidence/t08/t08-pause-menu-4x3.png`). **Aprovado.**

### Continuidade nos cortes — `docs/evidence/t09/t09-continuity.jpg`

Último quadro antes e primeiro depois de cada corte da ida e volta (1→2, 2→3, 3→2, 2→1), dirigidos pelo controlador real:

- Fundo, câmera, luz e oclusores trocam no mesmo quadro; nenhum quadro vazio ou com fundo de outra vista.
- O ator permanece no mesmo ponto do mundo e visível nas duas vistas; a seta amarela mantém a direção mundial durante o corte (direção preservada enquanto a tecla segue pressionada).
- No corte 2→1 da volta, o ator fica pequeno e parcialmente atrás da quina do caixote na vista larga — oclusão correta e característica do enquadramento amplo, não falha. Pode merecer atenção quando houver arte final.

**Aprovado.** Um quinto corte (1→2) registrado depois, durante os testes de colisão, apresenta o mesmo comportamento.

### Operação T08 — `docs/evidence/t08/`

Menu de pausa com foco visível (1080p e 4:3), overlay F3 legível e sem cobrir o menu, aviso de recuperação, aviso da marca dourada e conclusão com tempo. **Aprovado.**

## Build exportada e robustez (T10)

| Verificação | Ambiente | Resultado |
| --- | --- | --- |
| Exportação release `Windows Desktop` | editor 4.7.2 headless | saída 0, sem ERROR/WARNING; 62 arquivos, sem modelos/ENV_1/testes |
| Abertura do `.pck` no template de **release** Linux (mesmo commit) | headless, fora do projeto | saída 0, sem erros |
| Benchmark funcional no template de release | headless, 60 s | 2 voltas, 2 conclusões, 0 erros |
| Benchmark de 600 s no template de release | gráfico (llvmpipe) | 22 voltas, 22 conclusões, 0 erros |
| `check_technical_route` / `check_operation` / `check_soak` contra o `.pck` (`--main-pack`) | headless, fora do projeto | todos saída 0, zero ERROR |
| `check_soak.gd` no projeto | headless | 605,6 s de jogo, 27 voltas, 22 conclusões, 5 recuperações, 27 reinícios; nós/objetos/memória estáveis |
| `check_soak.gd` no projeto | gráfico (llvmpipe) | 605,6 s de jogo, mesmos números do headless, zero falhas |
| Gate de desempenho (p95 ≤ 16,7 ms) | build release, llvmpipe | p95 48,19 ms, 25,3 FPS (30 s + 120 s, 5 voltas, 0 erros) — reprovado em CPU; **não medido na RTX 5060** |
| `.exe` Windows | Wine 9.0 | não iniciou: falha interna do Wine (`kernelbase.dll`) antes do código do projeto |

O piloto automático (`-- --benchmark`) e o soak exercitam o jogo de forma repetível, mas não substituem a sessão humana de dez minutos prevista no plano.

## Não verificado

- Desempenho (p95 do tempo de quadro em 1080p na máquina de referência): requer a RTX 5060 — `medir-desempenho.cmd`.
- Execução do `.exe` exportado no Windows.
- Teclado e mouse físicos operados por pessoa; troca real de foco de janela no Windows (simulada pela notificação do engine).
- Exploração humana prolongada; percepção de conforto dos cortes.
- Arte final: os fundos são estudos geométricos autorais. ENV_1 continua com geometria comum não aprovada.
