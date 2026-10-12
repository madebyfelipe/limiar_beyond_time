# Relatório de testes — percurso técnico (T09)


## Armas, mira e suavização — Windows, 11/10/2026 (sessão Opus 5.5)

Godot `4.7.2.stable.official.ed1daf0bf`, Forward+/Vulkan, NVIDIA RTX 4050 Laptop GPU. Trabalho feito num worktree isolado (`.claude/worktrees/armas`, branch `feat/armas`), sem outro agente escrevendo nos mesmos arquivos.

**Suíte completa, duas passadas seguidas no estado final: 36 probes, 0 falhas, saída 0 — e de novo 36 probes, 0 falhas, saída 0.** Inclui o probe novo `combate` (808 ticks, 0 falhas), o soak de dez minutos, todas as regressões gráficas e o `terminal-ui` do Codex. O gate de desempenho continua `NÃO MEDIDO` em headless.

Antes de chegar lá, quatro execuções completas, registradas como aconteceram:

| Execução | Estado | Resultado |
| --- | --- | --- |
| 1 | base `0aa2722` | **Morreu em silêncio** depois do probe 21 (`cena-principal`), ao iniciar `robustez-10min`: saída 0, sem resumo. Mesmo sintoma do handoff, mas **sem segundo agente** — não é colisão. Não reproduziu isolado nem depois. Continua aberto em `KNOWN_ISSUES.md`. |
| 2 | base + suavização em edição | 35 probes, 1 falha: `operacao-grafica`, "Fall below the level was not recovered from (8.5, 0.5, -6.0)". Causa: pausa por perda de foco ligada no probe inteiro; foco real da área de trabalho pausava a queda. Reproduzido injetando a perda de foco, corrigido no probe. |
| A | armas, antes da escala de 1,8 m | 36 probes, 1 falha: `benchmark-funcional`, 0 voltas em 45 s com a máquina carregada (5881 quadros contra 6524 isolado). Rota técnica usa o jogador-cápsula, sem arma: não é regressão. Janela ampliada para 75 s. |
| B, C | estado final | 36/0 e 36/0. |

`check_combat.gd` (`combate`, novo): auto-mira do tanque pega o alvo visível mais próximo e ignora o escondido atrás da parede; Tab percorre Low → Left → Far → Low; pés plantados com a arma erguida; quatro tiros derrubam o alvo e a arma passa ao próximo; a parede para o tiro; ↑ inclina; giro à mão solta a trava na velocidade do tanque; recarga tira do estoque real e não acontece com estoque zero; antebraço alinhado ao tiro a 0,00°; três modos modernos medidos (cursor, livre 360 sem deriva ao andar e ao cortar câmera, assistida com cone de 20°); caminhada mirada a 1,26 m/s de lado; tiro do peito de um corpo de 1,8 m; página JOGABILIDADE; nenhuma escrita em `settings.cfg`. **Dez defeitos reintroduzidos, todos acusados** — tabela em `COMBAT.md`.

`check_retro_filter.gd`: no nível PSX, com bilinear, 2629 de 2673 blocos interiores passam a ter gradiente; voltar ao mais próximo restaura a imagem byte a byte; o botão do menu alterna e dá a volta.

## Apresentação montável e operação nos cenários — Windows, 11/10/2026

Godot `4.7.2.stable.official.ed1daf0bf`, Forward+/Vulkan, NVIDIA RTX 4050 Laptop GPU.

**Esta seção não registra uma suíte completa verde.** A última execução completa deu **33 probes, 2 falhas**, e é anterior a boa parte do que foi entregue depois. As duas falhas vieram de uma segunda sessão de agente escrevendo no mesmo diretório ao mesmo tempo, não de defeito do código: `exterior-grafico` reprovou com `Parse Error: Could not find type "RetroScreen"` enquanto essa classe estava sendo escrita, e `filtro-retro` reprovou porque o HUD novo passou a ser desenhado dentro da composição 16:9, que é a área amostrada pelo filtro. Antes disso, uma execução inteira **morreu em silêncio no probe 21**, com código 0 e sem linha de resumo — comportamento de processo encerrado, compatível com duas instâncias do Godot competindo; reexecutada, passou. Registro completo em `../HANDOFF.md`.

