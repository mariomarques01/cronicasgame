# Trilha dos Ventos: exploração, movimento e magia

Esta etapa estuda o SuperMak64 fornecido pelo usuário com REA 6.9.0 e adapta as
ideias ao coelho e ao cenário de Eldervale. A extração seletiva verificou
`bounce_pad.gd`, `checkpoint.gd` e `mak_animator.gd`; identidades e hashes estão
em [exploration-rea-evidence.json](exploration-rea-evidence.json). A referência foi
analisada estaticamente, sem executar o SuperMak64 original.

| Referência | Aplicação própria |
| --- | --- |
| `movement_profile.gd`, jump cut (linhas 105–110) | Soltar Espaço/Pular durante a subida limita a velocidade a 4,8 m/s uma única vez; manter pressionado conserva o salto de 8 m/s. Buffer e tolerância de borda existentes permanecem. |
| `bounce_pad.gd`, superfície com impulso vertical e reação visual | Pedra de impulso com lançamento de 12 m/s, feedback curto e controle aéreo existente; o corte de salto não reduz esse impulso. |
| `checkpoint.gd`, ativação e escolha de retorno com piso/espaço livre | Marco na entrada da floresta verifica altura, normal do piso e espaço para a cápsula antes de atualizar o ponto de retorno. |
| `mak_animator.gd`, mistura, inclinação e resposta de ações | Inclinações visuais suaves em curvas/aceleração e pirueta visual de 0,65 s no impulso mágico; orientação física e câmera continuam independentes. |

## Jogabilidade

A Trilha dos Ventos aparece depois do desbloqueio da floresta pela missão
existente. Marcas douradas orientam uma rota opcional, com uma pedra de impulso,
três plataformas de ruína e um mirante. A primeira plataforma é alcançada pelo
impulso; as seguintes usam saltos normais. O caminho central até a Árvore
Ancestral permanece livre. Lia apresenta a trilha em seu diálogo após a missão.

O Marco dos Ventos ativa ao passar perto. **Configurações → Voltar ao marco**
retorna à posição segura, limpa velocidade, animação aérea e impacto de câmera.
Cair abaixo do mundo usa o mesmo retorno. O marco e a conclusão são temporários
na partida; iniciar/carregar uma jornada reinicia esses indicadores. O formato
existente de salvamento e a progressão da missão não mudam.

No celular, o dedo que pressiona Pular conserva a propriedade do botão até
soltar/cancelar, inclusive durante movimento e giro de câmera com outros dedos.
Um segundo dedo no botão não rouba o salto. O coelho mantém os clipes existentes;
a pirueta e as inclinações são respostas visuais adicionais sem root motion.

## Direção visual

A inspiração em **Ne Zha 2** é interpretada com uma direção original de fogo
dourado, energia jade e movimentos circulares. Anéis ondulam ao redor das
plataformas; o impulso, o marco e a chegada ao mirante acionam expansões curtas.
As ruínas reutilizam a textura de pedra do projeto e pequenos símbolos de energia.
Isso complementa a ambientação existente da floresta e seus pontos luminosos.

A nova cena soma **1.750 triângulos**; o cenário total passa de 1.218.804 para
1.220.554, mantendo o limite de 1,3 milhão. Usa duas expansões de energia
reutilizáveis e um shader opaco compartilhado, sem criar partículas/nós durante
os eventos e sem luzes dinâmicas novas. A cena fica oculta enquanto a floresta
não foi desbloqueada. Animações de ação e efeitos temporizados param com os menus;
os anéis ambientais usam o tempo do shader, como a vegetação existente.

## Validação

325 verificações de integração aprovadas, sem falhas. Os testes medem altura de
salto curto/longo, propriedade/cancelamento do toque, limites e retorno da
inclinação, pirueta sem alterar orientação física, ativação/retorno seguro do
marco e limpeza na nova jornada. A rota inteira é percorrida pelo controlador
real: impulso até a primeira plataforma, saltos até as duas seguintes e conclusão
única no mirante, sem teletransportar entre as plataformas. Também verificam o
pool de duas expansões e ausência de luzes dinâmicas novas.

Os testes anteriores de controles, colisão, modelos, orçamento de geometria,
Retina, HUD, missão e salvamento continuam ativos. O teste do pacote exportado
verifica a inclusão da trilha e do shader de energia. A aparência foi conferida
em renderização nativa. A sensação e o desempenho no celular físico ainda
precisam ser avaliados no aparelho do usuário.
