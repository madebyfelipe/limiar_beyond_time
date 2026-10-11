# Limitações e pendências

## Estado atual — T10 pronta para revisão

- **Falta executar no Windows**: a build `builds/windows-t10` foi exportada nesta sessão Linux, mas o `.exe` não pôde ser aberto aqui. O Wine 9.0 do Ubuntu falha dentro do próprio `kernelbase.dll` (acesso nulo logo após carregar `dinput8.dll`) ao iniciar o template Windows 4.7.2, antes de qualquer código do projeto. Evidência equivalente obtida: o mesmo `.pck` rodou no template Linux de release (mesmo commit da engine) e no runtime do editor via `--main-pack`, fora da pasta do projeto, com percurso completo, testes T08 e voltas automáticas sem erro. Confirmar com dois cliques em `LIMIAR-Recon.exe` após `exportar-build.cmd`.
- **Falta o desempenho na máquina de referência**: o gate (1080p, VSync desligado, 30 s + 120 s, p95 ≤ 16,7 ms) só foi medido com renderização por CPU (llvmpipe), que reprova com p95 ≈ 50 ms e não representa a RTX 5060. Executar `medir-desempenho.cmd` e registrar `benchmark.txt` em `PROGRESS.md`.
- A exploração de dez minutos foi coberta por pilotos automáticos (probe `check_soak.gd` e benchmark de 600 s na build); não substitui uma sessão humana.
- O executor T09 e os atalhos `.cmd` novos (`executar-testes`, `exportar-build`, `medir-desempenho`) foram escritos para Windows, mas só executados no Linux (equivalentes de linha de comando).

## Estado anterior — T08

- F5 e `executar-percurso.cmd` abrem o percurso T07 com a operação T08. A build atual da T10 é gerada em `builds/windows-t10`; `builds/windows-t07` (diagnóstica T07) e `builds/windows` (T05) são antigas.
- T06 concluída com estudos autorais escolhidos pelo usuário e reprodução independente. T07 validada por ida/volta, desafios de colisão, oclusão e capturas; ENV_1 continua pendente de arte, preservado.
- O percurso é técnico e curto: ida caminhando/volta correndo do probe durou 36,12 s simulados. A meta de 3–5 min de exploração da Fase 1 não é atingida pelo conteúdo atual; os dez minutos de robustez foram cobertos por repetição automática de voltas (T10).
- T08 implementada: Esc/menu, reinício, F3, conclusão, recuperação abaixo do cenário e pausa por perda de foco. Teclas e botões foram exercitados por eventos de entrada injetados na janela do jogo; a perda de foco foi simulada pela notificação do engine, não por troca real de janela no Windows. Usabilidade com teclado físico e exploração humana prolongada não foram verificadas.
- Pausar interrompe a referência de movimento: ao retomar segurando uma direção, ela é recapturada pela câmera atual (decisão T08). A continuidade de direção através de cortes sem pausa continua como na T05.
- A recuperação é rede de segurança: no percurso fechado atual a queda só foi provocada no teste, posicionando o ator fora dos limites. O checkpoint é o último pad (azul na ida, dourado na volta); não existe sistema geral de checkpoints.
- Evidências da sessão em nuvem (Linux) foram renderizadas por software (Mesa llvmpipe sob Xvfb). FPS exibido nessas capturas não mede o desempenho da máquina de referência.
- Prévia de calibração aprovada: `calibration_route_study.tscn`; originais: `calibration_env1.tscn` / `executar-calibracao.cmd`. Usar F6 para a cena aberta. Os probes são `SceneTree` e exigem `--script`.

## T00 — Histórico concluído

