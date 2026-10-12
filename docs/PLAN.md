# LIMIAR Recon — plano de execução incremental

Plano aprovado em 11/10/2026. Este arquivo é o contrato de escopo para os executores. Consulte `PROGRESS.md` para distinguir trabalho planejado de trabalho realizado.

## Objetivo e decisões

Entregar primeiro uma base jogável 2.5D, com personagens 3D sobre backgrounds pré-renderizados, câmeras fixas e colisões tridimensionais. Validar a combinação antes de combate, animais e produção visual definitiva.

| Aspecto | Decisão |
| --- | --- |
| Engine | Godot 4.7.2 Standard, GDScript tipado; versão fixa na Fase 1 |
| Plataforma | Windows x64, single-player offline |
| Renderizador | Forward+, sem efeitos pesados no protótipo |
| Visual | Backgrounds pintados ou gerados por IA; atores e objetos interativos 3D |
| Câmera | Fixa por enquadramento, cortes por zonas |
| Movimento | Relativo à tela, referência preservada durante cortes |
| Entrada inicial | WASD/setas; Shift para correr |
| Desempenho | 1920 × 1080, 60 FPS na máquina de referência |
| Fase 1 | Percurso técnico de 3–5 minutos |
| Piloto completo | Experiência de 20–30 minutos |
| Arte inicial | Placeholders substituíveis, sem aprovação canônica implícita |
| Exatidão arte × geometria | Diretriz do usuário (11/10/2026): só nas áreas em que o jogador interage — chão caminhável, limites e obstáculos com colisão, escadas/rampas, portas, objetos de interação e superfícies que ocultam o ator no trajeto. Fundo decorativo fora do alcance (árvores distantes, céu, telhados, detalhes inventados pela IA) não precisa coincidir com a geometria |

A proposta é tecnicamente viável. O risco principal é alinhar perspectiva da imagem, personagens e geometria invisível. Imagens geradas por IA não fornecem automaticamente câmera ou profundidade confiáveis; cada enquadramento exige calibração.

Estado anterior à implementação: pasta sem projeto Godot ou Git. Na execução T00, já havia um modelo do usuário em `assets/models/keleken/model_base.glb`; preservá-lo.

## Estrutura e contratos

Criar sistemas progressivamente, somente na tarefa correspondente:

```text
res://
  actors/player/
  actors/animals/
  systems/camera/
  systems/combat/
  systems/interaction/
  systems/inventory/
  systems/missions/
  systems/audio/
  environments/
  resources/
  assets/models/
  assets/backgrounds/
  assets/audio/
  ui/
  tests/
  docs/
```

Usar cenas pequenas, referências explícitas no Inspector e sinais. Não criar gerenciador global de todos os sistemas, ECS ou framework de plugins. Separar configurações (`Resource`) de lógica. Os contratos detalhados estão em `ARCHITECTURE.md`.

## Sequência executável da Fase 1

**Uma tarefa por solicitação ao modelo.** Dependência de cada tarefa: conclusão e revisão técnica da anterior. Nunca avançar automaticamente para a próxima.

Autorização específica de 11/10/2026: o usuário pediu continuidade até T07, escolheu fundos de estudo com perspectiva consistente e autorizou revisão independente da T06 por subagente. Essa autorização permite concluir T06 e T07 na mesma solicitação, preservando os critérios abaixo e os renders ENV_1 para refinamento. Não abrange T08.

Autorização de 11/10/2026, sessão local: o usuário pediu "prossiga com o projeto para novas features", sem nomear a tarefa. Foi seguida a ordem sugerida pelo próprio `PROJECT_AUDIT.md`, implementando a pendência de prioridade 2 "levar a operação básica aos cenários novos" com objetivos da Fase 1, e em seguida os pedidos diretos de menu e presets de filtro. Essa autorização dispensa a regra de "uma tarefa por solicitação" acima para esses itens; não abrange trocar a cena principal do projeto, exportar build nem o backlog posterior à Fase 1.

Autorização seguinte (sessão em nuvem iniciada em 11/10/2026): o usuário pediu retomar a última tarefa pendente da lista e continuar o máximo possível sem consultas, pois estaria ausente por cerca de cinco horas. Essa autorização permite executar T08, T09 e T10 em sequência, mantendo dependências, critérios de aceite, revisão técnica e inspeção visual de cada tarefa. Não abrange o backlog posterior à Fase 1 (combate, animais, missões) nem aprovação de ENV_1.

### T00 — Preparar projeto e registro de decisões

- Entregar projeto mínimo Godot 4.7.2 com cena inicial vazia, Git, exclusões, diretórios de assets e preset Windows x64.
- Criar `PLAN.md`, `ARCHITECTURE.md`, `PROGRESS.md` e `KNOWN_ISSUES.md` em `docs`.
- Localizar ou instalar distribuição oficial e templates da mesma versão. Registrar caminho, versão, CPU, GPU e resolução dos testes.
- Aceite: abrir o projeto no editor e executar cena vazia sem erros.
- Limite: nenhum gameplay. A pasta `assets/models` deve existir, preservando conteúdo prévio.

