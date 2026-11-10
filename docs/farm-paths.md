# Caminhos e cercas da fazenda

A circulação usa o mapa de referência: estrada em volta da casa e das
plantações, faixa entre a casa e o campo, acesso lateral à horta e ligações aos
portões do curro, pasto e moinho. A grama Emerald Meadow permanece nas áreas
livres e os canteiros conservam sua geometria e UVs.

`data/regions/farm_paths.json` define trajetos em coordenadas mundiais X/Z e
larguras reais (2 m na ligação estreita entre os canteiros; 3–5 m nos demais
acessos). `tools/bake_farm_paths.py` gera `assets/textures/farm_paths_mask.png`
com Pillow. O mapa de 1024 px tem junções arredondadas e recorta as áreas
cultivadas para não pintar estrada por cima delas. Regenerar após editar o JSON:

```sh
python tools/bake_farm_paths.py
```

O terreno, as fundações, o pátio da casa e a entrada compartilham a mesma máscara
em coordenadas mundiais. Isso remove o anel genérico, os cruzamentos indevidos
e as manchas retangulares de terra que ignoravam as cercas.

As cercas continuam definidas em `data/regions/farm_fences.json`. As posições
ainda usam a escala histórica do modelo (55). Foram removidas divisórias soltas
e trechos que cortavam os acessos; os limites da casa, curro, pasto e moinho
foram reorganizados. Os portões da horta ficam nas pontas, o campo ganhou acesso
sul e a esquina junto à horta foi aberta para a ligação estreita. A saída norte
contorna o celeiro e passa por uma abertura na cerca antes do portão da missão.
Lia fica ao lado da passagem oeste, sem bloquear a estrada.

Validação local em Godot 4.6.3: 144 verificações de integração sem falhas,
exportação Web e smoke test do pacote sem falhas. Para cada trajeto, o teste
consulta a física com a cápsula do jogador no centro e nas duas bordas, a cada
metro. O portão da missão é excluído dessa checagem porque seu bloqueio faz
parte da progressão. O teste também confirma que a máscara não invade as
plantações. A auditoria do pacote mantém o orçamento de texturas de 192 MiB.
