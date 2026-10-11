# Limitações e pendências

## Estado atual — T07

- F5 e `executar-percurso.cmd` abrem T07; a build diagnóstica atual está em `builds/windows-t07`. A antiga pasta `builds/windows` continua T05.
- T06 concluída com estudos autorais escolhidos pelo usuário e reprodução independente. T07 validada por ida/volta, desafios de colisão, oclusão e capturas; ENV_1 continua pendente de arte, preservado.
- O percurso é técnico e curto: ida caminhando/volta correndo do probe durou 36,12 s simulados. Não satisfaz por si só a expectativa de exploração de 3–5 min, os dez minutos de robustez ou o orçamento 1080p/60 FPS do fechamento da Fase 1.
- Pausa, reinício, perda de foco, recuperação e aviso de conclusão ainda não existem (T08). Fechar pelo botão padrão da janela; ponto final apenas marcado no chão. Usabilidade com teclado físico e exploração humana prolongada não foram verificadas.
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
- Indicador de direção é uma seta 3D e pode ser ocultado pela geometria. Overlay F3 continua previsto para T08.
- Entrada sintética/probes reais confirmam contratos; exploração humana prolongada e usabilidade no teclado ainda não verificadas.
- Arquivos continuam não rastreados no Git, sem commit inicial. `git diff --check` não valida esse conteúdo; alterações foram relidas diretamente. Não houve publicação ou edição dos GLBs.

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
- Pausa, recuperação e diagnóstico: T08.
- Regressões automatizadas de gameplay e inspeção do percurso: T09.
- Desempenho 1080p/60 FPS, exploração de dez minutos e piloto executável: T10.
- Cor do oclusor validada nos estudos; sombras de contato e coerência dos ambientes reais permanecem pendentes.
- Assets finais, conteúdo canônico, combate e quatro espécies estão fora da T00.
