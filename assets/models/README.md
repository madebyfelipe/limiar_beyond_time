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

## Captura de movimento Mixamo — 11/10/2026

Substituição das animações procedurais por captura de movimento. O GLB-fonte **não** foi editado: seu SHA-256 segue `AEDBDF9C15EF225481FFA4630963C7F636702A071EB5CA5CC077B72CBE2816B1`. Ele deixou de ser instanciado em `player_dylan.tscn`, mas permanece como origem da malha e do inventário.

Caminho da conversão, sem Blender: `tools/glb_to_obj.py` leu o GLB, aplicou a transformação do nó de malha, girou -90° em Y para a frente apontar +Z, apoiou os pés em y=0 e centralizou em X/Z, gravando OBJ+MTL+JPEG. Esse pacote foi enviado ao auto-rigger do Mixamo (marcadores em queixo, pulsos, cotovelos, joelhos e virilha; *Standard Skeleton (65)*, simetria ligada). O rig devolvido tem 65 ossos `mixamorig_*` e substitui o esqueleto Tripo de 26 ossos.

| Arquivo | Clipe Mixamo | Bytes | SHA-256 |
| --- | --- | --- | --- |
| `dylan_protagonist/mixamo/dylan_rig_idle.fbx` | Breathing Idle, *With Skin* | 2.202.240 | `03648D4543F95596938620EB9F6060C6EA5E6FA327F1048F411283C0DBC5F542` |
| `dylan_protagonist/mixamo/walk.fbx` | Standard Walk, *In Place* | 391.808 | `A44E34D1273C0123F35C19A8EC9C3F1A78DD91B2C6B90DC8DFC06E9D0AB95A15` |
| `dylan_protagonist/mixamo/run.fbx` | Slow Run, *In Place* | 345.184 | `B225C571305BEFB251EFCB17E7B1316235FD282907FB986859198DE73A3A75A7` |
| `dylan_protagonist/mixamo/door_open.fbx` | Opening Door Inwards | 832.256 | `1F3BE20572731448109048A8F62B06A5729CC65FC932E8C5789555CE3E9CFD81` |
| `dylan_protagonist/mixamo/walk_back.fbx` | Walking Backwards (*Male Walk Backwards*), *In Place* | 383.520 | `CDA4C5D047A98EE6A4038D6FE51B1DF8BF69E85885F17E313CA73C8D755F328C` |
| `dylan_protagonist/mixamo/turn_a.fbx` | Turning (*Turning In Place*), ângulo 50 | 588.720 | `62FADCBEAF85276EC8483C118A2F3176FA845DC1B39ABA8536D61578E2FFABA3` |
| `dylan_protagonist/mixamo/turn_b.fbx` | o mesmo com *Mirror*, para o outro lado | 588.720 | `14CC1EC3A3A79965FBE8EC7E8B735F71EA995307E765A4A559426420C4A14595` |
| `dylan_protagonist/mixamo/dylan_clips.res` | derivado, ver abaixo | 633.426 | `99729C06E8843A1682C7EB696D39ED69B477D333413DAB1EBEF2019D101AA491` |

- As três últimas capturas foram baixadas na mesma data, depois do primeiro lote, para cobrir a marcha à ré e o giro no lugar dos controles de tanque. `turn_a`/`turn_b` são a mesma captura, a segunda com *Mirror* — arquivos de tamanho igual e hashes diferentes, conferidos.
- Origem: Mixamo (Adobe), baixados com a conta do usuário em 11/10/2026, FBX Binary, 30 fps, sem redução de quadros. Só o primeiro veio *With Skin*; ele carrega malha, esqueleto e a textura, que o Godot extraiu como `dylan_rig_idle_0.png`.
- Licença: os termos do Mixamo permitem uso dos personagens e animações em projetos, inclusive comerciais, e proíbem redistribuir os clipes como asset isolado. **Confirme os termos vigentes antes de publicar a build** — esta nota registra o entendimento na data, não um parecer jurídico.
- Unidade/escala: o FBX sai em centímetros. Os quatro `.import` usam `nodes/root_scale=100.0`, o que devolve o personagem com 0,996 de altura em T-pose e 0,976 em pé no idle.
- Orientação: a captura olha para +Z; `dylan_visual.gd` gira 180° em Y, porque a frente de gameplay é -Z.
- `dylan_clips.res` é gerado por `tools/build_dylan_animations.gd` a partir dos quatro FBX e é o único consumido em execução. Regerar após trocar qualquer captura.
- Aprovação: validado pelas 29 regressões da suíte e por inspeção das capturas em `.local`. `keleken/model_base.glb` segue sem uso.
