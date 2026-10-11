# LIMIAR Recon

Protótipo 2.5D para Windows: ator 3D sobre fundos pré-renderizados e câmeras fixas. **T01–T08 concluídas com estudos técnicos provisórios.** O percurso T07, com a operação T08 (pausa, reinício, diagnóstico F3, conclusão e recuperação), é a cena principal. Os renders de floresta/guarita ENV_1 continuam preservados para refinamento; sua geometria comum ainda não foi aprovada.

Repositório: [madebyfelipe/limiar_beyond_time](https://github.com/madebyfelipe/limiar_beyond_time). O Git inclui código, cenas, recursos, documentação, modelos, texturas e fundos. Engine local, cache de importação, logs/capturas de teste e builds geradas ficam nas pastas ignoradas.

Em outra máquina, clone o repositório e abra `project.godot` com Godot 4.7.2 Standard. Para usar os atalhos `.cmd`, coloque a distribuição Windows da engine em `.tools/godot-4.7.2/`, incluindo `Godot_v4.7.2-stable_win64_console.exe`. O editor reimporta os assets ao abrir. F6 na cena `environments/env1_continuity_probe.tscn` executa Dylan com os renders originais; F5 executa o percurso técnico.

## Jogar o percurso

Dê dois cliques em **`executar-percurso.cmd`**. No Godot, **F5** executa o mesmo percurso. Contorne o caixote, atravesse o corredor, suba a rampa e passe pela abertura à direita da estante para chegar à marca dourada. Depois volte à marca azul inicial.

- WASD/setas: mover em relação à tela. Shift: correr.
- Segurar uma direção durante o corte conserva a direção mundial; soltar todas e pressionar novamente usa a câmera atual.
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

Regressões anteriores:

```powershell
& $GodotExe --path $PWD --script res://tests/check_composition.gd
& $GodotExe --path $PWD --script res://tests/check_occlusion.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_locomotion.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_cameras.gd
& $GodotExe --headless --path $PWD --fixed-fps 60 --script res://tests/check_movement_reference.gd
```

Probes `SceneTree` usam `--script`, não F6. Capturas ficam em `%APPDATA%/Godot/app_userdata/LIMIAR Recon`; logs em `.local/`. Comandos, resultados e limites em `docs/PROGRESS.md`.

## Exportação diagnóstica

```powershell
New-Item -ItemType Directory -Path 'builds\windows-t07' -Force | Out-Null
& $GodotExe --headless --path $PWD --export-debug 'Windows Desktop' 'builds/windows-t07/LIMIAR-Recon.exe'
```

O preset seleciona T07, fonte espacial, cenas base e dependências. A antiga pasta `builds/windows` é T05. A exportação diagnóstica T07 não conclui T10: desempenho, exploração prolongada e operação T08 ainda estão pendentes. Modelos do usuário, ENV_1 e ferramentas de autoria não fazem parte do percurso exportado.

## Documentação

- `docs/PLAN.md`: sequência e critérios de aceite.
- `docs/ARCHITECTURE.md`: contratos dos componentes.
- `docs/PROGRESS.md`: estado real, ambiente e evidências.
- `docs/KNOWN_ISSUES.md`: limitações e pendências.
- `docs/calibration/ROUTE_STUDY.md`: origem, medidas e reprodução dos estudos.
- `assets/models/README.md`: inventário dos modelos fornecidos, preservados.

Para outra máquina, usar a mesma distribuição Standard e templates da fonte oficial: https://godotengine.org/download/archive/4.7.2-stable/ . Executáveis locais e caches não são versionados.
