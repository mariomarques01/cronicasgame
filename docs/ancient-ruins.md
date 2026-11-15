# Ruínas Antigas

Região construída a partir da direção do mapa fornecido pelo usuário: um núcleo
de alvenaria antiga a noroeste da floresta, conectado ao portão e à Árvore
Ancestral por trilhas de terra. O núcleo ocupa X −40 a −12 e Z −96 a −68.

## Cenário

Os módulos de arco inteiro, arco quebrado, parede e escombros foram modelados
localmente no Blender, com bordas gastas, variação de cor e pequenos trechos de
musgo. A pedra calcária usa material original de 512 px e normal map. As malhas
compactas têm, respectivamente, 1.456, 1.216, 1.392 e 760 triângulos. Não há
serviço externo de geração nem assets de terceiros novos nesta expansão.

O terreno recebe um patamar integrado, com transição de seis metros para as
colinas. Uma máscara separada pinta as novas trilhas sem alterar a máscara dos
caminhos da fazenda. Vegetação e colisões de troncos são excluídas das trilhas e
da clareira, preservando a Árvore Ancestral e as demais árvores da seed original.
As passagens dos arcos ficam livres; paredes e pilares usam formas de colisão
simples, e os pequenos escombros reutilizam um trimesh compartilhado.

A região contém **10.852 triângulos instanciados**; o cenário inteiro soma
**1.225.444**, dentro do limite de 1,3 milhão. Não foram adicionadas luzes
dinâmicas. O minimapa mantém sua captura única; uma marca 2D azul acompanha o
objetivo, sem renderizar o mundo novamente a cada atualização.

## Objetivos e salvamento

A conversa inicial com Lia e as três pedras permanecem como início da jornada.
A terceira pedra abre a floresta. A seguir:

1. Seguir a trilha e entrar no pátio inicia a investigação automaticamente.
2. Aproximar-se de cada inscrição e reduzir/parar o movimento por 0,8 s revela
   uma memória. Menus suspendem esse tempo; repetir uma inscrição não conta de novo.
3. A terceira inscrição indica o caminho da Árvore Ancestral no minimapa.
4. Chegar à árvore conclui a sequência. O vale continua aberto para exploração.

Cada avanço salva o progresso sem abrir diálogo obrigatório. Os textos lidos
ficam nos detalhes da missão, acessíveis pela faixa do HUD. O HUD tem cinco
objetivos de jornada, e o nome da missão muda para “As Memórias das Ruínas”.

O formato de save passa a v2, incluindo os IDs únicos das inscrições e validando
sua coerência com as etapas. O nome `eldervale_v1.json` é mantido para encontrar
os saves antigos. A carga lê v1, migra as etapas antigas de retorno a Lia ou
mecanismo para passagem aberta e mantém posição, inventário e pedras. Saves
inválidos não alteram o estado atual nem são sobrescritos durante a validação.

## Validação

369 verificações de integração aprovadas. O controlador real percorreu do portão
às ruínas, entre as inscrições e até a árvore, sem teletransportes entre pontos
da rota. Centro e bordas dos cinco caminhos foram consultados com a cápsula real,
sem colisões obstruindo a passagem. Os testes cobrem pausa da leitura, progresso
único, diário, retomada no meio da investigação, conclusão, migração v1, rejeição
de saves v2 incoerentes, orçamento de geometria e notificações de altura compacta.

O pacote exportado é testado com descoberta, inscrições e chegada à árvore. A
arquitetura e o HUD foram conferidos em renderização nativa. Desempenho em um
telefone físico continua dependendo da avaliação no aparelho do usuário.

## Reproduzir os assets

```sh
python tools/bake_ruins_stone.py
python tools/bake_ruins_paths.py
blender --background --python tools/build_ruins_assets.py -- /caminho/temporario
godot --headless --editor --import --quit
godot --headless --script tools/bake_ruins_assets.gd -- /caminho/temporario
```

O projeto já inclui as malhas e texturas prontas; esses comandos são ferramentas
de autoria, não executados ao iniciar o jogo. As fontes de geometria e dos materiais estão nos scripts de autoria.