### T01 — Provar composição 2D + 3D

- Entregar background geométrico provisório em TextureRect, cápsula 3D iluminada em SubViewport transparente e composição 16:9.
- Redimensionar com barras, sem esticar ou recortar.
- Aceite: cápsula sobre imagem sem retângulo opaco; mesmo alinhamento em 1920 × 1080, 1280 × 720 e janela 4:3.
- Limite: câmera única; sem personagem controlável; não depender de arte final.

### T02 — Provar profundidade e oclusão

- Entregar obstáculo no background, volume físico, malha de oclusão com material definido na arquitetura e cápsula percorrendo automaticamente a frente e o fundo do obstáculo.
- Aceite: cápsula visível na frente e ocultada atrás; sem emenda de cor ou deslocamento ao redimensionar.
- Bloqueio: corrigir a prova antes de avançar. Não substituir por foreground que cubra o personagem independentemente da profundidade.

### T03 — Implementar locomoção básica

- Entregar cena de jogador independente, PlayerConfig, caminhada, corrida, gravidade, colisão, rotação visual e arena com piso, paredes e rampas.
- Aceite: diagonal sem ganho de velocidade, paredes sólidas, ausência de deriva parado, rampas caminháveis e distância consistente em simulação de duração fixa sob diferentes taxas de renderização.
- Limite: câmera única; sem salto, combate, esquiva, mira ou stamina.

### T04 — Implementar enquadramentos e cortes

- Entregar ShotDefinition, ShotRig, CameraZone e CameraDirector, com dois enquadramentos do mesmo espaço.
- Trocar câmera, imagem e oclusores juntos; implementar prioridade, permanência mínima e manutenção do último enquadramento válido.
- Aceite: atravessar a transição 20 vezes em cada sentido sem tela vazia, imagem incorreta ou oscilação contínua.

### T05 — Preservar movimento nas transições

- Entregar MovementReference, integração com entrada/controlador/câmera e indicador de direção mundial desejada.
- Aceite: segurar W durante corte mantém direção mundial; soltar todas as teclas direcionais e pressionar novamente usa a câmera atual. Repetir com diagonais e corrida.
- Limite: sem controles tanque ou seleção de esquemas.

### T06 — Estabelecer calibração de backgrounds

- Entregar grade 3D, marcadores de debug, cápsula de 1,8 m e ajustes de câmera no Inspector.
- Ficha por enquadramento: imagem, dimensões, câmera, escala e pontos de referência.
- Ajuste manual no editor, sem reconstrução automática por IA.
- Pelo menos seis referências distribuídas entre perto/longe e esquerda/direita; buscar erro máximo de oito pixels em 1080p nos estudos. Pela diretriz posterior do usuário, a meta vale para as referências das áreas em que o jogador interage; fundo decorativo fora do alcance fica isento.
- Aceite: outro executor reproduz e confirma o enquadramento pela ficha.
- Corrigir ou rejeitar imagens incompatíveis; nunca distorcer o personagem para compensar a perspectiva.

### T07 — Montar percurso técnico

- Duas áreas pequenas conectadas por corredor; três enquadramentos e backgrounds de estudo provisórios.
- Um obstáculo contornável, passagem estreita, rampa e ponto final; colisão e oclusão coerentes.
- Estudos pintados simples; geração de imagem externa não é dependência obrigatória.
- Aceite: completar ida e volta sem atravessar limites visuais, ficar preso ou sair dos enquadramentos.

### T08 — Operação básica e diagnóstico

- Esc para pausa, botão de reinício, F3 para FPS/posição/enquadramento/referência de movimento, conclusão técnica e recuperação abaixo do cenário.
- Perder foco pausa; voltar ao app não retoma automaticamente.
- Aceite: pausa suspende física e cortes, UI continua operável; reinício restaura jogador, câmera e entrada.

### T09 — Automatizar regressões e testar visualmente

- Executor GDScript simples, sem plugin obrigatório; testes de normalização, referência de movimento, câmera e carregamento de cenas.
- Testar componentes reais, não duplicações da implementação.
- Relatório manual de colisão, oclusão, resolução e continuidade visual.
- Aceite: falhas geram código de saída diferente de zero; todos os casos obrigatórios passam. Headless não substitui inspeção visual.

### T10 — Exportar e fechar primeiro marco

- Build Windows x64, instruções, controles, relatório de testes/limitações e progresso atualizado.
- Aceite: executável funciona offline fora do editor, percurso completo sem erros ou referências ausentes, regressões aprovadas e desempenho medido.
- A Fase 1 termina aqui. Não antecipar combate ou animais.

## Aceite do primeiro percurso jogável

