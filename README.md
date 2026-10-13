# LIMIAR Recon

**Menu inicial:** execute `executar-menu.cmd` ou abra a cena principal no Godot. Logo separado com transparência, cenário noturno e neve animada; NEW GAME inicia no exterior, LOAD GAME retoma o save do terminal, OPTIONS abre as configurações e EXTRAS reúne os estudos. Arte e prompts em [assets/ui/main_menu](assets/ui/main_menu).

**Configurações:** **Esc / Options → Configurações** reúne modo de tela (janela, tela cheia e exclusiva), resolução da janela, VSync, limitador de FPS, volume, teclado/mouse e gamepad. As opções de jogabilidade e apresentação agora têm **setas clicáveis** e aceitam **←/→** ou direcional/analógico para alterar nos dois sentidos. As telas de controles permitem remapear duas entradas por ação, trocar binds em conflito, limpar e restaurar padrões. Sensibilidade/inversão do mouse e zona morta/inversão do gamepad são ajustáveis. Alterações ficam guardadas entre sessões. Guia em [docs/SETTINGS.md](docs/SETTINGS.md).

**Fase 2 — trilha do perímetro:** depois de salvar no terminal da guarita, o portão norte do pátio abre e leva à trilha onde o Keleken vive agora. `executar-perimetro.cmd` entra direto. Três câmeras fixas, corredor com cercado, pinheiro caído e galpão do relé lacrado, que encerra o conteúdo atual. As três vistas da trilha e o pátio norte têm fundos nevados gerados sobre a geometria; B compara arte/geometria. Estrutura de fase, portão e cenário em [docs/PERIMETER.md](docs/PERIMETER.md).

**Combate com Keleken:** `executar-perimetro.cmd` inclui patrulha, percepção com linha de visão, alerta, perseguição e bicada com 25 de dano. Dylan e o Keleken podem morrer; Esc → Reiniciar restaura os dois. **Q** esquiva na direção do movimento (sem direção, recua); **H** usa um kit médico para recuperar até 50 de vida. Kits e pistola são comprados no terminal da guarita com `buy medkit` e `buy weapon`. Saúde e estoque seguem pelas portas e são registrados por `save`. No gamepad, **△ / Y** esquiva e **R3 / RS** usa kit. Detalhes em [docs/COMBAT.md](docs/COMBAT.md). `executar-keleken.cmd` mantém o estudo isolado com os sete clipes, sem IA. Rig e fontes em [docs/KELEKEN_ANIMATION.md](docs/KELEKEN_ANIMATION.md).

**Gamepad, incluindo PS4 / DualShock 4:** analógico esquerdo ou direcional move; **L3 ou ○ mantido** corre; **✕** interage; **L2** ergue a arma; analógico direito mira; **R2 mantido** dispara; **□** recarrega; **L1/R1** trocam o alvo; **Options** pausa. Nos menus, analógico/direcional navega, ✕ confirma e ○ volta. O terminal permite escolher comandos com ←/→ e executar com ✕, sem teclado. Funciona nos esquemas câmera e tanque, com zona morta e avisos de botões conforme o dispositivo usado. Guia completo e validação em [docs/GAMEPAD.md](docs/GAMEPAD.md).

**Mira opcional inspirada em Parasite Eve II:** em **Esc → Jogabilidade**, escolha **Controles: Câmera** e **Mira (Câmera): Alvo travado**. Aponte um alvo e segure direito; a seleção acompanha o inimigo. Roda/Tab troca de alvo, esquerdo mantido dispara, R recarrega e soltar direito libera. Marcador mostra seleção/bloqueio e seta indica alvo fora da tela. Experimente em `executar-estande.cmd`. Levantamento e validação em [docs/PARASITE_EVE_2_MOUSE.md](docs/PARASITE_EVE_2_MOUSE.md).

**Presets de apresentação:** quatro telas sobre o mesmo framebuffer PSX de 320×180 — **Original** (sem efeito, para calibração), **PSX**, **PSX + linhas** (varredura e grade de abertura) e **TV de tubo** (vidro curvo, cantos sem imagem). **F4** percorre os quatro com aviso na tela, e **Esc → FILTRO** faz o mesmo pelo menu. A escolha vale entre cenas e entre sessões. Vale para cenário, Dylan e transição da porta; HUD e menu ficam fora do filtro, então o texto continua nítido. Detalhes e medidas em [docs/RETRO_PRESETS.md](docs/RETRO_PRESETS.md).

**Pausa, diagnóstico e objetivo:** **Esc** abre o menu de pausa — Continuar, Reiniciar, Controles, Filtro e Sair —, **F3** mostra o diagnóstico e a linha de objetivo acompanha a Fase 1: estrada, pátio, porta da guarita e terminal. Sair da geometria devolve Dylan ao último ponto firme. Reiniciar é tentativa nova e **não** apaga o registro salvo. Ver [docs/LEVEL_OPERATION.md](docs/LEVEL_OPERATION.md).

