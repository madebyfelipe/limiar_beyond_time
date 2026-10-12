# Arquitetura — LIMIAR Recon


## Combate — pistola, mira e alvos, 11/10/2026

- `systems/combat/`: `PlayerWeapon` (filho `Weapon` do `player_dylan.tscn`) é o **único dono da mira**. Processa antes do corpo (`process_physics_priority = -1`); `PlayerController` e `DylanVisual` só leem `aiming`, `heading` e `turn_input`. Tanque com a arma erguida: pés plantados e corpo girado pela arma. Esquema câmera: pernas pelas teclas, corpo encarando a mira, 70% da caminhada.
- `AimSettings` (estático, `user://settings.cfg` seção `[aim]`, mesmas regras do `ControlScheme`): modo da mira moderna — cursor no chão / livre 360 / assistida / alvo travado — e mira automática do tanque. O livre 360 guarda o rumo em espaço de **mundo**, para não mudar a cada corte de câmera. Alvo travado seleciona pelo cursor ao erguer e conserva a identidade; roda/Tab alternam, gatilho mantido repete somente nesta opção. `lock_indicator.gd`, dentro do quadro, distingue seleção, bloqueio e alvo fora da tela do retículo 3D de impacto.
- `AimSolver` leva o mouse da janela ao `SubViewport` 3D (`SubViewportContainer` com `stretch`) antes de virar raio; o container ignora mouse, então nada depende de eventos chegarem ao viewport.
- Tiros e linhas de visada são raios 3D do peito (2/3 da altura da cápsula: 1,2 m no Dylan de 1,8 m). Camadas físicas nomeadas: 1 "mundo", 3 "alvos". `Hurtbox` (Area3D na camada 3) encaminha dano a um `Health`; ao zerar, sai da camada e do grupo `combat_targets`. Pode apontar o próprio `body` para não bloquear a linha de visada até si.
- `AimPose` (`SkeletonModifier3D` filho do `Skeleton3D`) monta a pose de pistola sobre qualquer clipe, com `influence` em rampa. Resultado de modificador só é legível em `modification_processed`/`skeleton_updated`; a pistola é posicionada nesse sinal.
- Menu de pausa: a linha `CONTROLES` virou `JOGABILIDADE`, que abre uma página (`_build_gameplay_page`) com esquema de controle, mira moderna e mira automática. Detalhes em `COMBAT.md`.

## Apresentação PSX/CRT — 11/10/2026

`systems/rendering/retro_filter.tscn` é o último filho da composição Background/Actors, antes da UI. BackBufferCopy + shader de canvas fazem amostragem nearest em 320×180, quantização RGB e dithering Bayer, com scanlines/vinheta opcionais. Origem e extensão da área útil mantêm a grade alinhada ao redimensionar e deixam barras pretas intactas. Cada instância tem material próprio; F4 compartilha a seleção durante a sessão pelo script/grupo, sem autoload. A porta instancia o mesmo componente dentro do seu quadro, com cópia de tela própria, abaixo do fade; quadro e filtro são ocultados juntos na troca. A resolução do viewport 3D e as câmeras continuam sendo autoridade de composição/oclusão. Detalhes e testes em `RETRO_FILTER.md`.

## Dylan e passagem entre ambientes — 11/10/2026

- `dylan_visual.gd` gera uma biblioteca AnimationPlayer com idle, walk, run e door_interact. Tracks de rotação usam os ossos reais e convertem os eixos pelos ancestrais já posados; a malha, skin e GLB permanecem intactos. Velocidade real do corpo seleciona e regula a locomoção, com blend de 0,16 s. Nenhum root motion interfere na física.
- Exterior e sala instanciam `player_dylan.tscn`, com altura visual/colisão locais de 1,8 m. O padrão de 2,4 m continua nos ensaios originais. `target_height` controla apenas a apresentação; ao alterar escala de uma cena, atualizar também sua colisão e validar enquadramento.
- `ApproachPrompt` é a base das interações locais: jogador, ponto de aproximação, raio e o aviso na tela, visível exatamente enquanto E faria algo. Uma só definição de "estar perto" — distância horizontal dentro do raio e diferença de altura <0,25 m — serve porta e terminal.
- `DoorInteraction` estende essa base com orientação e caminho do destino (raio padrão 0,85 m). Gesto e viagem bloqueiam movimento e novas interações.
- `TerminalInteraction` estende a mesma base (raio 0,8 m) e grava o registro por `SaveGame`, confirmando na tela. `SaveGame` é estático, sem autoload, como `ControlScheme`; a sala retoma dele ao abrir e uma guarda de cena impede que um registro de outro ambiente reposicione o jogador. Campos e limites em `SAVE_SYSTEM.md`.
- `MissionState` guarda o objetivo da Fase 1 em quatro etapas, também estático e também sem autoload, e viaja no registro de salvamento. `LevelOperation` instala menu de pausa, diagnóstico F3, avisos passageiros e a rede de queda nos cenários que montam o runtime em código, em vez de cada um repetir o arranjo do percurso. Detalhes em `LEVEL_OPERATION.md`.
- `RetroFilter` virou tabela de presets sobre um shader só: o framebuffer PSX é a base e cada preset acrescenta varredura, grade de abertura, curvatura de tubo e vinheta, com ganho para o preset não virar apenas "mais escuro". F4 e o menu percorrem a mesma tabela, e a escolha fica em `user://settings.cfg`. Ver `RETRO_PRESETS.md`.
- `door_transition.gd` é uma CanvasLayer temporária no root, com mundo 3D próprio e composição 16:9. Sobrevive à troca de cena, anima maçaneta/folha/câmera, troca o ambiente sob preto e chama `arrive_from_door()` no destino. Depois restaura controle e se libera. Sem autoload ou gerenciador global. As portas pintadas e seus colisores ficam intactos.
- A cena principal/preset técnicos permanecem T07/T10. O fluxo conectado está disponível em `executar-exterior.cmd` e `executar-sala.cmd`.

