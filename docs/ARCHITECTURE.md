# Arquitetura — LIMIAR Recon

## Implementado na T00

- `project.godot`: Godot 4.7.2 Standard, GDScript, Forward+, base 1920 × 1080, janela inicial 1280 × 720, proporção preservada.
- `environments/bootstrap.tscn`: somente um Node3D raiz, sem script ou gameplay.
- `export_presets.cfg`: Windows x64; seleção da cena inicial e suas dependências, sem assinatura digital, sem alteração de recursos do executável e sem ferramenta externa obrigatória.
- Assets do usuário separados da cena inicial. `.tools`, `.local`, `builds` e `.godot` são locais/gerados, fora do versionamento; `.gdignore` impede importar ferramentas e builds.

## Implementado na T01

- `environments/composition.tscn`: TextureRect e SubViewportContainer no mesmo Control dentro de AspectRatioContainer 16:9, barras internas pretas e viewport 3D transparente de 1920×1080. Uma câmera perspectiva fixa, cápsula estática e luz ajustável no Inspector; exposição fixa, sem fog/glow/sombras.
- `project.godot`: composição é a cena principal; `canvas_items/expand` dá ao layout toda a janela, e o AspectRatioContainer preserva o enquadramento com barras. Exportação seleciona composição e dependências.
- `tests/check_composition.gd`: probe gráfico do componente real, com resize e capturas completas da janela, inclusive barras.

## Implementado na T02

- `environments/occlusion.tscn` herda T01; volume físico pertence ao World e a malha de oclusão é separada. `occlusion_proof.gd` apenas anima a cápsula para esta prova, sem controle/locomoção física.
- `background_occluder.gdshader`: material opaco, unshaded, SCREEN_UV, sem ALPHA. Shader/TextureRect/container usam nearest para manter amostragem equivalente nas três resoluções. Comparação integral com oclusor ligado/desligado resultou em diferença zero.
- Cena principal e seleção de exportação apontam para a prova T02. Testes gráficos T01 e T02 independentes permanecem executáveis.

## Implementado na T03

- `actors/player/player.tscn`, `PlayerConfig` e `PlayerController`: configuração Resource, física a 60 Hz e câmera explícita. Normalização de entrada, aceleração e rotação, controle habilitável e reset; valores do contrato preservados.
- `environments/locomotion.tscn`: arena técnica com piso, quatro paredes e rampa de 15°, herda a composição T01 e instancia o jogador. Esta arena é uma prova com primitivas, sem arte de ambiente aprovada.
- Probes reais de velocidade, colisão, chão/rampeamento e distância em 120 ticks sob limites de renderização 30/60/144.

## Implementado na T04

- ShotDefinition, ShotRig, CameraZone (`shot_priority`), CameraDirector e PresentationController implementam os contratos de enquadramento e troca atômica. Cada rig possui câmera, luz e oclusores; colisões compartilhadas permanecem independentes dos rigs.
- `environments/camera_study.tscn` herda a arena T03 e contém dois enquadramentos/zonas de estudo. Seleção por prioridade, empate atual, último válido e permanência de 0,2 s; enquadramento inicial explícito.
- `tests/check_cameras.gd` exercita 20 passagens por sentido com o controlador real e inspeciona a apresentação a cada tick/sinal. Movimento ainda usa a câmera corrente, até integração T05.

## Implementado na T05

- MovementReference conserva a base horizontal enquanto qualquer ação direcional estiver pressionada, inclusive oposição de teclas. PlayerController usa essa referência; PresentationController apenas atualiza a câmera corrente, preservando a base já capturada.
- Seta de ImmediateMesh no jogador indica direção mundial desejada. Reset/desabilitação limpam a referência. `movement_study.tscn` prova transições segurando W, diagonais e corrida; foi a cena principal até T05.
- Estudos SVG T01–T05 são provisórios; não foram aprovados como cenários finais.

## T06 — Concluída nos estudos autorais; ENV_1 pendente

