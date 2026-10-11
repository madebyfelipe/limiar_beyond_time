# ENV_1 — fichas de calibração provisórias (T06)

Data: 11/10/2026. **Não aprovado para percurso.** O usuário confirmou que as imagens são geradas/pintadas, sem dados de câmera, e que cam02 mostra a mesma estrada no sentido oposto. Isso confirma a intenção de continuidade, sem fornecer medidas ou geometria.

Atualização: após concluir T06/T07 com estudos, o usuário pediu retomar ENV_1. Há agora um **ensaio local de caminhada sobre o render original cam02**, aberto por `executar-render-original.cmd`. Ficha atual da cam02, limites e evidências em [ENV_1_REFINEMENT.md](ENV_1_REFINEMENT.md). Máximos atuais sem âncoras: **7,005 / 9,016 / 32,265 px**; o gate global continua reprovando cam02/cam03. As seções de cam02 abaixo registram a hipótese anterior, substituída. T07 segue como cena principal.

## Inventário preservado

Todos os originais têm **1672 × 941**. A extensão dupla `.png.png` foi preservada. Origem: fornecidos pelo usuário; licença e aprovação canônica não verificadas.

| Arquivo em `assets/backgrounds/env_1/` | SHA-256 |
| --- | --- |
| env01_cam01_bg.png.png | 51BB38751A272D40F9675C25166BFF4094BA66DFAAF3F3EA1B3D0E1BB6EB7892 |
| env01_cam02_bg.png.png | 799FD70959F27C6DBF256CE8E6A2CAAA9C5B36B7718E3323A414D2DF196F7F73 |
| env01_cam03_bg.png.png | F37148C434192B34DA3B1A3DECA4F7E81FE82E02D74B823EF5F1B116B672095D |

## Reprodução e ajuste manual

1. Usar Godot 4.7.2 Standard. Abrir `environments/calibration_env1.tscn`; a ficha inicial é cam03. A cena principal do projeto é o percurso T07.
2. Selecionar o nó CalibrationEnv1 e abrir `definition` no Inspector. Trocar esse recurso entre `resources/env_1/calibration_cam01.tres`, `calibration_cam02.tres` e `calibration_cam03.tres`.
3. Ajustar manualmente `camera_position`, `camera_rotation_degrees` e `fov` no recurso. A cena `@tool` aplica os valores e atualiza a grade/legenda. Alterar diretamente a câmera filha será sobrescrito pelo recurso.
4. A grade usa um metro por célula, configurável no nó raiz; `show_grid` a oculta. A cápsula tem 1,8 m, raio 0,3 m e escala (1,1,1). Sua posição é configurável; nunca alterar sua escala para compensar perspectiva.
5. Cruzes magenta numeradas representam observações 2D. Marcadores verdes representam projeções das hipóteses 3D; linhas amarelas mostram o residual. Revisar os alvos contra a imagem e a geometria antes de aprová-los.
6. Executar o probe gráfico para gravar evidências e o gate numérico para detectar hipóteses que não atingem a meta. Outro executor ainda precisa reproduzir e confirmar o enquadramento para fechar T06.

```powershell
$GodotExe = 'E:\LIMIAR\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --path E:\LIMIAR --editor res://environments/calibration_env1.tscn
& $GodotExe --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_calibration.gd
& $GodotExe --headless --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_calibration.gd -- --acceptance
```

Para abrir a prévia diretamente no Windows, executar `executar-calibracao.cmd` na raiz. Na janela da prévia, **1/2/3** trocam a ficha, imagem, câmera, cápsula e referências; **G** alterna a grade e **M** alterna os marcadores 3D e a sobreposição 2D. As alterações de seleção/visibilidade não são salvas nos recursos. No Godot, abrir a cena `calibration_env1.tscn` e usar **F6**, pois **F5 executa o percurso T07**. Os probes `SceneTree` acima exigem `--script`; não se executam pelo F6. As builds diagnósticas não contêm esta prévia de arte.

O primeiro probe verifica ferramentas e carregamento; **saída 0 nele não aprova a calibração**. O segundo exige seis correspondências e erro máximo ≤8 px; atualmente retorna **1**. Nenhum dos dois comprova sozinho coerência física ou revisão independente.

A imagem é ajustada por `KEEP_ASPECT_CENTERED`, preservando sua proporção nativa. Em uma área útil 1920×1080, a escala uniforme é 1080/941, a largura resultante 1918,9798 px e a margem horizontal aproximadamente 0,5101 px por lado. Os alvos usam pixels da imagem original, com origem no canto superior esquerdo; o erro é normalizado para a altura 1080. Janelas 4:3 mantêm barras externas.

## Hipóteses espaciais anteriores, ainda sem confirmação

