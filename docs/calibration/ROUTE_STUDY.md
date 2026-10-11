# Estudos do percurso — ficha reproduzível T06

11/10/2026. O usuário autorizou usar fundos de estudo consistentes e preservar ENV_1 para refinamento. Estes estudos autorais substituem ENV_1 **somente na validação técnica e no percurso T07**. Não representam arte final nem aprovação dos renders originais.

## Fonte e escala

- `environments/route_study_source.tscn`: fonte explícita dos três fundos, com malhas primitivas e medidas em metros. Sem reconstrução de imagens por IA.
- Uma unidade = 1 metro; cápsula de referência 1,8 m, raio 0,3 m, escala unitária.
- Área A: X -6…6, Z -1…11, chão Y=0. Área B: X -6…6, Z -25…-13, chão Y=1,2. Corredor com largura 3 m. Rampa Z -6…-10, sobe 1,2 m em 4 m (16,70°).
- Caixote A: 2,2 × 2,7 × 2,2 m, centro (0;1,35;5). Estante B: X -5,3…3, Z -18,6…-17,4. Barreira direita: X 4,6…6; passagem entre elas = 1,6 m.
- `tools/author_route_study.gd` registra a autoria das primitivas e as poses escolhidas manualmente; renderiza a fonte. Não busca câmeras, não altera a escala do ator e não reconstrói imagens. `tools/finalize_route_study.gd` associa os PNGs após sua importação.

## Enquadramentos

Todos os PNGs são 1920×1080, perspectiva, FOV vertical 49°. Origem de pixels no canto superior esquerdo. Sem recorte ou deformação. Os recursos contêm a precisão completa, oito pares pixel/mundo, nomes, imagem, escala e posição da cápsula.

| Vista / recurso | Posição da câmera | Rotação XYZ (graus, aproximada) | Maior erro medido em 1080p |
| --- | --- | --- | --- |
| `resources/route_study/shot_1.tres` | 11;16;22 | -37,179325;31,429565;0 | 0,773 px |
| `resources/route_study/shot_2.tres` | 10;13;3 | -41,95552;46,4688;0 | 0,987 px |
| `resources/route_study/shot_3.tres` | -12;17;-5 | -40,59246;-40,60129;0 | 0,584 px |

As referências são pequenos marcos coloridos nomeados `SurveyMark00`…`SurveyMark23` na fonte. Cada vista usa oito: ambas as laterais, pontos próximos/distantes e dois pontos intermediários. A altura da superfície dos marcos é 0,025 m acima do chão. Na vista 2, quatro estão no piso baixo e quatro no piso elevado. Eles são parte visível do estudo técnico.

Os pixels foram medidos no PNG pela cor e centroide da região visível, arredondados ao pixel. A medição não usa `Camera3D.unproject_position`; a comparação posterior usa essa projeção na cena de calibração. Geometria e câmera são conhecidas por autoria, portanto este teste valida reprodução/composição de um estudo de perspectiva conhecida; **não prova que os renders ENV_1 foram calibrados**. Os marcos inicialmente encobertos por caixote/estante foram reposicionados na fonte e os PNGs renderizados novamente antes da medição final.

## Reproduzir sem gerar novamente

```powershell
$GodotExe = 'E:\LIMIAR\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
& $GodotExe --version
& $GodotExe --path E:\LIMIAR --scene res://environments/calibration_route_study.tscn
& $GodotExe --path E:\LIMIAR --fixed-fps 60 --script res://tests/check_calibration.gd -- --study --acceptance
```

Na prévia, 1/2/3 selecionam as vistas, G mostra a grade e M alterna os marcos. No editor, selecionar a raiz, abrir `Definition` no Inspector e conferir os números com o respectivo `.tres`; a câmera aplica esses parâmetros. F6 executa a cena aberta. A cápsula permanece com 1,8 m em todas as vistas.

O gate testa seleção real por eventos de teclado, background/câmera, dimensões, escala, grade, visibilidade e barras em 4:3. Deve retornar 0, com oito correspondências por vista e máximo menor que 8 px. Capturas: `user://t06-study-cam01.png`, `cam02.png`, `cam03.png` e `cam03-4x3.png` com o mesmo prefixo. Log do primeiro aceite: `.local/route-calibration.log`.

Para regenerar os estudos (substitui somente arquivos autorais de estudo), executar nesta ordem: `--script res://tools/author_route_study.gd` em modo gráfico; `--headless --editor --import --quit`; `--headless --script res://tools/finalize_route_study.gd`. Repetir o aceite e a inspeção visual após qualquer mudança. Os renders ENV_1 e suas fichas não são entradas nem saídas desse processo.

## Revisão

Medição e revisão independente aprovadas em 11/10/2026 pelo executor `review_t06`. Reproduziu o gate gráfico (saída 0), inspecionou as três capturas 1080p e 4:3, conferiu os 24 marcos contra a fonte e confirmou câmera/escala. Editor headless carregou cena e recursos sem erros. Logs `.local/t06-independent.log` e `.local/t06-independent-editor.log`. Não foi realizada edição manual pelo Inspector. A grade da vista 2 é plano diagnóstico em Y=0,6; os marcos, não a grade, representam as duas alturas e a rampa. Este aceite libera T07 para os estudos autorais e não aprova ENV_1.
