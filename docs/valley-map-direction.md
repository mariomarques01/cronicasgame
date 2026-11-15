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
4. O objetivo muda para explorar a Floresta dos Sussurros.

Lia não interrompe novamente a exploração nem serve de bloqueio entre objetivos.
O mecanismo intermediário foi retirado. O HUD registra os dois objetivos da
missão de abertura: apresentação e reunião das pedras. A exploração da floresta
é a continuidade disponível depois da missão.

Os saves existentes mantêm pedras, inventário e posição. Os estados antigos
`2` (retorno a Lia) e `3` (mecanismo) migram em memória para `4` (passagem aberta),
com a região da floresta liberada, antes de notificar a interface. O formato de
save v1 permanece compatível. O salvamento automático usa o mesmo caminho e
não substitui as mensagens de progresso por avisos de salvamento.

## Próxima região definida

**Ruínas Antigas**, conectada à floresta e ao caminho da Árvore Ancestral.
A composição seguirá terreno caminhável, caminhos de pedra, arcos quebrados e
vestígios de construções antigas. Sua construção é a próxima expansão; não faz
parte da correção de missão e retirada das plataformas.

## Próximas áreas do mapa — referência, ainda não construídas

| Área | Direção para a expansão |
| --- | --- |
| Fazenda / Plantação / Moinho | Núcleo inicial existente; preservar caminhos e organização rural. |
| Vila de Eldervale | Núcleo habitado conectado à fazenda e ao rio; lugar para NPCs e missões secundárias. |
| Rio, pontes e Lago do Vale | Formar uma rede natural de circulação, com margens e travessias coerentes. |
| Cachoeira do Cristal | Marco de paisagem junto à continuidade do rio e às montanhas. |
| Campo de Flores / Colinas do Vale | Áreas de exploração entre fazenda, vila e lago. |
| Ruínas Antigas | Marco arquitetônico para uma próxima etapa da missão principal. |
| Floresta dos Sussurros / Árvore Ancestral | Floresta densa e marco principal; o bloqueio da árvore receberá objetivos próprios quando esse trecho for construído. |

As posições relativas, os caminhos principais/secundários e as pedras antigas
no mapa devem orientar a reorganização futura do mundo. O mapa conceitual não
é exibido como se todas essas áreas já estivessem implementadas. Esta correção
não constrói vila, lago, cachoeira ou novas ruínas.

As próximas etapas devem avançar por objetivos cumpridos e descoberta de áreas,
com progresso persistente. Conversas adicionais com Lia não devem virar
exigência para destravar cada trecho. Cada expansão precisa preservar rotas
caminháveis, colisões e o orçamento de geometria/sombras adotado para celular.