Eixos Godot: X lateral, Y vertical, Z longitudinal; uma unidade = um metro **por hipótese**. Porta de 0,9 × 2,1 m sobre plataforma y=1,1 m. Cam01/cam03 compartilham os mesmos seis pontos 3D candidatos. A base da escada é uma hipótese centrada em (2,25;0;0,5), largura aproximada 1,6 m e direção da largura girada 12,5°; não foi construída escada ou colisão.

Para cam02, a hipótese é estrada acompanhando X, com bordas em Z=2 e Z=8, portão em X=12 e chão plano y=0. Na revisão manual, os alvos esquerdos de corrimão e os dois alvos da travessa do portão passaram a y=1,1 m; os alvos direitos perto/médio continuam no chão. Essa altura é provisória. Os pares perto/médio não têm evidência de pertencer às mesmas estações longitudinais X=28/20. Postes, declive, curva da estrada e identidade dos marcos **não foram confirmados**. Não usar essas coordenadas como autoridade de gameplay.

Os ajustes desta execução foram manuais nos recursos, com inspeção de capturas; não houve otimizador, reconstrução automática, modificação das imagens ou ajuste da escala da cápsula. A interação de edição pelo Inspector ainda precisa de confirmação por um revisor; abertura da cena no editor e sua execução foram verificadas.

## Cam01 — vista aberta da guarita/estrada

- Recurso: `resources/env_1/calibration_cam01.tres`.
- Câmera posição (-12,70145;2,31744;9,786856), rotação em graus (-3;-59;0), FOV vertical 50°, projeção perspectiva.
- Cápsula: base (2,25;0;2); grade centrada na origem.

| ID | Alvo candidato | Pixel original (x,y) | Ponto 3D hipotético (x,y,z) | Erro 1080p (px) |
| --- | --- | --- | --- | --- |
| 1 | Porta inferior esquerda | 723,493 | 0;1,1;0 | 4,660 |
| 2 | Porta inferior direita | 748,493 | 0,9;1,1;0 | 5,710 |
| 3 | Porta superior direita | 749,363 | 0,9;3,2;0 | 3,682 |
| 4 | Porta superior esquerda | 724,364 | 0;3,2;0 | 7,005 |
| 5 | Base esquerda da escada | 803,558 | 1,469;0;0,673 | 3,691 |
| 6 | Base direita da escada | 840,548 | 3,031;0;0,327 | 6,378 |

Máximo: **7,005 px**, antes 39,493 px. Atende à meta numérica dos seis candidatos desta ficha. Os dois alvos inferiores foram corrigidos de y=476 para y=493 após inspeção do original ampliado: a marca anterior estava acima da base da folha. Em seguida, a pose foi ajustada manualmente; as seis coordenadas 3D compartilhadas com cam03 permanecem idênticas às anteriores. Nenhum alvo foi obtido da projeção ajustada.

Este resultado local **não aprova a vista completa**: os seis pontos concentram-se em porta/escada, faltam referências distribuídas pela estrada e confirmação física entre as vistas. Alvos parcialmente encobertos por corrimão/neve e escala continuam provisórios.

## Cam02 — hipótese anterior da estrada (histórico, substituída)

- Recurso: `resources/env_1/calibration_cam02.tres`.
- Câmera posição (32,369964;17,062349;0,885414), rotação (-55;125;0), FOV vertical 50°, perspectiva.
- Cápsula: base (24;0;5); grade centrada em (24;0;5).

| ID | Alvo candidato | Pixel original (x,y) | Ponto 3D hipotético (x,y,z) | Erro 1080p (px) |
| --- | --- | --- | --- | --- |
| 1 | Guarda-corpo perto esquerda | 360,748 | 28;1,1;8 | 350,190 |
| 2 | Estrada perto direita | 1360,827 | 28;0;2 | 490,330 |
| 3 | Guarda-corpo médio esquerda | 692,484 | 20;1,1;8 | 278,929 |
| 4 | Estrada médio direita | 1365,468 | 20;0;2 | 258,574 |
| 5 | Travessa do portão longe esquerda | 1061,148 | 12;1,1;8 | 14,486 |
| 6 | Travessa do portão longe direita | 1310,251 | 12;1,1;2 | 2,531 |

Máximo atual: **490,330 px**, anteriormente 732,809 px. A correção de altura e pose aproximou o portão, mas piorou algumas referências de chão: o máximo menor não significa melhora em todos os marcos. A hipótese de pontos alinhados em seções de estrada reta/plana não se ajusta às observações; precisa rever correspondências, traçado e alturas. Esse número mede a hipótese, **não demonstra impossibilidade de calibrar a imagem**.

## Cam03 — vista próxima da entrada

- Recurso: `resources/env_1/calibration_cam03.tres`.
- Câmera posição (9,0313;4,5131;10,7497), rotação (-12;36;0), FOV vertical 40°, perspectiva.
- Cápsula: base (2,25;0;2); grade centrada na origem.

