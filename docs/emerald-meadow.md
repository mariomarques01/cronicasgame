# Chão Emerald Meadow

Atualização: as plantas antigas mencionadas abaixo foram substituídas pelos
assets de repolho e cenoura; veja `docs/cabbage-and-carrots.md`. O chão plano e
a grama Emerald Meadow continuam em uso.

O ZIP enviado pelo usuário foi extraído para
`assets/grass/source/emerald_meadow.glb`. Essa pasta usa `.gdignore`: o GLB
original de 26,99 MB e 534.354 triângulos é uma fonte de edição, não um recurso
de inicialização ou exportação. O ZIP redundante foi removido do repositório.

`assets/grass/emerald_meadow_albedo.png` contém uma projeção superior da região
central do modelo e de sua textura original, com continuidade nas bordas por
espelhamento. Não é uma grama genérica substituta. A resolução é 1024 px, com
mipmaps. O jogo usa essa textura em uma superfície plana, sem replicar centenas
de milhares de faces para cada pedaço de chão.

A superfície da fazenda mede 108 × 104 unidades e sua colisão é plana em Y=0,01.
O terreno de apoio permanece abaixo dela, inclusive nos cantos. Os caminhos,
construções, árvores, cercas e as pedras interativas da missão são preservados.
As pedras e flores decorativas da antiga base fundida foram removidas junto
com aquela base. Remendos antigos nas raízes das árvores também foram retirados.

As duas áreas cultivadas (`crops` e `vegetable_garden`) foram separadas para
`assets/models/farm_crops.res`. Seus 26.629 triângulos mantêm as posições e UVs
originais, verificados por SHA-256. Elas não recriam a colisão irregular antiga.
As bordas/terra dos canteiros continuam visíveis; as plantações não foram
achatadas. Os pisos existentes nas construções continuam com suas colisões.

Para regenerar os recursos, a partir da raiz:

```sh
python tools/bake_meadow_texture.py  # Python, numpy, Pillow e g++ com C++17
godot --headless --editor --import --quit
godot --headless --script tools/bake_meadow_farm.gd
```

Validação: testes de integração verificam as plantações, a colisão plana, os
acessos e a missão. O smoke test executa o pacote de fora do projeto e verifica
que o modelo fonte e a antiga base não estão exportados. A auditoria de texturas
inclui os samplers dos shaders do terreno, além dos materiais dos modelos.
