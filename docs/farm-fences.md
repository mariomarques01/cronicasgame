# Cercas Mossy Garden

O arquivo fornecido pelo usuário, `Meshy_AI_Mossy_Garden_Fence_1109123432_texture.glb`, está preservado sem alterações em `assets/models/mossy_fence.glb`, com as texturas extraídas pelo importador Godot.

A cerca original estava fundida à malha Golden Acres. Sobrepor um modelo não removeria sua aparência nem suas colisões. `farm_without_fences.res` deriva da fazenda original, rebaixando os trechos de cerca e removendo triângulos degenerados. As bordas verticais exageradas dos canteiros são rebaixadas junto aos canteiros, preservando as texturas. O GLB original da fazenda também permanece intacto.

`data/regions/farm_fences.json` descreve os traçados no plano X/Z original do GLB (antes da escala 55 e do deslocamento Y=9,8). Os intervalos `gaps` são frações do comprimento total do traçado e reservam passagens. As faixas de remoção incluem as cercas dos canteiros, horta, currais, frente da casa e perímetro. As entradas norte e sul permanecem abertas; o portão da missão é independente.

Para regenerar os dois recursos derivados, após importar o projeto com Godot 4.6.3:

```sh
godot --headless --script tools/bake_farm_fences.gd
godot --headless --script tests/integration.gd
```

O processamento usa `ImporterMesh.generate_lods()` para derivar um módulo de 4.394 triângulos (original: 140.766), removendo vértices não utilizados e preservando UVs/materiais. Os recursos comprimidos são versionados: não há processamento da malha original a cada início do jogo.

`farm_fences.gd` instancia 192 seções em um MultiMesh, com altura de 1,35 unidade, rotação seguindo cada trecho e colisões de caixa independentes. As aberturas deixam espaço para o personagem circular. Um piso com colisão cobre o buraco deixado pelo arco deformado na entrada sul, ligando-o ao caminho externo. O início/retorno após quedas foi afastado da linha da cerca.

Os testes incluem colisões das cercas, acesso às plantações, entradas norte/sul e travessia real da entrada sul caminhando. Foram conferidos enquadramentos em terceira pessoa e uma vista aérea do mapa. Não foi medido FPS no iPhone ou em outro aparelho físico.

Capturas: [horta e cercados](screenshots/fences-garden.png), [distribuição no mapa](screenshots/fences-map.png).