| ID | Alvo candidato | Pixel original (x,y) | Ponto 3D hipotético (x,y,z) | Erro 1080p (px) |
| --- | --- | --- | --- | --- |
| 1 | Folha da porta inferior esquerda | 746,514 | 0;1,1;0 | 6,192 |
| 2 | Folha da porta inferior direita | 812,515 | 0,9;1,1;0 | 6,248 |
| 3 | Folha da porta superior direita | 813,328 | 0,9;3,2;0 | 4,400 |
| 4 | Folha da porta superior esquerda | 745,321 | 0;3,2;0 | 1,311 |
| 5 | Base esquerda da escada | 839,663 | 1,469;0;0,673 | 32,265 |
| 6 | Base direita da escada | 975,652 | 3,031;0;0,327 | 20,743 |

Revisão de 11/10/2026 após autorização para usar medidas provisórias: alvos revistos sobre a imagem, passando da linha do painel inferior à folha inteira, e o ponto direito da escada passou do penúltimo ao último degrau. A câmera foi ajustada manualmente mantendo as mesmas seis coordenadas 3D de cam01. O probe agora verifica essa igualdade para impedir geometrias independentes usadas apenas para reduzir erro.

Os quatro pontos da porta estão abaixo de 7 px; isso é ajuste parcial. Máximo dos seis: **32,265 px**, anteriormente 70,852 px. Porta ajustada não valida chão, escada, escala real ou continuidade entre vistas. A identificação dos pontos parcialmente ocultos de cam01 continua pendente; ela não foi silenciosamente alterada para melhorar a métrica.

## Evidências da retomada manual

- Ferramentas em headless e gráfico: saída 0; igualdade da hipótese espacial cam01/cam03, imagens, câmera, cápsula unitária de 1,8 m, grade e barras aprovadas. Regressões gráficas de composição T01 e headless de movimento T05: saída 0.
- Gate `-- --acceptance`: saída 1, três hipóteses ainda acima de 8 px. Logs `.local/t06-manual-{tooling-headless,tooling-graphical,acceptance,composition-regression,movement-regression}.log`.
- Capturas inspecionadas: `.local/t06-manual-cam01.png`, `t06-manual-cam02.png`, `t06-manual-cam03.png` (1920×1080) e `t06-manual-cam03-4x3.png` (1280×960). Porta cam03 e portão cam02 mais próximos dos alvos; escada/estrada seguem desalinhadas. Originais novamente conferidos por SHA-256, sem alteração.
- Análise auxiliar de raios/projeção, recortes locais e candidatos numéricos declarados manualmente serviram para diagnóstico; nenhuma busca automática, otimização ou reconstrução 3D foi aplicada. As medidas físicas continuam hipóteses.

## Estado e barreira

### Retomada com navegação na prévia — 11/10/2026

- Teste gráfico final: seis erros cam01 abaixo de 8 px; cam02/cam03 preservadas em 490,330/32,265 px. Gate retorna 1 com **duas** falhas; ferramentas, seleção de fichas por eventos reais de teclado, repetição/soltura e visibilidade passam.
- Logs `.local/t06-resume-{tooling,graphical,acceptance}.log`. O log `tooling` precede a pose final; números finais estão em `graphical` e `acceptance`. Capturas finais preservadas como `.local/t06-resume-camNN.png` e `.local/t06-resume-cam03-4x3.png`.
- Candidatos de câmeras no mesmo lado da fachada e de escada perpendicular foram examinados, mas não adotados: não resolveram as duas vistas com a mesma geometria. A diferença de lado das poses continua hipótese de investigação, não diagnóstico comprovado de incompatibilidade.
- Os alvos direitos de cam02 caem na região de rocha/neve, sem borda de estrada inequívoca. Antes de novos ajustes de pose, identificar marcos físicos verificáveis; os pares atuais não devem ser tratados como estações transversais confirmadas. Não foram movidos apenas para reduzir o erro.

ENV_1 continua **sem validação da geometria comum**. A retomada mais recente está em `ENV_1_REFINEMENT.md`, com 12 pares em cam02, quatro deles âncoras explicitamente excluídas do aceite. O ensaio local foi reproduzido por outro executor; essa aprovação limitada não aprova a integração das três vistas. T06/T07 usam os estudos técnicos autorais; ENV_1 pode ser examinado na cena de calibração e na faixa local de ensaio, sem substituir o percurso.

Próximo trabalho: revisar alvos/alturas e a geometria proxy da escada/estrada, manter medidas compartilhadas entre vistas, ajustar as poses no Inspector e repetir a medição. As imagens não foram rejeitadas; não há evidência suficiente para exigir novos renders neste momento. Não corrigir erro apenas movendo alvos 2D para onde a hipótese projeta nem criando coordenadas livres para produzir erro zero por construção.