- Inspeção visual concluída em 11/10/2026 por PNGs do `--write-movie` nativo: editor, cena principal e build inspecionados. T00 concluída; comandos e evidências em `PROGRESS.md`. A ferramenta de captura Windows continua com timeout, mas não impede essa revisão pelo renderizador.
- As capturas do Movie Maker são locais, da área renderizada, em 1280 × 720; não comprovam desktop completo, resolução 1080p ou desempenho em tempo real. Composição e redimensionamento pertencem à T01.
- Cena inicial intencionalmente vazia: sem câmera de jogo, personagem, background ou controles. Não é o primeiro percurso jogável.
- Godot e templates são instalações locais e não acompanham Git. Outra máquina precisa da mesma versão.
- O editor não impede abertura em outra versão; observar o contrato 4.7.2.
- O preset T00 selecionava bootstrap; o atual seleciona T07 e recursos necessários, sem modelos.
- Origem, licença, escala, rig e aprovação dos modelos Kelenken e Dylan não foram verificados. Ambos estão preservados e fora da cena/exportação T00.
- Apenas templates Windows x64 (debug/release e wrappers) foram instalados, conforme plataforma-alvo. Outras plataformas exigem seus templates e estão fora do escopo.

## T01–T05 — Provas concluídas; conteúdo provisório

- Em 11/10/2026, a revisão da dependência foi tentada novamente com a skill computer-use. A captura do editor falhou com `FrameArrived timed out: timed out waiting on channel`; após atualizar a seleção e ativar novamente a janela, falhou com `window capture timed out: timed out waiting on channel`.
- Reprodução mínima, comandos e resultados registrados na seção T01 de `PROGRESS.md`. A regressão headless T00 passou (saída 0), mas sozinha não resolvia a pendência visual daquela tentativa.
- A revisão T00 foi concluída posteriormente por captura nativa do renderizador. Após autorização de execução contínua, T01–T05 foram implementadas e revisadas; resultados separados em `PROGRESS.md`.
- SVGs atuais são estudos originais geométricos, sem aprovação canônica ou calibração de ambientes. Chão e referências gerais do estudo ainda precisam de ajuste aos renders; colisões/oclusão das provas são técnicas.
- Filtros nearest mantêm cores equivalentes entre fundo e oclusor nas resoluções testadas (diferença de pixels zero). Reavaliar qualidade de filtragem quando integrar renders reais.
- Indicador de direção é uma seta 3D e pode ser ocultado pela geometria. O overlay F3 (T08) mostra a direção desejada em texto.
- Entrada sintética/probes reais confirmam contratos; exploração humana prolongada e usabilidade no teclado ainda não verificadas.
- Na fase T01–T05 os arquivos ainda não eram rastreados, portanto `git diff --check` não cobria aquele conteúdo; alterações foram relidas diretamente. Posteriormente o projeto foi commitado e publicado em `madebyfelipe/limiar_beyond_time`, conforme registro em `PROGRESS.md`. GLBs originais permanecem preservados.

## Exportação — Falha reproduzida e corrigida

- Selecionar somente a cena T05 omitiu cenas base herdadas, mesmo com saída 0 na exportação. A build falhou ao carregar. Selecionar as bases resolveu parte do problema; a textura padrão da base também precisou de inclusão explícita.
- Preset atual usa recursos selecionados (cena principal, bases e textura padrão) e suas dependências. Build final diagnóstica passou em headless e gráfica, sem modelos ou testes no pacote. Ao acrescentar cenas herdadas, verificar a build, não apenas o código da exportação. Reprodução e comandos em `PROGRESS.md`.
- Na T07, as classes de câmera instanciadas em script, a classe base ShotDefinition e o shader de oclusão também precisaram de seleção explícita. A primeira build saiu com código 0, mas registrou erros de parsing/arquivos ausentes; após correção do preset, execução headless e gráfica sem erros. Inspecionar logs além do código de saída.

## ENV_1 — Renders recebidos; geometria comum ainda não validada

Atualização mais recente: `executar-render-original.cmd` abre um ensaio com os três originais, cortes e caminhada contínua. A translação −20 m em X da cam02 é hipótese autoral temporária, sem correspondência física confirmada. Testes/revisão passaram para essa faixa; não aprovam geometria do ambiente. Duas cópias de correção da cam03 por imagegen não atingiram o alinhamento pretendido e ficaram fora das cenas. Detalhes em `calibration/ENV_1_CONTINUITY.md`. O ensaio anterior só da cam02 permanece em `executar-estrada-isolada.cmd`.

