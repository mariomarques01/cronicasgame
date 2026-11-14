# Efeitos e transições de movimento

Segunda etapa baseada na análise estática do SuperMak64 fornecido pelo usuário,
com o REA 6.9.0. A nova extração seletiva de `scripts/fx/juice_vfx.json` foi
verificada com integridade `fail`; hashes e identidade em
[effects-rea-evidence.json](effects-rea-evidence.json). O código anteriormente
extraído `juice.gd` e `mak_player.gd` complementa a referência.

| Referência | Adaptação própria para Eldervale |
| --- | --- |
| `juice_vfx.json`, `player_jump_1` | Rajada pequena no evento real de salto |
| `player_footstep`; `mak_player.gd:on_footstep`, redução de poeira para deixar as pernas visíveis | Poeira mínima apenas em corrida, a cada 1,8 m efetivamente percorridos; sem emissão parado, andando devagar ou no ar |
| `player_skid`, cooldown de evento | Rajada curta ao frear/reverter uma corrida, com intervalo mínimo de 0,28 s |
| `player_land`, intensidade pela velocidade de contato | Tamanho e velocidade da poeira proporcionais ao impacto; impulso vertical de câmera limitado a 7,5 cm e 0,18 s para contatos acima de 7 m/s |
| `juice.gd`, pool e orçamento de efeitos | Oito emissores reutilizáveis, no máximo 12 partículas por emissor, sem criar nós ou texturas em eventos |
| Eventos semânticos separados do efeito | Salto, frenagem e pouso sinalizados pelo controlador; brilho ciano aditivo apenas após coleta aceita |

A transição correr/andar → repouso agora mistura por 0,18 s para um clipe estático
local, em vez de buscar e congelar abruptamente o primeiro quadro de Walking.
Walking/Running preservam suas transições e ritmo proporcional à velocidade real,
com suavização exponencial da cadência para evitar mudanças bruscas de ritmo.
O clipe de repouso é gerado do modelo existente; nenhuma nova animação foi copiada.

Os efeitos usam gradiente e material originais, sem luzes adicionais, sombras,
flashes de tela ou alterações globais na velocidade do jogo. Os emissores param
com os menus. A câmera recebe apenas um deslocamento vertical transitório, sem
alterar mira, órbita ou colisão. A coleta não dispara novamente em tentativa
inválida ou repetida. Não há combate, dano ou hitstop nesta etapa.

A corrida usa distância percorrida como aproximação da cadência, não eventos de
contato exatos dos pés. As superfícies ainda compartilham poeira neutra; efeitos
de água e identificação de materiais do SuperMak não foram adaptados.

Validação: 282 verificações aprovadas, zero falhas. Testes do controlador real cobrem decolagem, corrida, frenagem,
repouso sem emissão, pool fixo sob rajadas repetidas, brilho de coleta, pausa e
retorno da câmera ao offset original. Somam-se às verificações existentes de
colisão, salto, diálogo, HUD, salvamento e exportação. Desempenho em aparelho
físico ainda depende da avaliação no celular do usuário.