Verificados individualmente contra o estado final: `filtro-retro` (gráfico), `operacao-cenarios` (172 ticks), `salvamento` (136 ticks), `dylan-portas` (1164 ticks), `exterior-geometria` (4100 ticks, 55 colisores), `sala-geometria` (2415 ticks) e `unidades` — todos com 0 falhas. A suíte inteira precisa ser reexecutada duas vezes quando houver uma mão só no repositório.

`check_retro_filter.gd` foi reescrito para o modelo montável: cada nível de pixelização renderiza diferente dos outros, **cada efeito muda a tela sozinho** (cinco verificações, uma por interruptor), desligar tudo restaura a composição byte a byte, o pixel virtual continua inteiro nos níveis médio e PSX em 1280 × 720, 1920 × 1080 e 1280 × 960, as barras pretas seguem intactas, as escolhas sobrevivem à troca de cena e a página do menu dirige o mesmo modelo.

Duas medições que viraram correção de produto, não de teste:

| Medida | Antes | Depois |
| --- | --- | --- |
| Degrau de brilho entre linhas vizinhas, com varredura ligada | 0,0068 (contra 0,0072 sem efeito — **invisível**) | 0,0777, 10,8 × a base |
| Pixels sem imagem com a tela de tubo ligada | 11 851, uma moldura preta | 60, contra 44 da base — **sem moldura** |

A varredura era invisível porque 360 bandas numa janela de 720 linhas dão um pixel por banda e a reamostragem as devolve como cinza chapado; o limite caiu para 240. E a métrica anterior do probe contava pixels alterados entre linhas, que uma cena nevada já satura em ~50% — passou a medir linhas inteiras escurecendo juntas.

`check_level_operation.gd` (`operacao-cenarios`, novo): **172 ticks, 0 falhas**. Esc pausa em vez de sair nas duas cenas e congela o ator com tecla pressionada; F3 liga/desliga e nomeia o enquadramento ativo; perda de foco pausa; a rede devolve o ator de 40 m abaixo do chão ao ponto firme; o objetivo começa na estrada, avança na cancela, **não retrocede** ao voltar, avança ao entrar e ao salvar, vai para o registro e volta dele numa sessão nova; reiniciar pelo R e pelo menu zera ator, câmera e objetivo sem apagar o registro.

Um defeito que esse probe pegou antes de entrar: o terminal gravava a etapa **anterior** à do próprio salvamento, então salvar e fechar o jogo devolvia o objetivo "registre o progresso no terminal" com o jogador parado na frente do terminal recém-usado.

## Salvamento e colisor do poste — Windows, 11/10/2026

Godot `4.7.2.stable.official.ed1daf0bf`, Forward+/Vulkan, NVIDIA RTX 4050 Laptop GPU. Executor completo: **32 probes, 0 falhas, saída 0**, já com o probe novo. O soak de dez minutos e as oito regressões gráficas passaram junto; o gate de desempenho continua `NÃO MEDIDO` em headless, como sempre.

`check_save_persistence.gd` (`salvamento`, novo no executor): **124 ticks, 0 falhas**. Alcance do terminal, repetição de tecla que não duplica a gravação, ida e volta de posição/orientação/contador/horário, confirmação na tela, retomada em sessão nova, chegada pela porta ignorando o registro, e três registros que não devem ser obedecidos — de outra sala, de formato desconhecido e apontando para cena inexistente. Usa `user://save_probe.cfg`: a suíte nunca lê nem sobrescreve o salvamento de quem joga na máquina.