- `CalibrationDefinition : ShotDefinition` registra dimensões, observações 2D, candidatos 3D, notas de escala e pose. `environments/calibration_env1.tscn` reutiliza a composição T01 com grade, cápsula de 1,8 m, marcadores e residuais, aplicando configurações manualmente editáveis via Resource no Inspector.
- Renders originais em `assets/backgrounds/env_1`; proporção nativa preservada, sem edição. Fichas em `resources/env_1` e `docs/calibration/ENV_1.md` são hipóteses, não contratos físicos aprovados.
- `tests/check_calibration.gd` separa probe de ferramentas de gate de alinhamento. Nos originais ENV_1, cam01 atende à meta numérica local e cam02/cam03 ainda a excedem. A geometria comum desses renders não foi aprovada.
- A cena de calibração expõe uma lista explícita de fichas. Teclas 1/2/3 selecionam a vista; G/M alternam grade/marcadores. Entrada restrita à prévia em execução, sem modificar recursos em disco ou o controle de gameplay. Repetição e soltura das teclas não alternam visibilidade.
- Por escolha explícita do usuário, T06 foi concluída com três fundos de estudo autorais de geometria conhecida. Fonte `route_study_source.tscn`, fichas `resources/route_study`, prévia `calibration_route_study.tscn`. Oito marcos por vista, medidos nos PNGs e comparados às projeções; erros máximos abaixo de 1 px. Outro executor reproduziu as fichas, conferiu os 24 marcos e inspecionou as quatro capturas. Originais ENV_1 preservados para refinamento.
- Autoria é offline, por `tools/author_route_study.gd`, seguida de importação e `tools/finalize_route_study.gd`. Não existe reconstrução/fitting automático. Regeneração reinicia o estado de revisão; a legenda diferencia estudo aprovado de hipótese pendente.

## T07 — Percurso técnico

Retomada de arte ENV_1: `env1_road_probe.tscn` é um ensaio isolado sobre o PNG cam02, usando a ficha revisada, jogador existente e faixa conservadora com colisões locais. Não possui cortes nem substitui T07. A máscara `CalibrationDefinition.reference_anchor_mask` distingue posições derivadas do plano hipotético de referências usadas para conferir o ajuste; âncoras não entram no mínimo nem no máximo do gate e têm prefixo A no overlay. Escopo/evidências em `calibration/ENV_1_REFINEMENT.md`.

- `technical_route.tscn` herda a composição e instancia o jogador T03/T05. É a cena principal, versão 0.0.7-t07. Fichas, fonte, referências de nós e volumes de zonas ficam explícitos no Inspector.
- `technical_route.gd` monta apenas este nível: instancia a fonte espacial oculta; copia suas dimensões/transforms para colisores compartilhados; cria três ShotRigs com cópias das malhas e o shader T02. Não renderiza a fonte visível em tempo real: o fundo é o PNG pré-renderizado e as cópias somente reproduzem sua cor enquanto escrevem profundidade.
- PlayerController, MovementReference, CameraDirector, CameraZone, ShotRig e PresentationController são reutilizados sem alteração. Zonas têm prioridades 0/1/2 e permanência de 0,2 s. Cortes não movem corpo nem colisores.
- Duas áreas de 12×12 m, corredor de 3 m, rampa de 1,2 m em 4 m, caixote contornável, passagem de 1,6 m na área elevada e ponto final dourado. `Endpoint` é Marker3D espacial; desde a T08 sua posição vem de `RouteProgress.end_pad`, que detecta a conclusão.
- `check_technical_route.gd` dirige o controlador por Input real, sem teleporte na ida/volta; verifica colisão, limites, contato com chão, enquadramento e cortes. `check_route_rendering.gd` verifica oclusão e emendas em três vistas × três resoluções. Capturas reais foram inspecionadas.
- Preset inclui explicitamente classes de câmera e shader usados na montagem, além de cenas/base/fundos. Exportação por seleção não os descobriu automaticamente, mesmo terminando com código 0. Build diagnóstica corrigida em `builds/windows-t07`; a build de release da T10 fica em `builds/windows-t10`.

## T08 — Operação básica e diagnóstico

