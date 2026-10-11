# ENV_1 — retomada e ensaio com o render original

11/10/2026. Solicitação: retomar a calibração e continuar usando os renders. **Ensaio local disponível; integração das três vistas ainda não aprovada.** O percurso T07 e sua build continuam com os estudos técnicos. Continuação posterior: `ENV_1_CONTINUITY.md` registra um ensaio com três vistas originais, a hipótese de ligação, os diagnósticos numéricos e as cópias de arte candidatas. As seções abaixo descrevem o ensaio isolado original.

## Executar e avaliar

Dar dois cliques em `executar-estrada-isolada.cmd`, ou abrir `environments/env1_road_probe.tscn` e usar F6. WASD/setas movem, Shift corre e G mostra a faixa limitada de ensaio. A cápsula mantém 1,8 m e escala unitária. Fechar pela janela do Windows. `executar-render-original.cmd` agora abre o ensaio posterior com três vistas.

Esta cena usa o PNG original da cam02, a câmera da ficha e o controlador existente. A faixa de aproximadamente 16 m permite observar escala e contato aparente com o chão durante a caminhada. Os limites invisíveis ficam deliberadamente afastados de guarda-corpo, pedras e portão; G os torna visíveis. Não representam a largura completa da estrada. Há uma câmera, sem teleporte, conexão com outras vistas, acesso ao portão, escada ou oclusores de vegetação/guarda-corpo. Não é uma aprovação disfarçada do ambiente nem substitui T07.

## O que foi revisto

A ficha anterior de cam02 supunha estrada reta, FOV 50° e pares perto/médio em estações iguais. Seus pontos direitos estavam em neve/rocha, sem borda identificada. Essa construção foi abandonada. O máximo antigo de 490,330 px e o novo máximo **não são comparáveis como medida de melhora do mesmo conjunto**, pois as referências mudaram.

A nova hipótese usa perspectiva mais comprimida: posição `(63.80803,34.98116,-25.13368)`, rotação `(-34,126.5,0)` e FOV vertical **15°**. Ajustes de pose/lente e dimensões foram declarados manualmente, sem otimizador, reconstrução automática ou edição do PNG. Portão: plano X=12, Z de 2,2 a 7,8, Y de 0 a 1,6 m. São dimensões de trabalho, não medidas reais.

Os quatro pontos inferiores dos postes foram usados como âncoras de posicionamento sobre o plano candidato y=0, com análise de raios e arredondamento manual. **Não são pés físicos confirmados:** a inspeção ampliada mostra apoios ocultos ou estendendo-se abaixo da pista. Seus pequenos resíduos não comprovam que o chão seja plano. Os quatro pontos superiores testam uma separação vertical comum de 1,3 m; não foram dadas alturas livres para cada poste. A incerteza de identificação dos capuzes/apoios ainda precisa de revisão.

`reference_anchor_mask` marca essas quatro âncoras. Elas continuam visíveis no overlay, com prefixo A, mas não contam para o mínimo de seis pares nem para o máximo usado pelo gate. Os outros oito pontos incluem quatro cantos do portão utilizados no ajuste, portanto também não devem ser descritos como oito observações independentes de um ajuste cego.

| ID | Referência | Pixel original | Candidato 3D | Erro 1080p |
| --- | --- | --- | --- | --- |
| 1 | Portão topo esquerdo | 1063,132 | 12;1,6;7,8 | 4,024 px |
| 2 | Portão topo direito | 1310,219 | 12;1,6;2,2 | 0,858 px |
| 3 | Portão base direita | 1301,289 | 12;0;2,2 | 4,508 px |
| 4 | Portão base esquerda | 1058,203 | 12;0;7,8 | 1,992 px |
| A5 | Poste próximo inferior, âncora | 483,730 | 31,35;0;5,85 | excluído |
| 6 | Poste próximo superior | 475,669 | 31,35;1,3;5,85 | 5,593 px |
| A7 | Poste médio A inferior, âncora | 665,521 | 25,1;0;7,15 | excluído |
| 8 | Poste médio A superior | 661,458 | 25,1;1,3;7,15 | 2,580 px |
| A9 | Poste médio B inferior, âncora | 762,432 | 21,9;0;7,5 | excluído |
| 10 | Poste médio B superior | 758,363 | 21,9;1,3;7,5 | 9,016 px |
| A11 | Poste distante inferior, âncora | 887,312 | 17,3;0;8,1 | excluído |
| 12 | Poste distante superior | 892,253 | 17,3;1,3;8,1 | 5,511 px |

