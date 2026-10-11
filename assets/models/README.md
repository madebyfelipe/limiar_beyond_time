# Modelos 3D

Salve os modelos de trabalho neste diretório. Prefira `.glb` para importação no Godot e mantenha arquivos-fonte em subdiretórios separados.

Para cada asset, registre origem, licença, unidade/escala, orientação, animações e status de aprovação. Um arquivo presente nesta pasta não é automaticamente aprovado para uso canônico ou distribuição.

## Arquivo encontrado antes da T00

- Caminho: `keleken/model_base.glb` (grafia original preservada).
- Tamanho: 1.160.188 bytes.
- SHA-256: `1748ED72AFC6B5E1F85C2DF601AFA2A0D5C1790418F0BD3C0655B65B53EE8376`.
- Origem/licença/escala/rig/aprovação: não informados.
- Uso na T00: nenhum; não instanciado na cena e não selecionado para exportação.

## Arquivo observado durante a T00

- Caminho: `dylan_protagonist/model-rigged.glb`.
- Tamanho: 1.013.148 bytes.
- SHA-256: `AEDBDF9C15EF225481FFA4630963C7F636702A071EB5CA5CC077B72CBE2816B1`.
- Origem/licença/escala/rig/aprovação: não verificados; o nome do arquivo não comprova a qualidade do rig.
- Uso na T00: nenhum; preservado, sem instância na cena ou inclusão na exportação.

O Godot criou metadados `.import` e texturas extraídas durante a importação. Esses arquivos auxiliares não representam edição dos GLBs originais.

## Integração Dylan — 11/10/2026

- Instalado nos ensaios ENV_1 por solicitação do usuário: `actors/player/player_dylan.tscn` e `dylan_visual.gd`. Cena técnica T07 mantém seu ator de prova.
- Esqueleto importado: 26 ossos; textura/material presentes. GLB não contém animações. Pose neutra dos braços aplicada na instância, sem alteração do arquivo.
- Fonte tem altura 0,99608624 e frente +X. Adaptador gira +90° em Y e aplica escala uniforme 2,4/0,99608624. Altura inicial 1,8 foi aumentada 33% após ajuste pedido pelo usuário. Colisão herdada recebe altura 2,4 e centro 1,2; CharacterBody permanece unitário.
- Pés e cabeça conferidos visualmente; medição da malha deformada da primeira instalação confirmou base y≈0 e altura 1,8. Ampliação mantém a mesma origem. Animações de caminhada/corrida permanecem pendentes; o modelo se desloca com pose fixa.
- SHA-256 do GLB conferido e igual ao inventário. Não exportado nesta integração.

## Animação e guarita — 11/10/2026

- O GLB continua sem clipes embutidos e seu hash permanece idêntico. `dylan_visual.gd` agora cria clipes originais idle/walk/run/door_interact no AnimationPlayer, com blends e velocidade conforme o movimento físico. A informação anterior sobre pose fixa é histórica.
- Modelo instalado no exterior e na sala, com altura visual/colisão de 1,8 m para a geometria autorada. Os ensaios originais mantêm a ampliação de 2,4 m. Não foi alterada a escala do asset-fonte.
- Animações são procedurais de protótipo: sem captura de movimento, IK de pés ou mão presa à maçaneta. Detalhes/testes em `docs/DYLAN_ANIMATION.md`.