## Estudos autorados de interior e exterior — 11/10/2026

- `save_room_source.tscn` e `exterior_source.tscn` são fontes espaciais editáveis, construídas antes da arte por scripts em `tools/`. Suas capturas e fichas de câmera são as referências estruturais para image_gen.
- `save_room.tscn` permite comparar arte/geometria e inspecionar o interior. `exterior.tscn` reutiliza CameraDirector, CameraZone, ShotRig e MovementReference com três enquadramentos do mesmo mundo.
- `exterior_presentation.gd` estende PresentationController: após a troca atômica existente, aplica o shader de background na fonte compartilhada ou restaura seus materiais para inspeção. Colisores são copiados uma vez das dimensões/transforms autoradas e permanecem independentes da apresentação.
- Exterior e sala agora estão conectados por interação E e transição; a cena principal e o preset da Fase 1 não mudaram. Arte candidata e limitações em `docs/calibration/SAVE_ROOM_GEOMETRY.md` e `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`.

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
- Um plano pode ser reenquadrado sem refazer a arte: `zoom`/`focus` em ShotDefinition estreitam o frustum da câmera e ampliam a arte em torno do mesmo ponto. Como é o mesmo pinhole sobre um retângulo menor do plano de imagem, o registro entre pintura e geometria se mantém — a reprojeção foi medida em 0,000 px. O corte é aplicado em três lugares que precisam concordar: `ShotRig._apply_crop()` (frustum), `background_crop.gdshader` (placa de fundo) e `background_occluder.gdshader` (oclusores que se repintam com a placa).
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

Combate: primeira fatia implementada (ver topo e `COMBAT.md`). Não há animais nem inimigos. As demais interfaces abaixo continuam contratos para as tarefas correspondentes.

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
- Valores vigentes desde 11/10/2026: caminhada 1,8 m/s; corrida 3,8 m/s; aceleração 26 m/s²; desaceleração 40 m/s²; gravidade 20 m/s². Rotação configurável em PlayerConfig. As velocidades acompanham a passada das capturas do Dylan (1,48 e 2,73 m/s), e as rampas firmes removem a derrapagem ao soltar a tecla; o contrato anterior era 2,5/5,0 com 15/20. `tank_turn_speed` 1,5 rad/s e `tank_reverse_factor` 0,45 regem o esquema de tanque, ambos escolhidos para ficar perto do que as capturas de giro e de marcha à ré carregam.
- WASD e setas; Shift corre. No exterior, Q esquiva e H usa kit médico; `PlayerController` possui Health, imunidade breve e bloqueio por morte. Arma/mira em `PlayerWeapon` e combate do Keleken em `KelekenActor`; regras em `COMBAT.md`. Sem mouse look, salto ou stamina.

## Interfaces mínimas planejadas

| Componente | Contrato |
| --- | --- |
| PlayerConfig : Resource | Velocidades, aceleração, desaceleração, gravidade, velocidade de rotação, giro e ré do modo tanque |
| ControlScheme | Preferência de controle (câmera ou tanque), estática no processo e gravada em `user://settings.cfg` |
| PlayerController | Movimento físico, habilitar/desabilitar controle, reposicionar no início |
| ShotDefinition : Resource | ID, background, parâmetros da câmera e o recorte projetivo (`zoom`/`focus`) do enquadramento autorado |
| ShotRig | Definição, câmera e malhas de oclusão do enquadramento |
| CameraZone : Area3D | Volume, enquadramento e prioridade |
| CameraDirector | Seleção; sinal `shot_changed(previous_id, current_id)` |
| PresentationController | Aplicar câmera, imagem e oclusores juntos |
| MovementReference | Entrada de tela → direção horizontal, base conservada durante cortes |

Zonas: maior prioridade vence; empate preserva câmera atual; sem zona mantém última válida; candidato precisa permanecer ativo por pelo menos 0,2 s. O enquadramento inicial deve ser explicitamente configurado; não depender da ordem de callbacks de entrada.

Interação, tiros, alcance e dano futuros usam coordenadas e colisões 3D. Pixels do background não são autoridade de gameplay.

## Processo de conteúdo

Backgrounds pintados/IA serão calibrados manualmente com câmera e volumes, sem reconstrução automática. Ficha por enquadramento, seis referências perto/longe/esquerda/direita e cápsula de 1,8 m. Imagem incoerente deve ser corrigida ou rejeitada.

Diretriz do usuário (11/10/2026): a exatidão geométrica entre arte e geometria só importa onde o jogador interage. Isso inclui chão caminhável, limites e obstáculos com colisão, escadas/rampas, portas, objetos de interação e superfícies que ocultam o ator ao longo do trajeto. Elementos decorativos fora do alcance (árvores distantes, céu, telhados, ornamentos inventados pela IA) podem divergir da geometria. Se um elemento decorativo tiver colisor em área alcançável, ou o colisor some, ou o elemento passa a contar como área de interação.

Manter modelos GLB em `assets/models`, fontes separadas, metadados de origem/licença/escala/orientação/aprovação. Não alterar o modelo existente como parte da preparação T00. Não assumir aprovação canônica de Dylan, Cryopteryx, narrativa ou arte pelo simples uso de placeholders.

## Referências oficiais

- https://godotengine.org/download/archive/4.7.2-stable/
- https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
- https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html

As páginas `stable` podem evoluir; a API observada no executável fixado prevalece para este projeto.