Continuação posterior: troca invertida para a ponta próxima indicada pelo usuário, início na cam02 e ligação até cam01/cam03. A translação acima foi substituída por giro de 180° e origem (39,2;0;7,2), ainda hipótese espacial. Dylan instalado nos dois ensaios, ampliado 33% a pedido do usuário e com pose neutra. Não há animações no GLB; caminhada/corrida ainda usam pose fixa. Colisão e altura visual de trabalho 2,4, sem aprovação de escala absoluta do ambiente. A revisão independente citada acima refere-se à versão anterior, com cápsula.

Medições das fichas preservadas: cam01/cam02/cam03 **7,005 / 9,016 / 32,265 px**, duas falhas no gate. Pontos inferiores de postes são âncoras provisórias, não pés confirmados; quatro são excluídos do aceite. Ver `calibration/ENV_1_REFINEMENT.md`. Os parágrafos seguintes documentam as hipóteses anteriores, antes da autorização para corrigir cópias.

- Recebidos três PNGs de 1672×941 em `assets/backgrounds/env_1`, preservados. O usuário confirmou imagens geradas/pintadas sem dados de câmera; cam02 é a mesma estrada no sentido oposto.
- Ferramentas T06, seis candidatos por vista e fichas provisórias implementadas. Na última retomada, cam01 passou de 39,493 para **7,005 px**, após correção observacional da base da porta e pose manual, com geometria compartilhada preservada. Cam02 **490,330 px** e cam03 **32,265 px** continuam acima da meta; o gate retorna duas falhas. Os seis pontos locais de cam01 não validam a estrada inteira ou continuidade.
- Prévia agora aceita 1/2/3 para selecionar vista, G para grade e M para marcadores. Os probes exercitam essas ações por eventos de teclado, inclusive repetição/soltura; não há locomoção. Alvos direitos cam02 estão em região de rocha/neve sem borda inequívoca; revisar identidade física antes de assumir seções de estrada. Hipóteses de câmeras no mesmo lado da fachada foram examinadas e não resolveram o conjunto, sem comprovar incompatibilidade das imagens.
- Cam03 teve os alvos da folha inteira/último degrau corrigidos e nova pose, preservando a hipótese espacial compartilhada com cam01. Cam02 teve corrimão/travessa do portão elevados à altura hipotética de 1,1 m e nova pose; alguns marcos de chão pioraram, apesar do máximo menor. O pareamento das estações de estrada reta não é confiável e continua impedindo aceite.
- Hipóteses de escala, alvos encobertos e referências de estrada plana/alturas ainda precisam de revisão. Esses resultados não demonstram que os renders sejam impossíveis de calibrar. Nenhuma imagem foi rejeitada ou alterada e nenhum novo render foi solicitado.
- Reprodução ENV_1: engine fixado com `--headless --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_calibration.gd -- --acceptance` retorna 1. Parâmetros em `docs/calibration/ENV_1.md`. Esta pendência não bloqueia os estudos autorais aprovados pelo usuário; com `-- --study --acceptance`, o gate retorna 0. Cena principal/preset são T07.
- Edição interativa de valores no Inspector e confirmação por outro executor pendentes. A primeira captura de um segundo editor mostrou serviços 6006/6005 já em uso; repetir com `--dap-port 6116 --lsp-port 6115` evitou o conflito. Os scripts não apresentaram erro.

## Ainda não verificado / tarefas futuras

- Calibração de arte ENV_1 ainda pendente. T01–T07 concluídas no escopo técnico com os estudos autorais.
- Pausa, recuperação e diagnóstico: T08 concluída no escopo técnico; foco real de janela e teclado físico ainda dependem de teste humano.
- Regressões automatizadas e inspeção do percurso: T09 concluída (`tests/run_all.gd`, 20 probes, e `docs/TEST_REPORT.md`). O executor foi validado no Linux; no Windows, usar `executar-testes.cmd` e conferir `summary.txt` na primeira execução.
- Desempenho 1080p/60 FPS na máquina de referência e abertura do `.exe` no Windows: pendências da revisão T10 (ver topo).
- Cor do oclusor validada nos estudos; sombras de contato e coerência dos ambientes reais permanecem pendentes.
- Assets finais, conteúdo canônico, combate e quatro espécies estão fora da T00.