- `ui/pause_menu.tscn` (`PauseMenu`): processa sempre (`PROCESS_MODE_ALWAYS`). Esc (ação `pause`) alterna `SceneTree.paused`; botões Continuar, Reiniciar percurso e Sair, navegáveis por teclado e mouse. `NOTIFICATION_APPLICATION_FOCUS_OUT` e `NOTIFICATION_WM_WINDOW_FOCUS_OUT` abrem a pausa; o retorno do foco não retoma. `pause_on_focus_loss` existe para probes que não exercitam esse caminho. Sinal `restart_requested`; o menu não conhece o nível.
- `ui/diagnostics_overlay.tscn` (`DiagnosticsOverlay`): F3 (ação `toggle_diagnostics`), também durante a pausa. Mostra FPS, tempo de quadro suavizado, posição, velocidade horizontal, chão, enquadramento ativo/candidato, estado e base da `MovementReference`, direção desejada, etapa/tempo do percurso e estado da simulação. Recebe referências do nível após a montagem em runtime.
- `environments/route_progress.gd` (`RouteProgress`): objetivo técnico local — alcançar a marca dourada e voltar à azul. Footprints 2 × 1,5 m dos pads autorais; roda em física, portanto pausa suspende etapa e relógio. Sinais `endpoint_reached` e `route_completed(elapsed)`; `checkpoint()` devolve o último pad alcançado na tentativa.
- `technical_route.gd` liga os três componentes. `restart()` restaura jogador (`reset_to_start`), câmera (`CameraDirector.reset_to(initial_shot)`), referência de movimento, objetivo e avisos. Pés abaixo de `recovery_height` (−4 m) acionam `recover()`: jogador no último pad, câmera do enquadramento cuja zona contém o pad (mesma regra de prioridade do diretor) e aviso temporário pausável. Sinais `restarted` e `recovered(checkpoint)`.
- Extensões mínimas de contratos existentes: `PlayerController.reset_to(transform)` (reset_to_start passa a usá-lo) e reset da referência em `NOTIFICATION_PAUSED` — pausar interrompe a entrada, e a próxima direção usa a câmera atual; `CameraDirector.reset_to(shot)` ativa imediatamente e descarta candidato. Sem autoload ou gerenciador global.
- `tests/check_operation.gd` exercita a cena real com eventos de teclado reais (`push_input`) para Esc/F3/setas/Enter e ações de Input para locomoção.

## T09 — Regressões

- `tests/run_all.gd`: executor sem plugin; cada probe em processo filho do mesmo executável. Aprovação = saída 0 + linha-resumo + ausência de linhas de erro do engine. Probes gráficos abrem janela própria; `--headless-only` os pula. Logs em `.local/tests/`.
- `tests/check_units.gd` e `tests/check_scenes.gd` cobrem unidades das classes reais e carregamento de todas as cenas; `check_scenes.gd` usa a classe `Logger` do engine para falhar sozinho em erros.
- `tests/capture_visual_report.gd` gera as capturas do relatório manual (`docs/TEST_REPORT.md`); não substitui a inspeção humana.

## T10 — Build e medição

- Preset `Windows Desktop`: exportação release em `builds/windows-t10`, console wrapper sempre gerado (`debug/export_console_wrapper=2`) para leitura de log/benchmark. Seleção explícita ganhou `environments/route_benchmark.gd`, instanciado só por script (mesma razão das classes de câmera na T07). UI e `RouteProgress` entram como dependências da cena principal.
- Templates de release não aceitam `--script`, `--scene` nem `--main-pack` (sem *path overrides*). Por isso a medição do gate roda dentro da cena principal: `technical_route.gd` cria `RouteBenchmark` apenas quando os argumentos de usuário contêm `--benchmark` (após `--`). O piloto automático usa ações de Input no controlador real, reinicia após cada volta, desliga VSync, pede tela cheia (ou janela 1920×1080 se recusada), amostra o tempo de parede entre quadros após o aquecimento e captura erros do engine por `Logger`. Grava `user://benchmark.txt` e `user://benchmark-frametimes.csv` e sai com 0 apenas se p95 ≤ 16,7 ms, sem erros e com ao menos uma volta concluída. Em `--headless` nada é renderizado: só a parte funcional é julgada.
- `tests/check_soak.gd`: dez minutos de jogo no percurso real (ida/volta caminhando e correndo, pausas, F3, reinícios no meio da volta, recuperações), falhando em erro do engine, volta que não termina ou crescimento de nós/objetos/memória estática.
- Fora do jogo exportado: modelos, ENV_1, testes, ferramentas de autoria e calibração.

Não há combate ou animais implementados. As demais interfaces abaixo continuam contratos para as tarefas correspondentes.

## Decisões e motivos

1. **2.5D com fundo estático e física 3D:** sustenta arte pré-renderizada e colisões espaciais consistentes.
2. **Cenas pequenas e referências explícitas:** permite executar tarefas isoladas sem gerenciador monolítico, ECS ou dependências de plugins.
3. **Configuração em Resource:** ajuste pelo Inspector e separação entre conteúdo e lógica.
4. **Uma tarefa por solicitação:** validar fundamentos antes dos dependentes e manter diffs revisáveis.
5. **Engine fixa:** `project.godot` informa compatibilidade 4.7, mas não trava patch; conferir `--version` e usar 4.7.2. Não atualizar silenciosamente.
6. **Exportação por seleção explícita do conteúdo usado:** evita distribuir assets não usados ou sem aprovação. A seleção deve evoluir junto com as cenas entregues. No fechamento T05, o filtro passou a `resources` para selecionar também a textura base usada por cenas herdadas; as cenas base são explícitas, e somente suas dependências entram no pacote.

