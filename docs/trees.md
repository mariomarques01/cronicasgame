# Árvores dentro e fora da fazenda

Fontes originais preservadas sem alterações:

- `pinheiro 3d model.glb` → `assets/models/farm_pine.glb`.
- `arvore 3d model.glb` → `assets/models/forest_tree.glb`.

`scripts/world/trees.gd` usa o polígono formado pelos trechos `outer_west` e `outer_east` do cercado. A classificação considera o ponto de implantação do tronco, e não uma caixa retangular ou a extensão da copa. Há **4 pinheiros internos e 313 árvores externas**, incluindo a substituição do marco ancestral por uma versão maior do mesmo modelo exterior.

Foram substituídas as três árvores fundidas à malha Golden Acres e as árvores procedurais externas. Um dos antigos exemplares procedurais ficava dentro do contorno real do cercado e também usa pinheiro. Os recortes da malha se restringem aos volumes das árvores, incluindo o tronco inclinado do sudoeste; a vegetação baixa restante não é rebaixada nem remodelada. Pisos de raiz fecham o terreno sob os recortes, sem mover as plantas.

`data/regions/farm_trees.json` registra volumes e posições das árvores e referências da vegetação anterior, inicialmente extraídas do estado `1fde463`. As assinaturas SHA-256 cobrem posições dos triângulos e UVs das plantas conservadas em canteiros, horta, arbustos a noroeste, vegetação baixa a sudoeste e plantas do pasto. O tronco inclinado atravessava a região sudoeste: a assinatura de retenção exclui os volumes identificados como árvore. Após a substituição dos demais prédios, a comparação usa o estado `5757e28`, excluindo também suas áreas de construção (a amostra noroeste continha uma faixa do telhado antigo do celeiro). As assinaturas anteriores e as originais sem exclusões continuam registradas. O processamento falha antes de salvar a fazenda caso as plantas conservadas mudem.

Regenerar os recursos com Godot 4.6.3, na raiz do projeto:

```sh
godot --headless --editor --import --quit
godot --headless --script tools/bake_farm_fences.gd
godot --headless --script tests/integration.gd
```

As fontes têm cerca de 503 mil triângulos cada. As malhas compartilhadas têm 15.716 triângulos cada, com limite de erro de simplificação relativo à altura. A floresta é agrupada em setores de 32 unidades, com alcance de exibição de 125 unidades; isso permite descartar setores fora da vista. Colisões ficam nos troncos, permitindo passar sob a copa. Os recursos são preparados previamente, sem simplificação durante o jogo.

Foram inspecionados os pinheiros no pátio e sudoeste, as árvores externas e a vista aérea. Não houve medição de FPS em aparelho físico.

Capturas: [dentro da fazenda](screenshots/trees-inside.png), [fora do cercado](screenshots/trees-outside.png) e [vista aérea](screenshots/trees-map.png).