| Área | Critério |
| --- | --- |
| Movimento | Caminhada/corrida com colisão consistente, sem ganho diagonal |
| Câmeras | Cortes estáveis nos dois sentidos e em sobreposições |
| Continuidade | Direção preservada enquanto houver entrada direcional |
| Composição | Fundo, atores e oclusores alinhados em todas as resoluções de teste |
| Profundidade | Frente e trás corretos nos obstáculos previstos |
| Operação | Pausa, retomada, reinício e conclusão sem estado residual |
| Robustez | Dez minutos de exploração sem erro, travamento ou saída irrecuperável |
| Exportação | Build funcional fora do editor |
| Desempenho | 1080p, VSync desligado, 30 s de aquecimento e 120 s de percurso; p95 do tempo de quadro ≤ 16,7 ms |

Registrar medições reais. Desempenho no graybox não comprova o desempenho do piloto final. Os critérios desta seção pertencem ao percurso, não à cena vazia da T00.

## Assets e dependências

Fase 1: Godot e templates da mesma versão, Git, três backgrounds provisórios, cápsula e primitivas. Não exige Blender, plugins pagos, modelos finais ou serviço externo de IA.

Piloto: Dylan com modelo/rig/animações (locomoção, mira, tiro, esquiva, interação, dano e morte); quatro animais com comportamento e animações próprios; arma e objetos; backgrounds, colisores e oclusores por enquadramento; som ambiente/passos/arma/animais/rádio/UI; elementos de UI e fonte licenciada.

Preferir GLB no jogo e fontes em diretórios separados. Registrar origem, licença, escala, orientação e aprovação. Assets disponíveis não são automaticamente aprovados nem distribuíveis.

## Riscos e mitigação

| Risco | Mitigação |
| --- | --- |
| Perspectiva de IA inconsistente | Calibrar estudos; corrigir ou rejeitar imagem incompatível |
| Oclusão incorreta/emendas | Prova T02; repetir ao mudar renderizador, exposição ou escala |
| Personagem flutuante | Referência de altura, chão e contato; sombras de contato depois |
| Desorientação em cortes | Manter referência e testar os dois sentidos |
| Fundo estático limitar efeitos | Iluminação por enquadramento; portas móveis e objetos alteráveis separados |
| Executor ampliar escopo | Uma tarefa por execução, contratos fixos, revisão antes da próxima |
| Placeholder virar cânone | Status provisório e aprovação separada de anatomia, narrativa e arte |
| Polimento impedir conclusão | Terminar percurso técnico antes dos cenários definitivos |

Causa do desaparecimento indefinida. Cryopteryx provisório até aprovação de anatomia, escala e comportamento. Conteúdo original/licenciado; não reproduzir assets de Dino Crisis.

## Backlog após a Fase 1

| Ordem | Entrega | Gate |
| --- | --- | --- |
| P1 — Combate | Uma arma, mira para câmera fixa, munição, recarga, dano, saúde e esquiva | Acertos 3D, parede bloqueia tiro, dano e morte funcionam |
| P2 — Kelenken | Percepção, território, investigação, risco, perseguição e desistência | Encontro resolvível sem combate; retorno à rotina |
| P3 — Exploração/missão | Interação, documentos, rádio, inventário mínimo e objetivos | Sequência de objetivos completa sem combate obrigatório |
| P4 — Outros animais | Ankylosaurus defensivo, Cryopteryx de alta ameaça, Quetzalcoatlus terrestre | Perfis distintos por recurso; herbívoro sem perseguição predatória genérica |
| P5 — Piloto | Floresta, perímetro, estação, extração, menus, checkpoints e final | Jornada de 20–30 min observados; recuperação após morte |
| P6 — Acabamento | Arte aprovada, animação, som, luz, contato com chão e otimização | Regressão completa e desempenho com conteúdo final |

IA futura: máquina de estados reutilizável, estados habilitados por espécie e AnimalProfile. Não implementar ecossistema, necessidades metabólicas ou competição interespecífica no MVP. Detalhes das fases futuras serão fechados nos pacotes correspondentes.

## Protocolo do executor

> Leia plano, arquitetura, progresso e problemas conhecidos. Execute somente a tarefa [ID]. Confirme a conclusão/revisão da dependência e inspecione os componentes existentes. Reutilize contratos; não antecipe fases nem substitua arquitetura. Faça a menor alteração completa, execute verificações e regressões relevantes. Separe implementado, testado automaticamente, verificado visualmente e não verificado. Atualize progresso com arquivos, decisões, comandos, resultados e limitações. Se bloqueado, registre reprodução mínima e não avance. Ao concluir, entregue resumo verificável e pare.

Cada registro contém ID, dependências, estado, alterações, evidências e pendências. Estados: pendente, em execução, bloqueada, pronta para revisão, concluída. Revisar diff e aceite antes da tarefa seguinte. Inspeção visual pendente impede declarar conclusão; compilação sozinha não basta.
