# Casa principal Cozy Timber Hearth

Fonte enviada pelo usuário: `Meshy_AI_Cozy_Timber_Hearth_1109122408_texture.glb`, preservada sem alterações em `assets/models/cozy_timber_house.glb`. O importador Godot extrai as três texturas adjacentes; mantenha os arquivos de imagem e `.import` versionados.

A antiga construção fazia parte da malha Golden Acres. Sua região é rebaixada na malha derivada `farm_without_fences.res`, removendo a geometria elevada e a colisão antiga. Um pátio com piso e colisão cobre as UVs da fachada/telhado colapsados. Cercas, acessos e demais construções permanecem nos lugares atuais.

`scripts/world/main_house.gd` instancia a nova casa em `(-13.25, 0.025, -0.5)`, com escala uniforme para largura de 24 unidades. A varanda aponta para +Z, alinhada ao caminho e à abertura da cerca frontal. O piso inferior da malha fica apoiado no pátio; a colisão triangular acompanha a nova geometria. A troca não adiciona um sistema de interior ou abertura da porta.

Configuração de colocação: `main_house` em `data/regions/farm_fences.json`. Os limites de remoção correspondentes também estão em `erase_rectangles`, no sistema de coordenadas original da fazenda. Ao reposicionar/remodelar a região, mantenha os limites do pátio e da remoção alinhados.

Regeneração dos recursos derivados, com Godot 4.6.3, a partir da raiz do projeto:

```sh
godot --headless --editor --import --quit
godot --headless --script tools/bake_farm_fences.gd
godot --headless --script tests/integration.gd
```

O processamento compartilhado agora regenera a fazenda, o módulo de cerca e a casa. A casa renderizada usa `cozy_timber_house_mobile.res`, com 56.786 triângulos (fonte: 454.364), mantendo UVs/materiais. Nenhuma simplificação ocorre ao abrir o jogo. Não houve medição de FPS em celular físico.
