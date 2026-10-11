# ENV_1 — ensaio contínuo com três renders

Atualização posterior de 11/10/2026: Dylan agora usa ciclos idle/walk/run gerados em `dylan_visual.gd`, preservando a altura de 2,4 m deste ensaio. Os registros abaixo sobre pose fixa descrevem a integração anterior. A porta interativa está no novo exterior autorado, não neste ensaio dos renders originais; ver `../DYLAN_ANIMATION.md`.

11/10/2026. Os três PNGs originais já podem ser percorridos no mesmo ensaio. **Funcionamento da faixa verificado; calibração do ambiente ainda pendente.** O usuário autorizou corrigir cópias dos renders quando necessário, preservando os originais. T07 principal e build permanecem com os estudos aprovados; T08 não foi iniciada.

## Abrir

`executar-render-original.cmd`, ou F6 em `environments/env1_continuity_probe.tscn`. WASD/setas movem, Shift corre, G revela limites. Segurar a direção durante um corte conserva o movimento mundial; soltar e pressionar novamente adota a câmera atual. **Começa na estrada cam02 e troca para cam01 na ponta próxima indicada pelo usuário**, ao caminhar para a parte inferior da imagem; continuar leva à cam03. O retorno usa as mesmas posições e colisões. A cena anterior da estrada isolada continua em `executar-estrada-isolada.cmd`, também com Dylan.

## O que a ligação significa

Há um único jogador e piso y=0. Dylan usa adaptação uniforme do modelo para altura de trabalho 2,4 unidades, 33% acima da primeira integração de 1,8, conforme ajuste visual solicitado. O CharacterBody continua com escala unitária; colisão tem altura 2,4, centro y=1,2 e raio 0,3. Isso é escala visual provisória do ensaio, não medida real do personagem. A faixa autoral foi estendida: estações (X;limite Z maior) (0,8;4,4), (9,6;4,4), (14,2;3,2), (18,2;3,0); largura 1,6. Paredes de 0,2 m e raio reduzem a região acessível. Os limites ficam diante da escada/caixas e são limites de ensaio, não paredes encontradas na imagem.

Cam01/cam03 usam suas poses existentes. Para inverter a ligação conforme a imagem do usuário, a cam02 recebe uma transformação rígida no ShotDefinition temporário: giro de 180° em Y e origem (39,2;0;7,2). Portanto X mundial=39,2−X local e Z mundial=7,2−Z local. Após a segunda indicação do usuário, a entrada navegável da cam01 foi fixada em **(8,5;0;3,6)**, junto ao poste/cancela mostrado no recorte. `env1_camera_director.gd` usa o centro do jogador, sem a espera de residência nesse corte, para impedir navegação da cam01 além dessa entrada. O retorno ocorre em X≥8,55, com margem de 5 cm para estabilidade. A faixa permite variação lateral; o ponto indicado é o centro de referência da entrada, não um teleporte para coordenadas fixas. Os cortes com cam03 conservam o comportamento padrão de zonas/residência. A antiga translação −20 m em X foi substituída. Não há marco físico comum que valide essa posição: continua sendo hipótese de montagem. O portão de madeira não foi equiparado à cancela listrada. As fichas de calibração permanecem intactas.

CameraDirector, CameraZone e PresentationController existentes fazem os cortes. Nenhum corte move o jogador, o piso ou os obstáculos. A inversão de orientação da cam02 permite experimentar o sentido oposto solicitado. Isso não comprova a identidade espacial dos elementos ao fundo.

Escada, plataforma, cancela, caixas e vegetação ainda não têm colisão/oclusão correspondente nesse ensaio. A faixa fica diante dos elementos, sem acesso a eles. Não há sombra de contato autoral. A concordância dos pés com regiões visíveis da estrada não valida escala absoluta, declive ou toda a superfície do chão.

## Diagnóstico da guarita e correção de arte

Foi acrescentado um diagnóstico numérico local, diferente dos ajustes manuais anteriores: projeção pinhole equivalente à Godot, mínimos quadrados limitados, somente pose/FOV da câmera. Os seis pontos 3D compartilhados e os alvos 2D ficaram fixos. O script não escreve fichas nem imagens. Não se trata de reconstrução automática da cena, e seus resultados não substituem o aceite visual/distribuído do plano. Scripts `tools/calibration/env1_pose_diagnostic.py` e `env1_layout_diagnostic.py` usam NumPy; a primeira tentativa com SciPy indisponível foi substituída, sem instalação de pacotes.

O candidato a partir da pose corrente reduziu o máximo cam03 de 32,265 para 18,780 px e atingiu o limite inferior de FOV 10°. Outra inicialização encontrou cerca de 18 px. Três geometrias alternativas declaradas manualmente também foram examinadas, sem obter simultaneamente menos de 8 px nas duas vistas. Nenhuma foi aplicada. São buscas locais e referências concentradas na porta/escada: não provam incompatibilidade matemática das imagens.

Após autorização do usuário, a skill imagegen e a ferramenta nativa produziram duas cópias 1672×941:

- `assets/backgrounds/env_1_candidates/cam03_v1.png`: tentativa local de alinhar porta e pés da escada à projeção da ficha atual. A base permaneceu aproximadamente horizontal, em vez da inclinação solicitada.
- `assets/backgrounds/env_1_candidates/cam03_v2.png`: segundo ajuste da base; o apoio esquerdo foi deslocado demais para a esquerda. Continua fora do alvo. Também há deriva visual fora da escada, portanto não é uma edição estritamente localizada.