**Dylan animado e passagem pela porta:** abra `executar-exterior.cmd`, siga até a porta da guarita e pressione **E** quando aparecer o aviso. Dylan faz o gesto; a maçaneta gira, a porta abre em close sobre fundo preto e a câmera atravessa antes de revelar a sala. E junto à porta interna faz o retorno. Repouso, caminhada e corrida usam clipes originais gerados no rig. A guarita usa Dylan de 1,8 m, compatível com sua geometria; os ensaios dos renders originais mantêm a escala de 2,4 m. Detalhes em `docs/DYLAN_ANIMATION.md`.

**Novo exterior criado a partir de geometria 3D:** abra `executar-exterior.cmd` (ou F6 em `environments/exterior.tscn`). Estrada → cancela aberta → escada/porta da guarita, com três câmeras fixas e novos fundos nevados. Começa com arte; B compara geometria, T alterna câmera/tanque, F3 diagnóstico, R reinicia, Esc pausa. WASD/setas e Shift. Ficha, prompts e validação em `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`.

**Terminal de comandos e HUD:** dentro da sala, ande até a mesa e pressione **E**. Digite `help` para listar os comandos, `shop` para ver produtos, `buy ammo` para comprar e `save` para guardar progresso e estoque em `user://save.cfg`. `inventory` mostra suprimentos; `status` mostra o registro; `exit` ou Esc retoma o jogo. Tab completa, ↑/↓ percorrem histórico e Ctrl+L limpa a tela. O HUD mantém apenas VITALITY. Guia e capturas reais em [docs/COMMAND_TERMINAL.md](docs/COMMAND_TERMINAL.md). Um único registro; combate e consumo de suprimentos continuam pendentes.

**Estudo da sala de salvamento da guarita:** abra `executar-sala.cmd` (ou F6 em `environments/save_room.tscn`). Geometria foi criada antes da arte, com câmera próxima de interior. WASD/setas movem, Shift corre, **E** abre a porta ou o menu do terminal, B compara arte/geometria, C abre visão técnica ampla, T alterna câmera/tanque, F3 diagnóstico, R reinicia e Esc pausa. Arte ainda em revisão de alinhamento. Ficha e limites em `docs/calibration/SAVE_ROOM_GEOMETRY.md`.

