# Repolhos e cenouras

As plantações antigas foram retiradas da cena e do pacote exportado, incluindo
a horta lateral. Os dois GLBs enviados pelo usuário estão preservados em
`assets/crops/source/`, com `.gdignore`. Os modelos completos não são carregados
pelo jogo. Os arquivos `cabbage_mobile.res` e `carrots_mobile.res` mantêm a
geometria 3D e as texturas dos assets fornecidos, com redução de polígonos.

O campo abaixo da casa tem repolhos à esquerda e cenouras à direita, seguindo
a referência. São 48 repolhos e 20 módulos de cenouras (cada módulo contém várias
cenouras do modelo original). Cada tipo compartilha uma malha por MultiMesh.
Os quatro canteiros deixam um corredor central entre os portões e uma passagem
transversal. A horta lateral fica apenas com terra, pronta para novos cultivos.
As cercas e as passagens existentes permanecem livres.

`data/regions/farm_crops.json` define os canteiros, quantidades e tamanhos.
`data/regions/farm_paths.json` reserva esses canteiros e inclui os corredores
internos. A colisão continua sendo o piso plano da fazenda; as plantas não
introduzem novos degraus ou obstáculos de física.

Geometria de cada módulo: repolho com 9.170 triângulos (original 587.882) e
cenoura com 24.022 (original 769.400). Albedos de 1024 px, normais e rugosidade
de 512 px, com mipmaps e materiais não metálicos.

Regeneração a partir da raiz (Pillow, Godot 4.6.3):

```sh
python tools/extract_crop_textures.py
python tools/bake_farm_paths.py
godot --headless --editor --import --quit
godot --headless --script tools/bake_crop_models.gd
```

Validação local: 156 verificações de integração aprovadas, incluindo limites
geométricos dos módulos, corredores, portões, movimentos, missão e salvamento.
O teste do pacote exportado confirma a presença dos cultivos novos, a ausência
das plantações antigas e dos GLBs pesados e o orçamento de texturas. Estimativa
conservadora das 35 texturas: 165,7 MiB RGBA8 com mipmaps. O pacote Web tem cerca
de 54 MiB. A estabilidade no Safari/iPhone depende de validação no aparelho.