Como da outra vez, a aprovação de primeira não foi aceita como prova. Três defeitos reintroduzidos de propósito: `resume()` que nunca restaura reprova em 4 asserções; sem guarda de cena, o registro do exterior derruba o jogador para `y = −2,04` dentro da sala (2 falhas); sem guarda de formato, 1 falha. Com o código correto, 0 falhas nas duas execuções seguintes. A data mostrada na tela foi conferida à parte, porque nenhuma asserção verifica formato de data: `REGISTRO 1 · 11/10/2026 21:51` contra `2026-10-11T21:51` do sistema, fuso −180 min.

Um erro meu no próprio probe merece registro, porque é do tipo que passa escondido: o primeiro teste de "E fora do alcance do terminal" foi feito no spawn da sala, que **é** o ponto de aproximação da porta. A asserção passava — nenhum registro era gravado — mas por motivo errado: E abria a porta e tirava o controle do jogador, e é por isso que as asserções seguintes reprovavam. O teste passou para o meio da sala e ganhou duas asserções que pegam exatamente esse engano (`E in the middle of the room opened the door` e `The player lost control without interacting with anything`).

`check_exterior.gd` ganhou duas asserções pelo colisor removido do poste: nenhum corpo estático chamado `LightPole` e a cápsula do jogador livre na base do poste. Headless: **4100 ticks, 97,85 m, 55 colisores, 0 falhas**; gráfico: 4110 ticks, 97,91 m, mesmos 55 colisores. Repondo o colisor no `exterior_source.tscn`, a execução dá **56 colisores e 2 falhas**, as duas novas — a asserção foi verificada contra o defeito, não só contra o acerto.

## Captura de movimento, enquadramento e controles — Windows, 11/10/2026

Godot `4.7.2.stable.official.ed1daf0bf`, Forward+/Vulkan, NVIDIA RTX 4050 Laptop GPU. Executor completo: **31 probes, 0 falhas, saída 0**, já com os dois probes novos.

`check_foot_contact.gd` (`contato-pes`) mede o pé que está no chão enquanto o corpo anda, pelo controlador real, e reprova deslize: **0,04 m/s sob um corpo a 1,80 m/s** e **0,36 m/s a 3,80 m/s**. Amostra só com o corpo livre — encostado numa parede, o deslocamento aponta para fora da frente do personagem e nenhum ciclo mantém contato. Foi assim que a patinação relatada ficou objetiva: a cadência vinha de uma estimativa de passada 24% alta.

`check_tank_controls.gd` (`controles-tanque`): **363 ticks, 0 falhas**. Giro no lugar sem deslocar o corpo, avanço ao longo da frente, ré mais lenta e no sentido oposto, preferência preservada na troca de cena, esquema de câmera intacto quando selecionado, e parada em menos de 0,25 m depois de soltar a tecla. Depois da entrada das capturas de giro e de ré, o probe também exige o clipe certo em cada caso — `turn_left` à esquerda, `turn_right` à direita com rotação horária conferida, e `walk_back` na ré. Essa verificação pegou as duas capturas de giro trocadas entre si: o sentido foi então medido pela direção do quadril, não pelo nome do arquivo. Depois do relato do usuário sobre o pivô jogar o corpo para o lado, o probe passou a medir também o ângulo entre a frente renderizada e a direção comandada (limite 15°) e o salto da base dos pés (limite 0,15 m). A asserção foi validada contra o próprio defeito: com a guinada reintroduzida no builder ela reprova com `Pivot points the body 72.6 deg away from its heading`, e volta a passar com a correção. Vale registrar que as 31 regressões passavam com o defeito presente — nenhuma olhava para onde o corpo apontava.

Probes ajustados para não fixarem velocidade: `distance_sampler.gd` integra a expectativa a partir do `PlayerConfig` e `check_locomotion.gd` compara com os valores configurados; o contrato numérico continua em `check_units.gd`. A rampa passou a ser verificada por chegada, não por tempo fixo. O recorte da vista 2 foi medido à parte: reprojeção de 818 pontos da área caminhável com erro de 0,000 px.

Uma execução gráfica de `operacao` falhou uma vez por perda de foco da janela durante a suíte (o próprio probe documenta esse risco com entrada sintética) e passou em três execuções seguidas depois, além da suíte completa final.

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