Protótipo 2.5D para Windows: ator 3D sobre fundos pré-renderizados e câmeras fixas. **T01–T09 concluídas com estudos técnicos provisórios; T10 pronta para revisão** — build Windows x64 exportada e validada nesta sessão em nuvem (Linux), faltando abrir o `.exe` no Windows e medir o desempenho na máquina de referência (veja [Build Windows](#build-windows-t10)). O percurso T07, com a operação T08 (pausa, reinício, diagnóstico F3, conclusão e recuperação), é a cena principal. Os renders de floresta/guarita ENV_1 continuam preservados para refinamento; sua geometria comum ainda não foi aprovada.

Repositório: [madebyfelipe/limiar_beyond_time](https://github.com/madebyfelipe/limiar_beyond_time). O Git inclui código, cenas, recursos, documentação, modelos, texturas e fundos. Engine local, cache de importação, logs/capturas de teste e builds geradas ficam nas pastas ignoradas.

Em outra máquina, clone o repositório e abra `project.godot` com Godot 4.7.2 Standard. Para usar os atalhos `.cmd`, coloque a distribuição Windows da engine em `.tools/godot-4.7.2/`, incluindo `Godot_v4.7.2-stable_win64_console.exe`. O editor reimporta os assets ao abrir. F6 na cena `environments/env1_continuity_probe.tscn` executa Dylan com os renders originais; F5 executa o percurso técnico.

## Jogar o percurso

Dê dois cliques em **`executar-percurso.cmd`**. No Godot, **F5** executa o mesmo percurso. Contorne o caixote, atravesse o corredor, suba a rampa e passe pela abertura à direita da estante para chegar à marca dourada. Depois volte à marca azul inicial.

- WASD/setas: mover em relação à tela. Shift: correr.
- Segurar uma direção durante o corte conserva a direção mundial; soltar todas e pressionar novamente usa a câmera atual.
- **Controles de tanque**, à moda dos survival horrors clássicos: esquerda/direita giram Dylan no lugar e cima/baixo o levam para frente e para trás, sem relação com a câmera. Trocar pelo botão **Controles** na pausa, ou por **T** no exterior e na sala. A escolha vale para todas as cenas e fica guardada em `user://settings.cfg`.
- Duas áreas, três enquadramentos, obstáculo contornável, rampa e passagem de 1,6 m.
- **Esc**: pausa com Continuar, Reiniciar percurso e Sair do jogo (mouse ou setas + Enter). Esc de novo retoma. Perder o foco da janela também pausa; voltar à janela não retoma sozinho.
- **F3**: diagnóstico com FPS, tempo de quadro, posição, velocidade, enquadramento ativo/candidato, referência de movimento, etapa/tempo do percurso e estado da simulação. Funciona também com o jogo pausado.
- Ao pisar na marca dourada, o objetivo muda para voltar à marca azul; ao voltar, aparece **PERCURSO TÉCNICO CONCLUÍDO** com o tempo. Reiniciar percurso restaura personagem, câmera, entrada e objetivo.
- Se o personagem cair abaixo do cenário (pés abaixo de −4 m), ele volta à última marca alcançada naquela tentativa, com a câmera correspondente.

Os fundos são estudos geométricos autorais, não arte final. A ida caminhando e a volta correndo do probe percorreram 86,16 m em 36,12 s simulados; isso não comprova a duração de exploração de 3–5 min ou desempenho do marco final.

## Ferramentas e abertura

Godot **4.7.2 Standard**, GDScript, Forward+, Windows x64; Git, sem plugins de terceiros ou .NET. Templates **4.7.2.stable**. A versão exata é contrato: `project.godot` informa compatibilidade 4.7, mas não trava o patch.

```powershell
$GodotExe = Join-Path $PWD '.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --version
& $GodotExe --path $PWD --editor
& $GodotExe --path $PWD
```

No editor, F6 executa somente a cena aberta; F5 executa o percurso T07. As provas T01–T05 permanecem em `environments/`.

## Calibração T06

**Para jogar com Dylan sobre os três renders originais**, executar `executar-render-original.cmd` (ou F6 em `environments/env1_continuity_probe.tscn`). Começa na estrada cam02: caminhar em direção à ponta próxima, na parte inferior da imagem, ativa cam01; continuar leva à cam03 da guarita. É possível voltar pelo mesmo caminho. WASD/setas, Shift e G para revelar limites. Dylan recebeu aumento uniforme de 33% solicitado pelo usuário, pose neutra e colisão compatível com sua altura; o GLB não contém animações de caminhada. A ligação é uma hipótese autoral de ensaio; escada, oclusão e geometria comum ainda não estão aprovadas. Detalhes em `docs/calibration/ENV_1_CONTINUITY.md`. F5 continua executando T07.

A navegação da segunda vista (cam01) começa no ponto indicado pelo usuário junto ao poste/cancela. O corte usa o centro do personagem no limite X=8,5; ao voltar e ultrapassar esse limite, a apresentação retorna à estrada. Não há teleporte na entrada.

O ensaio anterior, com uma faixa mais longa só na cam02, permanece em `executar-estrada-isolada.cmd`. Duas cópias de correção da cam03 foram geradas e inspecionadas, mas não atingiram a precisão exigida e não são usadas nas cenas. Os três originais estão intactos.

- Estudos aprovados para T07: `environments/calibration_route_study.tscn`; ficha em `docs/calibration/ROUTE_STUDY.md`.
- Renders originais pendentes: `environments/calibration_env1.tscn`, ou `executar-calibracao.cmd`; fichas em `docs/calibration/ENV_1.md`.
- Nas duas prévias: 1/2/3 trocam vista, G alterna grade, M alterna marcadores. São cenas estáticas. Ajustes da câmera ficam no recurso `Definition` pelo Inspector.

```powershell
& $GodotExe --path $PWD --scene res://environments/calibration_route_study.tscn
& $GodotExe --path $PWD --fixed-fps 60 --script res://tests/check_calibration.gd -- --study --acceptance
```

Os estudos têm oito referências distribuídas por vista e erros máximos abaixo de 1 px em 1080p; a reprodução foi confirmada por outro executor. Isso não aprova ENV_1. O gate original, sem `--study`, ainda falha em cam02/cam03.

## Testes do percurso

```powershell
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_technical_route.gd
& $GodotExe --path $PWD --fixed-fps 60 --script res://tests/check_technical_route.gd
& $GodotExe --path $PWD --fixed-fps 60 --script res://tests/check_route_rendering.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_operation.gd
```

O primeiro/segundo fazem ida e volta com o controlador real e sem teleporte no percurso, conferem limites, chão/rampa, enquadramento, cortes e desafios de colisão. O terceiro exige renderizador gráfico: verifica oclusão e ausência de emendas nas três vistas em 1920×1080, 1280×720 e janela 1280×960 com barras. Os probes retornam código diferente de zero ao falhar. Headless não comprova renderização. `check_operation.gd` (T08) usa eventos reais de teclado para Esc/F3/setas/Enter: pausa congelando física, candidato de corte e relógio; F3 durante a pausa; reinício pelo menu restaurando personagem/câmera/entrada; perda de foco; duas recuperações de queda; marca dourada e conclusão. Sem `--headless`, salva capturas `t08-*.png`.

Todas as regressões de uma vez (T09), com resumo e código de saída agregado — no Windows, **`executar-testes.cmd`**:

```powershell
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd                    # headless + gráficos
& $GodotExe --headless --path $PWD --script res://tests/run_all.gd -- --headless-only  # só headless
```

Cada probe roda em um processo separado; os gráficos abrem e fecham janelas sozinhos. Logs e `summary.txt` em `.local/tests/`. Relatório manual de colisão, oclusão, resolução e continuidade em `docs/TEST_REPORT.md` (capturas por `tests/capture_visual_report.gd`).

Regressões anteriores (já incluídas no executor):

```powershell
& $GodotExe --path $PWD --script res://tests/check_composition.gd
& $GodotExe --path $PWD --script res://tests/check_occlusion.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_locomotion.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_cameras.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_movement_reference.gd
```

Probes `SceneTree` usam `--script`, não F6. Capturas ficam em `%APPDATA%/Godot/app_userdata/LIMIAR Recon`; logs em `.local/`. Comandos, resultados e limites em `docs/PROGRESS.md`.

## Build Windows (T10)

Builds não vão para o Git (o executável tem ~105 MB). Gere a sua com dois cliques em **`exportar-build.cmd`**, ou:

```powershell
New-Item -ItemType Directory -Path 'builds\windows-t10' -Force | Out-Null
& $GodotExe --headless --path $PWD --export-release 'Windows Desktop' 'builds/windows-t10/LIMIAR-Recon.exe'
```

Requer os templates oficiais `4.7.2.stable` em `%APPDATA%\Godot\export_templates\4.7.2.stable` (já instalados na máquina de referência). Saída em `builds\windows-t10`:

| Arquivo | Uso |
| --- | --- |
| `LIMIAR-Recon.exe` | o jogo; dois cliques para jogar, offline |
| `LIMIAR-Recon.pck` | conteúdo; precisa ficar ao lado do `.exe` |
| `LIMIAR-Recon.console.exe` | mesmo jogo com console de log (diagnóstico e benchmark) |

Para levar a outro computador, copie os três arquivos juntos. Controles iguais aos do percurso acima (WASD/setas, Shift, Esc, F3). A build contém só o percurso técnico: cenas, scripts, shader, os três fundos de estudo e a UI — sem modelos do usuário, ENV_1, testes ou ferramentas.

**Desempenho (gate da Fase 1):** dois cliques em **`medir-desempenho.cmd`**. Ele roda a build (ou o projeto, se a build não existir) em tela cheia, VSync desligado, 30 s de aquecimento e 120 s de percurso automático com o controlador real, e grava `%APPDATA%\Godot\app_userdata\LIMIAR Recon\benchmark.txt` com média, p50, p95, p99, máximo e o veredito (p95 ≤ 16,7 ms). Equivale a `LIMIAR-Recon.console.exe -- --benchmark`; opções `--warmup=S`, `--duration=S`. Não use o computador durante a medição.

Nesta sessão (Linux, renderização por CPU), o mesmo `.pck` foi validado fora da pasta do projeto: no template de release Linux (mesmo commit da engine) carregou sem erros e completou 22 voltas automáticas em 10 minutos renderizando; pelo runtime do editor com `--main-pack` passou no percurso completo, nos testes T08 e no soak de 10 minutos. O `.exe` Windows não abriu no Wine 9.0 (falha interna do Wine) e precisa ser confirmado no Windows. O desempenho medido em CPU (p95 ≈ 50 ms) **não** representa a RTX 5060. A antiga pasta `builds/windows` é T05 e `builds/windows-t07` é a diagnóstica T07.

## Documentação

- `docs/PLAN.md`: sequência e critérios de aceite.
- `docs/ARCHITECTURE.md`: contratos dos componentes.
- `docs/PROGRESS.md`: estado real, ambiente e evidências.
- `docs/KNOWN_ISSUES.md`: limitações e pendências.
- `docs/TEST_REPORT.md`: regressões automatizadas e inspeção visual manual (T09).
- `docs/evidence/`: capturas inspecionadas na sessão em nuvem.
- `docs/calibration/ROUTE_STUDY.md`: origem, medidas e reprodução dos estudos.
- `assets/models/README.md`: inventário dos modelos fornecidos, preservados.

Para outra máquina, usar a mesma distribuição Standard e templates da fonte oficial: https://godotengine.org/download/archive/4.7.2-stable/ . Executáveis locais e caches não são versionados.
