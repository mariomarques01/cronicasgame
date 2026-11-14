# Geometria e sombras para celular

A revisão anterior reduziu resolução e trabalho de HUD/minimapa, mas ainda
instanciava 4.861.140 triângulos no cenário, incluindo um personagem de 127.420
triângulos, 920.600 nas plantações e 2.530.276 nas árvores. Compartilhar malhas
em MultiMesh reduz chamadas de desenho; não elimina o custo dos triângulos de
cada instância nem das passagens de sombra.

## Alteração

A geometria total agora soma 1.218.804 triângulos (redução de 74,9%), antes de
considerar descarte por visão e distância. Os números por módulo e os resultados
da comparação local estão em [mobile-geometry-budget.json](mobile-geometry-budget.json).

- Árvores externas: 1.400 triângulos; pinheiros: 1.800.
- Repolhos: 1.000; módulos de cenouras: 1.300.
- Cerca: 2.399. Uma tentativa de 650 perdeu detalhe visual e foi descartada.
- Coelho animado: 18.000, mantendo os 32 vínculos do esqueleto original.
- Cercas divididas em células de 16 m para descartar trechos fora da visão,
  preservando as 192 seções, transformações e colisões.
- Árvores externas deixam de projetar sombras e são descartadas além de 90 m;
  os pinheiros internos conservam suas sombras. Plantações não projetam sombras.
- Sol com duas cascatas, alcance de 45 m, atlas de 1.024 e filtro leve.

As texturas originais são reutilizadas. Os limites das malhas estáticas são
preservados para manter altura, largura e encaixe dos módulos. As colisões não
foram simplificadas com a malha visual. O coelho usa a cena, esqueleto e clipes
originais; os índices dos ossos da malha simplificada são remapeados para a skin
original, em vez de trocar a animação por uma reexportação do Blender.

O salto e a aterrissagem são retargetados no processamento offline. O runtime
não carrega mais o FBX inteiro nem retargeta o salto ao entrar na cena. O pacote
também deixa de incluir o GLB de alta densidade do personagem.

## Validação

302 verificações de integração, incluindo limites de geometria, 32 vínculos do
esqueleto, células de cercas, configurações de sombra e os testes de animação,
movimento, colisão, coleta, HUD e salvamento existentes. Teste do pacote verifica
a presença dos clipes de salto e a ausência dos personagens-fonte pesados.

Na comparação OpenGL por software (Mesa llvmpipe), com câmera e configurações
iguais e apenas as malhas trocadas, a mediana passou de 1.361,82 ms para
689,05 ms por quadro; primitivas renderizadas de 2.887.926 para 1.187.908.
Foram 12 amostras por caso, após cinco quadros de aquecimento, em 640 × 360.
Esse resultado serve para comparar o custo da geometria nesse ambiente; não
representa o FPS de celular nem mede todos os cenários de jogo. A aparência foi
conferida por captura do jogo renderizado.

## Reproduzir

São necessários Blender 4.3+, Godot 4.6.3 e os GLBs-fonte já usados pelos scripts
de bake anteriores (incluindo as fontes de cultivos na pasta ignorada).

```sh
blender --background --python tools/decimate_mobile_geometry.py -- /caminho/temporario
godot --headless --script tools/bake_mobile_geometry.gd -- /caminho/temporario
godot --headless --script tools/audit_geometry.gd
```

Use o executável `godot` correspondente ao ambiente (o nome pode variar).
O bake preserva as fontes e gera apenas as malhas/cena compactas distribuídas.
