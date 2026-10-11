# Verificação do projeto — 11/10/2026

**Retrato anterior à implementação de Dylan/portas.** Na solicitação seguinte, os ciclos de animação, integração de Dylan na guarita, ligação exterior/interior e interação E foram implementados, e a engine local foi instalada para testes. Estado atualizado em `DYLAN_ANIMATION.md` e `PROGRESS.md`. As pendências abaixo permanecem como registro da análise original.

Revisão da cópia em `C:\Desenvolvimento\limar_beyond_time`. Escopo: código, cenas, recursos, configuração de exportação, testes e documentação. Nenhum sistema de jogo foi alterado.

## Conclusão

O projeto contém uma base técnica 2.5D implementada, um percurso técnico com operação básica e estudos jogáveis de exterior/interior. Ainda não é um piloto integrado. T10 permanece com aceite pendente; os cenários novos não estão incluídos na entrega exportada configurada.

Os testes anteriores descritos abaixo são evidências documentadas de outras sessões. Não foram reexecutados nesta revisão.

## O que já existe

- Composição com fundo pré-renderizado, atores 3D e oclusão por profundidade.
- Controlador com caminhada, corrida, gravidade e colisões; referência de movimento preservada durante cortes.
- Câmeras fixas, zonas, prioridade e permanência mínima para cortes.
- Percurso técnico com pausa, reinício, F3, objetivo de ida/volta e recuperação de queda.
- Exterior com três vistas e trajeto estrada → cancela → escada → porta; interior com circulação e comparação entre geometria/arte.
- Executor de regressões e probes para componentes, percurso, operação, sala e exterior.

## Pendências prioritárias

| Prioridade | O que falta | Evidência e condição para concluir |
| --- | --- | --- |
| 1 | Preparar e validar a execução nesta cópia | `.tools` contém somente `.gdignore`; a engine exigida pelos atalhos não está instalada ali nem foi encontrada como `godot`/`godot4` no PATH. O caminho histórico `E:\LIMIAR` também não está disponível. Instalar a versão contratada e reimportar os assets antes de executar os probes. |
| 1 | Fechar o aceite T10 | Não há executáveis em `builds` nesta cópia. Os templates não foram encontrados no caminho padrão documentado. Gerar a build Windows, confirmar funcionamento offline fora do editor, executar regressões e registrar benchmark na máquina de referência: 1080p, 30 s de aquecimento + 120 s de medição, p95 ≤ 16,7 ms. Não há aqui resultado novo que encerre esse gate. |
| 1 | Corrigir o poste na arte externa da vista 2 | `environments/exterior.gd` ainda usa `art_cam02_v02.png`; a v03 não existe. A ficha registra desvio de 26–50 px em 1080p e colisor em área alcançável. A decisão registrada é corrigir a imagem; guia, máscara e prompt já estão em `docs/calibration/exterior/pole_fix`. Integrar a correção e verificar alinhamento/oclusão e regressões. |
| 1 | Validar o alinhamento final da sala | A arte é candidata. A ficha não registra medição independente de pelo menos seis correspondências distribuídas nem aprovação do gate de 8 px nas áreas de interação. Movimento e colisão no 3D não comprovam esse alinhamento. |
| 2 | Ligar exterior e interior | Os scripts não implementam troca de cena na porta. A porta externa bloqueia o ator; a sala é aberta separadamente. Falta definir entrada/saída, posicionamento e orientação do jogador e estado preservado durante a passagem. |
| 2 | Implementar interação e salvamento | A sala tem terminal e circulação, mas não possui ação de interação nem persistência de progresso. O checkpoint de `RouteProgress` é apenas um pad em memória para recuperar quedas no percurso técnico. Falta salvar, carregar e verificar recuperação após fechar/reabrir o jogo. |
| 2 | Integrar Dylan ao conteúdo novo e animá-lo | Exterior, sala e percurso instanciam `player.tscn`, com ator de prova. Dylan aparece nos ensaios dos renders originais. O GLB não contém animações e o adaptador aplica pose fixa. A integração deve rever a altura de trabalho de 2,4 m, enquadramento, colisão e passagem por portas/obstáculos. |
| 2 | Levar a operação básica aos cenários novos | Exterior e sala têm R para reiniciar e Esc para sair. Não instanciam o menu de pausa, F3, objetivos e recuperação presentes no percurso. Esses comportamentos precisam ser integrados se as cenas virarem o fluxo principal. |
| 2 | Entregar o conteúdo novo na build | `project.godot` inicia `technical_route.tscn`; o preset seleciona recursos do percurso técnico. Exterior, sala, seus fundos e Dylan não fazem parte dessa seleção. Após integração, atualizar entrada/preset e testar o pacote exportado para detectar dependências ausentes. |
| 2 | Atingir a duração prevista da Fase 1 | O probe do percurso registrou 36,12 s simulados para ida caminhando/volta correndo. Não há validação de exploração humana de 3–5 min. Repetir voltas por dez minutos comprova outra propriedade: robustez. |
| 3 | Fechar conteúdo visual e sonoro | Há pendências de sombras de contato, continuidade dos materiais entre vistas e enquadramentos adicionais para usar toda a sala em produção. `assets/audio` contém apenas `.gitkeep`; não foram encontrados players de áudio no código/cenas examinados. |
| 3 | Completar metadados dos assets e consolidar documentos | Origem/licença/aprovação dos modelos permanecem não verificadas no inventário. A documentação mistura estado atual e histórico; `KNOWN_ISSUES.md` ainda diz que o executor não foi validado no Windows, enquanto `TEST_REPORT.md` registra posteriormente oito probes de conteúdo aprovados no Windows. Esse registro parcial não fecha o aceite da build T10. |