**Ambas ficaram fora das cenas.** Não são renders calibrados. A inspeção de recortes identifica desvios da ordem de dezenas de pixels no apoio esquerdo; não foi emitido um gate de seis pontos dessas candidatas. Um diagnóstico exploratório da v2, com identificação aproximada dos dois apoios e os quatro alvos antigos da porta, também permaneceu acima de 8 px; não serve como medição final da nova imagem.

Os prompts completos e o método de execução estão preservados em `art_candidates/cam03_v1_prompt.txt` e `cam03_v2_prompt.txt`. Alvos nativos pedidos: porta TL (744,6;319,9), TR (811,0;324,7), BR (811,8;520,4), BL (747,4;508,8); apoios da base (817,0;645,5) e (966,1;667,7). Esses alvos são projeções da hipótese escolhida, não observações independentes. As cópias permitem avaliar o método de correção sem modificar o inventário original.

## Verificação

Entrada restrita após indicação do segundo shot: `check_env1_continuity.gd` passou em headless e gráfico com **1551 ticks, 50,547 m simulados com repetições e zero falhas**. A cada tick, cam01 exige X<8,56; a entrada a partir da estrada exige X≤8,5 e X>8,4. Cortes registrados na entrada: X≈8,467 caminhando/correndo; retorno X≈8,632, um passo após cruzar a margem de 8,55. Esse limite preserva a posição do personagem e sua direção mantida. Logs `.local/entry-point-{headless,graphical}.log`; captura `env1-continuity-dylan-after-cut.png` inspecionada. O diretor compartilhado dos estudos permanece igual.

Atualização Dylan/troca invertida: modelo fornecido tem 26 ossos, material/textura e nenhum AnimationPlayer/clipe no GLB. `actors/player/player_dylan.tscn` herda o controlador, esconde cápsula/seta e instancia o original. `dylan_visual.gd` corrige frente +X para −Z e abaixa os braços por pose local, sem editar malha/skin/GLB. Ainda se move em pose fixa, sem ciclo de caminhada/corrida. A colisão base técnica de T07 não foi alterada.

Probe atualizado: 1552 ticks, aproximadamente 50,542 m simulados com repetições, zero falhas em headless e gráfico com Dylan ampliado. Verifica cam02 inicial, nenhuma troca no extremo distante, corte no trecho inferior indicado, ida e retorno, limites, cabeça na altura atual enquadrada, apresentação sincronizada, G e barras 4:3. Capturas finais `env1-continuity-dylan-{road-start,before-cut,after-cut,guardhouse,road-return,far-limit,guardhouse-limits,4x3}.png` em `.local/`. Logs `dylan-enlarged-{headless,graphical}.log`. Medição gráfica da malha deformada confirmou base y=0,000018 e altura 2,4, mantendo os pés no chão. Probe isolado atualizado para verificar a altura real da colisão passou com 1748 ticks/zero falhas, log `dylan-enlarged-isolated.log`. A revisão independente abaixo é da versão anterior de cápsula, não da instalação/ampliação do Dylan.

Os resultados a seguir registram a versão anterior da faixa:

Engine 4.7.2.stable.official.ed1daf0bf; testes com `--fixed-fps 60`:

```powershell
$GodotExe = 'E:\LIMIAR\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --headless --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_env1_continuity.gd
& $GodotExe --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_env1_continuity.gd
```

- Headless e gráfico: **1094 ticks, 41,734 m simulados, zero falhas**, saída 0. Ida, volta correndo, lados da faixa, limites nas quatro direções, contato com piso, escala unitária, cabeça enquadrada, passos sem salto, fundo/câmera sincronizados. Pés comparados com polígonos traçados separadamente nas três imagens. Os 41,734 m incluem repetições e desafios; não são o comprimento da faixa.
- Primeira versão falhou ao pressionar a extremidade perto das caixas. O limite mínimo passou de X=0 para 0,8; polígonos de verificação não foram alargados para esconder a falha.
- G e barras 4:3 passaram graficamente. Capturas em `.local/env1-continuity-*.png`; início, cam01 e final inspecionados pelo executor. Revisor inspecionou também limites e 4:3.
- Reprodução pelo revisor autorizado: mesmos 1094 ticks/41,73 m, zero falhas. Nenhum bug funcional bloqueante no escopo; não aprovou calibração/globalidade. Log `.local/env1-continuity-independent.log`.
- Originais conferidos por SHA-256, iguais ao inventário. Nenhuma ficha, controlador compartilhado, cena principal ou preset alterado. Testes da faixa não substituem o gate original, que continua reprovando cam02/cam03.
- Verificação final: os dois launchers iniciados de `.local` e abertura T07 headless retornaram 0. Gate dos estudos retornou 0 (máximos 0,772 / 0,987 / 0,584 px); gate ENV_1 retornou 1 com exatamente duas falhas (7,005 / 9,016 / 32,265 px). Logs `env1-continuity-launcher`, `env1-isolated-launcher`, `env1-continuity-t07-smoke`, `env1-continuity-study-regression` e `env1-continuity-acceptance` em `.local/`. Não houve nova exportação nem medição de FPS.

Próxima etapa geométrica: definir a fonte espacial autoral da guarita, plataforma e escada e conferir referências distribuídas da estrada antes de aceitar uma cópia corrigida. As tentativas de edição por coordenadas em texto não demonstraram precisão suficiente. A faixa atual permite avaliar movimento e cortes com a arte original durante esse trabalho.
