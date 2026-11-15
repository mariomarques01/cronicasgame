# Direção do Vale da Fazenda

O mapa de referência enviado pelo usuário passa a orientar as próximas áreas.
A região deve ser um vale contínuo de exploração, com fazenda, vila, água,
colinas, floresta e marcos arquitetônicos ligados por trilhas naturais.

A Trilha dos Ventos foi retirada: plataformas cilíndricas, pedra de impulso,
marco, mirante, anéis de fogo/jade e a pirueta de impulso deixaram de fazer parte
do jogo. O salto de altura variável, a resposta suave do personagem e as
reduções de geometria continuam compondo os controles e a base técnica.

## Correção entregue

1. Uma única conversa com Lia inicia a missão.
2. Cada pedra recolhida atualiza o contador e salva a jornada.
3. A terceira pedra abre a passagem e libera a colisão automaticamente.
4. O objetivo muda para encontrar as Ruínas Antigas na floresta.

Lia não interrompe novamente a exploração nem serve de bloqueio entre objetivos.
O mecanismo intermediário foi retirado. A apresentação e a reunião das pedras são os dois primeiros objetivos; o HUD
agora registra cinco metas com a descoberta das ruínas, a investigação e a
chegada à árvore.

Os saves existentes mantêm pedras, inventário e posição. Os estados antigos
`2` (retorno a Lia) e `3` (mecanismo) migram em memória para `4` (passagem aberta),
com a região da floresta liberada, antes de notificar a interface. Novos saves usam o formato v2;
a leitura de v1 continua compatível. O salvamento automático usa o mesmo caminho e
não substitui as mensagens de progresso por avisos de salvamento.

## Ruínas Antigas implementadas

A região fica a noroeste da floresta, ligada ao portão e ao caminho da Árvore
Ancestral. Inclui pátio caminhável, arcos de alvenaria, paredes quebradas,
escombros, pavimentação antiga e três inscrições. A jornada continua por
proximidade: descoberta das ruínas → investigação das inscrições → chegada à
árvore, com progresso salvo e sem novas conversas com Lia.

A marca azul no minimapa indica o objetivo atual. As memórias decifradas ficam
nos detalhes da missão. A árvore continua sendo o marco visual existente; uma
recriação visual completa da árvore do conceito não faz parte desta etapa.
Veja [ancient-ruins.md](ancient-ruins.md) para implementação e validação.

## Situação das demais áreas do mapa

| Área | Direção para a expansão |
| --- | --- |
| Fazenda / Plantação / Moinho | Núcleo inicial existente; preservar caminhos e organização rural. |
| Vila de Eldervale | Núcleo habitado conectado à fazenda e ao rio; lugar para NPCs e missões secundárias. |
| Rio, pontes e Lago do Vale | Formar uma rede natural de circulação, com margens e travessias coerentes. |
| Cachoeira do Cristal | Marco de paisagem junto à continuidade do rio e às montanhas. |
| Campo de Flores / Colinas do Vale | Áreas de exploração entre fazenda, vila e lago. |
| Ruínas Antigas | Implementadas nesta expansão, com investigação automática. |
| Floresta dos Sussurros / Árvore Ancestral | A investigação já conduz ao marco existente. A recriação visual completa da árvore do conceito fica para uma etapa futura. |

As posições relativas, os caminhos principais/secundários e as pedras antigas
no mapa devem orientar a reorganização futura do mundo. O mapa conceitual não
é exibido como se todas essas áreas já estivessem implementadas. Esta expansão
não constrói vila, lago ou cachoeira.

As próximas etapas devem avançar por objetivos cumpridos e descoberta de áreas,
com progresso persistente. Conversas adicionais com Lia não devem virar
exigência para destravar cada trecho. Cada expansão precisa preservar rotas
caminháveis, colisões e o orçamento de geometria/sombras adotado para celular.