## Composição planejada (T01–T02)

Ordem: TextureRect com background → SubViewport transparente com mundo 3D → UI/debug. Compartilhar o mesmo retângulo 16:9; usar barras em outras proporções. Preservar enquadramento, sem crop ou distorção.

Cada ShotRig possui câmera perspectiva fixa, definição, oclusores e luz dos atores. Geometria física pertence ao mundo contínuo; não deve desaparecer ao trocar de câmera. Oclusores são visuais por enquadramento e não substituem colisores.

Oclusão: malha opaca escreve profundidade e reproduz a imagem do fundo via SCREEN_UV, com shader unshaded. Não escrever ALPHA=0 nem desabilitar depth test para torná-la invisível. Usar a mesma imagem, área útil e orientação do background; testar cor e contornos em T02. Só os oclusores do enquadramento atual ficam visíveis.

Fixar exposição e desativar fog, glow e efeitos que alterem a equivalência visual na Fase 1. Sombras dinâmicas no background ficam para acabamento. Iluminação dos atores já será ajustável.

A troca de câmera, imagem e conjunto de oclusores deve ser atômica antes da próxima renderização. Não alterar o corpo físico ou teleportar o personagem ao cortar.

## Movimento planejado (T03 e T05)

- CharacterBody3D com cápsula e filho visual substituível.
- Gravidade e `move_and_slide()` em `_physics_process`.
- Eixos da câmera projetados no plano horizontal; W para o fundo da tela; A/D para os lados.
- Normalizar entrada para evitar ganho diagonal. Visual gira suavemente para o deslocamento.
- Guardar base da câmera no início da entrada. Manter enquanto houver direcional, mesmo após cortes. Liberar quando todas as teclas direcionais forem soltas.
- Valores iniciais: caminhada 2,5 m/s; corrida 5 m/s; aceleração 15 m/s²; desaceleração 20 m/s²; gravidade 20 m/s². Rotação configurável em PlayerConfig.
- WASD e setas; Shift corre. Sem mouse look, salto, esquiva, mira ou stamina na Fase 1.

## Interfaces mínimas planejadas

| Componente | Contrato |
| --- | --- |
| PlayerConfig : Resource | Velocidades, aceleração, desaceleração, gravidade, velocidade de rotação |
| PlayerController | Movimento físico, habilitar/desabilitar controle, reposicionar no início |
| ShotDefinition : Resource | ID, background e parâmetros da câmera |
| ShotRig | Definição, câmera e malhas de oclusão do enquadramento |
| CameraZone : Area3D | Volume, enquadramento e prioridade |
| CameraDirector | Seleção; sinal `shot_changed(previous_id, current_id)` |
| PresentationController | Aplicar câmera, imagem e oclusores juntos |
| MovementReference | Entrada de tela → direção horizontal, base conservada durante cortes |

Zonas: maior prioridade vence; empate preserva câmera atual; sem zona mantém última válida; candidato precisa permanecer ativo por pelo menos 0,2 s. O enquadramento inicial deve ser explicitamente configurado; não depender da ordem de callbacks de entrada.

Interação, tiros, alcance e dano futuros usam coordenadas e colisões 3D. Pixels do background não são autoridade de gameplay.

## Processo de conteúdo

Backgrounds pintados/IA serão calibrados manualmente com câmera e volumes, sem reconstrução automática. Ficha por enquadramento, seis referências perto/longe/esquerda/direita e cápsula de 1,8 m. Imagem incoerente deve ser corrigida ou rejeitada.

Manter modelos GLB em `assets/models`, fontes separadas, metadados de origem/licença/escala/orientação/aprovação. Não alterar o modelo existente como parte da preparação T00. Não assumir aprovação canônica de Dylan, Cryopteryx, narrativa ou arte pelo simples uso de placeholders.

## Referências oficiais

- https://godotengine.org/download/archive/4.7.2-stable/
- https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
- https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html

As páginas `stable` podem evoluir; a API observada no executável fixado prevalece para este projeto.
