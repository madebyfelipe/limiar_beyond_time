# Modelos 3D

Salve os modelos de trabalho neste diretório. Prefira `.glb` para importação no Godot e mantenha arquivos-fonte em subdiretórios separados.

Para cada asset, registre origem, licença, unidade/escala, orientação, animações e status de aprovação. Um arquivo presente nesta pasta não é automaticamente aprovado para uso canônico ou distribuição.

## Pistola original — 12/10/2026

- `weapons/pistol/pistol_lowpoly.glb`: geometria autorada por código no Blender, sem malhas de terceiros; 756 triângulos, uma malha e seis materiais. Referência visual gerada com imagegen integrada, sem uso dela como textura.
- Fonte editável `weapons/pistol/source/pistol.blend` e gerador `tools/build_pistol.py`. Metros, frente −Z, cima +Y, origem na empunhadura; nó `Muzzle` para o traçador. Sem rig ou animação.
- Substitui a caixa provisória no Dylan dos cenários/estande. Testes headless e gráficos de combate passaram; prévias inspecionadas. Protótipo original, sem aprovação canônica implícita. Detalhes em `weapons/pistol/README.md`.

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

## Inspeção Keleken — 12/10/2026

- Inspecionado `keleken/model_base.glb` sem edição: hash permanece `1748ED72AFC6B5E1F85C2DF601AFA2A0D5C1790418F0BD3C0655B65B53EE8376`.
- GLB declara gerador `https://tripo3d.ai`; origem da conta, licença e aprovação continuam não verificadas.
- Uma malha/material, 4.425 vértices exportados e 3.030 triângulos, UV e JPEG embutido. Não há skin, pesos, ossos nem clipes; confirmado também pela importação no Godot.
- Caixa importada: X 1,253988 × Y 1,200000 × Z 0,542331; base Y −0,619632; frente +X conferida visualmente. Esses valores não definem a escala física canônica.
- A pesquisa original não implementou rig. Na solicitação seguinte foi criada a cópia animada e integrada uma instância de estudo no exterior, conforme abaixo.

## Rig e animação Keleken — 12/10/2026

- Derivado `keleken/keleken_animated.glb`, fonte editável `keleken/source/keleken_rig.blend` e gerador `tools/rig_keleken.py`. O GLB original permanece intacto.
- Rig customizado na API do Blender, 24 ossos de deformação, pesos de até quatro influências, textura original e sete clipes baked a 30 fps: idle, walk, run, look, alert, attack_beak e recover.
- Os clipes são autorados por código, sem biblioteca externa ou mocap. Revisão após feedback: olhares rápidos, inclinações da cabeça, movimento do pescoço e passada mais curta/baixa. Procedência da malha e licença continuam não verificadas.
- Escala de estudo 2,4 m, base Y≈0, frente −Z. Instância no exterior com wander limitado à estrada; sem IA de ataque. Cena isolada em `executar-keleken.cmd`.
- Fonte Blender fica sob `.gdignore`. Detalhes, medidas, comandos, limites e evidências em `docs/KELEKEN_ANIMATION.md` e `docs/evidence/keleken`.

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

## Transições, reações e mira Mixamo — 13/10/2026

- Treze capturas novas em `dylan_protagonist/mixamo/`: dash para trás, parada de corrida, reação a tiro (desarmado e com pistola), morte, idle olhando em volta, cinco ciclos de pistola, susto e digitação. Exportadas com root motion; `.import` com `root_scale=100`, como as demais. Capturas, janelas e hashes em `docs/DYLAN_TRANSITIONS.md`.
- O catálogo inteiro do Mixamo sobre o rig `dylan_mixamo` fica fora do Git, em `E:\LIMIAR\.local\mixamo_library\`.

## Esquivas Mixamo — 12/10/2026

- Exportadas da conta do usuário sobre o rig `dylan_mixamo`, FBX Binary, 30 fps, sem skin: `dylan_protagonist/mixamo/roll_stand.fbx` (Stand To Roll → `dodge_forward`), `dodge_back.fbx` (Dodging Back → `dodge_back`) e `dodge_right.fbx` (Dodging Right → `dodge_right`, espelhado em `dodge_left`). O `dodge_right.fbx` anterior, vindo de um espelho público no GitHub, foi substituído.
- `.import` com `root_scale=100`, como as demais capturas; não há mais retarget. `dylan_clips.res` regenerado (806.946 bytes, SHA-256 `980B331FF2F14C00D9B50C9BB59D98ED7A38E1259B74651B56187A3677E5730B`). Hashes, janelas e capturas descartadas em `docs/DODGE_AND_GAMEPAD.md`.

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
