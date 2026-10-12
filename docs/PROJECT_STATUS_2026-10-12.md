# Estado e pendências — 12/10/2026

Verificação da cópia local em `C:\Desenvolvimento\limar_beyond_time`, por leitura de código/configuração e execução de testes. Este retrato prevalece sobre afirmações históricas dos documentos citados; não aprova arte nem fecha T10.

## Resultado

A base técnica, exterior/guarita, terminal, pistola, gamepad e Keleken de estudo estão implementados. Ainda falta transformar esses componentes em uma experiência integrada, exportada e validada. Não foram encontrados defeitos nos 21 testes executados nesta verificação.

## Prioridades

| Ordem | Pendência | Evidência atual / condição de conclusão |
| --- | --- | --- |
| 1 | Definir a entrada da experiência integrada | `project.godot` inicia `technical_route.tscn`, com o jogador de cápsula do estudo técnico. Exterior, guarita e estande são acessados pelos atalhos. Definir entrada, novo jogo/continuar e navegação entre os conteúdos; adequar benchmark ao cenário que será entregue. |
| 2 | Preparar e validar a build Windows atual | Não existem `builds/windows-t10/LIMIAR-Recon.exe` nem templates em `%APPDATA%/Godot/export_templates/4.7.2.stable` nesta cópia. O preset já lista exterior e sala, mas usa seleção explícita de recursos; revisar dependências das classes novas instanciadas por código, exportar e executar fora do editor. A ausência de uma classe na lista não prova, sozinha, que ela ficará fora do pacote. |
| 3 | Fechar o aceite T10 | Executar build offline, regressões completas, exploração humana de dez minutos e medição 1080p com VSync desligado, 30 s de aquecimento + 120 s, p95 ≤ 16,7 ms na máquina de referência. Não foi refeito nesta verificação. |
| 4 | Combate com inimigos — implementado após este levantamento | Keleken tem percepção, alerta, perseguição/desistência, bicada com dano e morte por tiros. Dylan recebe dano, morre, reinicia, esquiva e consome kits. Saúde segue pelas portas e é salva. Validação em `tests/check_enemy_combat.gd` e detalhes em `COMBAT.md`; clipes dedicados de esquiva/morte continuam pendentes. |
| 5 | Completar animações do Dylan | Mira usa pose procedural; faltam clipes dedicados de repouso mirando, strafe, caminhada mirada, disparo e recarga. A locomoção lateral mirada reutiliza caminhada para frente. Evidência: `actors/player/dylan_visual.gd`, `actors/player/aim_pose.gd` e `docs/COMBAT.md`. |
| 6 | Completar persistência do carregador | `SaveGame` agora guarda saúde, progresso, posição/orientação e suprimentos. Não guarda munição no carregador; a sessão retomada começa com carregador cheio, conforme `COMBAT.md`. |
| 7 | Corrigir e validar apresentação | O colisor do poste já foi removido, mas seu oclusor continua desalinhado com a arte da vista 2. Alinhamento fino da sala e aceite dos renders originais ENV_1 continuam pendentes. Não houve nova inspeção visual nesta verificação. |
| 8 | Som e conteúdo do piloto | Sem áudio de disparo/animais no código de combate/Keleken. A missão atual termina no salvamento do terminal; documentos, rádio, outros animais, extração e jornada de 20–30 minutos continuam no backlog do plano. |
| 9 | Consolidar regressões, documentação e Git | `check_settings.gd` existe e passa, mas não está registrado em `tests/run_all.gd`. Há 23 arquivos rastreados modificados e arquivos novos de gamepad, configurações e Keleken ainda não versionados. `COMBAT.md` e `KNOWN_ISSUES.md` ainda dizem que falta gamepad, embora já exista e tenha passado no teste. README também mistura presets antigos e limites históricos com estado atual. |

## Validação executada

Godot local: `4.7.2.stable.official.ed1daf0bf`, Windows, headless.

Executor `tests/run_all.gd`, seleção de 20 probes, saída 0 e `T09 runner executed=20 failed=0`:

- unidades, cenas (23 cenas), locomoção, câmeras e referência;
- percurso e operação;
- sala/exterior, Dylan/portas e controles de tanque;
- gamepad, contato dos pés, animação e passeio do Keleken;
- salvamento, terminal, operação dos cenários, combate e abertura da cena principal.

Separadamente: `tests/check_settings.gd`, saída 0, `SETTINGS failures=0`.

Comando do executor:

```powershell
& '.\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/run_all.gd -- --only=unidades,cenas,locomocao,cameras,referencia,percurso,operacao,sala-geometria,exterior-geometria,dylan-portas,controles-tanque,gamepad,contato-pes,keleken-animacao,keleken-wander,salvamento,terminal-ui,operacao-cenarios,combate,cena-principal
```

Logs e resumo em `.local/tests/`. O teste de configurações foi executado diretamente e não integra esse resumo.

A primeira execução dentro do sandbox foi rejeitada pelo executor por erros de acesso aos logs em AppData e à loja de certificados do Windows; as asserções dos probes passaram. A repetição com acesso normal passou sem esses erros. Não tratar os erros iniciais como regressão do jogo.

Não executados nesta revisão: testes gráficos, suíte completa, soak de dez minutos, benchmark, exportação, calibração ENV_1 e uso manual do controle físico. As constatações visuais acima são pendências documentadas e conferidas no estado dos componentes, não novas medições de imagem.

Somente este relatório foi adicionado; nenhuma implementação de jogo foi alterada.