O alvo 10 foi corrigido de 754,368 para 758,363 após inspeção ampliada do capuz do poste. Recorte anotado local em `.local/env1-post-b-inspect.png`; originais intactos. Máximo final sem âncoras **9,01570 px**, ainda acima de 8. O portão isolado tem máximo 4,508 px. A distribuição à direita ainda se concentra no portão; não valida toda a borda rochosa.

## Cam01/cam03 e continuidade

Fichas preservadas: máximos **7,00475 / 32,26464 px**. Foram examinadas hipóteses manuais de lado da fachada, campo de visão mais estreito, largura de porta e base da escada compartilhada. As variantes não resolveram conjuntamente porta/escada sem piorar outras referências e não foram salvas nas fichas. Nenhuma imagem foi declarada impossível.

O ajuste de cam01 continua local à porta/escada. Cam02 não tem um marco comum identificado com essas duas vistas; o portão de madeira visível nela não deve ser automaticamente identificado com a cancela listrada da guarita. A intenção do usuário de mesma estrada no sentido oposto foi preservada como requisito, não convertida em correspondência física inventada.

Para a integração contínua ainda faltam: identificar correspondências físicas entre os trechos, fechar o proxy comum de plataforma/escada e confrontar marcos distribuídos do chão. Não conectar cenários por teleporte nem mover alvos para a projeção para esconder os erros. O ensaio local permite avaliar a arte agora, enquanto essa geometria permanece pendente.

## Reprodução e evidências

```powershell
$GodotExe = 'E:\LIMIAR\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --headless --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_env1_road_probe.gd
& $GodotExe --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_env1_road_probe.gd
& $GodotExe --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_calibration.gd
& $GodotExe --headless --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_calibration.gd -- --acceptance
```

- Probe de caminhada headless/gráfico final: **1748 ticks, zero falhas**, saída 0. Controlador real, ida/volta sem teleporte, corrida, chão, escala unitária, limites laterais e das duas extremidades, cabeça enquadrada e pés dentro de um polígono traçado separadamente sobre a estrada original. G e barras 4:3 conferidos. Isso valida a faixa de ensaio, não a estrada inteira, a escala absoluta ou oclusão.
- Capturas `env1-road-start`, `far`, `returned`, `rail-limit`, `limits` e `4x3` em `user://`, preservadas em `.local/`. Início, extremo distante e limites inspecionados pelo executor principal; revisor também inspecionou 4:3.
- Reprodução independente autorizada: probe headless aprovado e capturas revisadas; nenhum bug funcional bloqueante no escopo local. Logs `.local/env1-road-independent.log` e `env1-calibration-independent.log`. O revisor apontou risco de chamar âncoras de correspondências independentes; corrigidos Resource, legenda, overlay e log. Sua execução numérica precede a última correção observacional do alvo 10 e a máscara de âncoras.
- Gate final: **duas falhas esperadas**, cam02/cam03, saída 1. Ferramenta gráfica: saída 0. Logs `.local/env1-refine-graphical-final.log` e `env1-refine-acceptance-final.log`. Probes finais da faixa em `.local/env1-road-check-final.log` e `env1-road-graphical-final.log`. Gate dos estudos e abertura T07 também passaram, mantendo os valores anteriores.
- O ensaio não mede FPS, não valida exploração humana prolongada e não foi exportado. Originais e modelos preservados; nenhum avanço para T08.