## Conteúdo posterior à Fase 1

O backlog do plano ainda está por implementar:

1. P1: arma, mira, munição, recarga, saúde, dano, morte e esquiva.
2. P2: comportamento do Kelenken — percepção, investigação, perseguição, desistência e rotina.
3. P3: interação, documentos, rádio, inventário e objetivos de missão.
4. P4: comportamentos próprios das outras três espécies.
5. P5: piloto integrado de 20–30 min, menus, checkpoints, extração e final.
6. P6: arte aprovada, animação, som, iluminação e desempenho com o conteúdo final.

Esses itens não são defeitos das provas técnicas e não foram implementados antecipadamente nesta revisão.

## Renders originais ENV_1

São uma frente separada dos novos fundos autorados. Permanecem preservados, com ensaios de circulação e hipótese espacial. As fichas registram erros máximos de aproximadamente 7,005 / 9,016 / 32,265 px, com duas vistas reprovadas. Não existe aprovação da geometria comum que permita tratá-los como substituição final do percurso.

## Verificações feitas nesta revisão

- Leitura de plano, progresso, problemas conhecidos, relatório de testes e fichas de calibração recentes.
- Inspeção de cenas/scripts de percurso, exterior, sala, jogador e configuração de exportação.
- Conferência de 98 caminhos literais estáticos `res://` em scripts/cenas/recursos/configuração: nenhum alvo ausente. Caminhos dinâmicos e saídas locais foram excluídos dessa contagem; ela não verifica importação, parsing ou carregamento no engine.
- Conferência dos fundos externos ativos: v02 da vista 2 presente; v03 ausente.
- Verificação de ferramentas, build, logs locais e caminho padrão dos templates: indisponíveis nesta cópia.
- `git diff --check` sem problemas antes da criação deste relatório.

Não houve execução do Godot, benchmark, inspeção visual nova ou comprovação de que as regressões passam atualmente.

## Ordem sugerida

Primeiro restaurar a execução local e fechar as verificações técnicas pendentes. Para evoluir o cenário da guarita, corrigir o poste e validar a arte da sala; depois integrar exterior/interior, personagem e operação básica, seguindo com interação/salvamento. Exportar e medir novamente o conteúdo integrado. Encerrar o marco técnico antes de iniciar o backlog de combate e animais.

## Referências

- `docs/PLAN.md`: critérios de aceite e backlog.
- `docs/PROGRESS.md`: estado e histórico das entregas.
- `docs/TEST_REPORT.md`: resultados documentados das regressões.
- `docs/calibration/exterior/EXTERIOR_GEOMETRY.md`: alinhamento externo e decisão sobre o poste.
- `docs/calibration/exterior/pole_fix/README.md`: preparação da correção.
- `docs/calibration/SAVE_ROOM_GEOMETRY.md`: limites do estudo interno.
- `assets/models/README.md`: inventário e integração de Dylan.
