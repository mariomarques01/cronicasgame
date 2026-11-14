# Controles em terceira pessoa

Ajuste próprio para Eldervale, estudando o projeto SuperMak64 fornecido pelo usuário
e usando [REA](https://github.com/morluto/rea) 6.9.0 para inventário e extração
seletiva do ZIP. Identidades e hashes em [controls-rea-evidence.json](controls-rea-evidence.json).

O pacote é `SuperMak64-Godot-source.zip`, 284.029.631 bytes. O README declara
Godot 4.7 e origem `mr-mak` no commit `f73ccfb8e`. O REA inventariou 5.296 entradas
e extraiu cinco arquivos de controles e mais quatro de interação/feedback, todos
com política de integridade `fail`.

## Evidências e adaptação

| Princípio | Evidência no SuperMak64 | Aplicação no Eldervale |
| --- | --- | --- |
| Intensidade do analógico | `movement_profile.gd:16–18`, deadzone e curva; `mak_input.gd` mantém magnitude | Zona morta radial de 14%, magnitude contínua até 8 m/s |
| Aceleração e frenagem separadas | `movement_profile.gd:26–39` | Aceleração 36 m/s², freada 60 m/s²; caminhada de teclado 4,5 m/s e Shift até 8 m/s |
| Salto tolerante | `movement_profile.gd:20–22` | Buffer de 0,12 s antes do pouso e tolerância de 0,10 s após perder apoio |
| Estabilidade no chão | `movement_profile.gd:325` | Snap de 0,35 m e parada em rampas |
| Pequenos degraus | `mak_player.gd:2608–2649` | Verificação de teto, avanço e apoio antes de elevar até 0,28 m |
| Interação com NPC | `npc_talker.gd:118–166` | Coelho e Lia se voltam um para o outro; a conversa interrompe o movimento |
| Impacto de aterrissagem | `mak_player.gd:1195` e `juice.gd:2–23` | Evento de contato real e poeira discreta com pool de 3 emissores |
| Câmera de terceira pessoa | `mak_camera.gd:42–49`, órbita, recentralização e antecipação | Órbita independente, antecipação de 0,12 s limitada a 0,8 m e centralização por R/configurações |

Os valores foram calibrados para o coelho e a fazenda existentes. O salto mantém
8 m/s e gravidade de 24 m/s² para preservar o arco e as animações atuais.

No celular, tocar a região inferior esquerda posiciona o joystick sob o dedo.
Um deslocamento pequeno caminha devagar e um maior chega à corrida. O dedo da
direita controla a câmera em toda a área livre, sem disputar input com os
indicadores ou botões do HUD. Um terceiro dedo pode pular durante movimento e
rotação. Cancelar ou soltar o toque libera o controle.

A câmera usa deslocamentos CSS já transformados pelo Godot, com sensibilidade
consistente em retrato, paisagem e DPR 1/2/3. **R** ou **Configurações → Centralizar
câmera** coloca a vista atrás do personagem e também retorna da vista aérea.
A órbita mantém os limites de inclinação e a colisão por SpringArm3D.

Os giros não extrapolam em frames lentos. A velocidade dos clipes Walking/Running
acompanha a velocidade horizontal real, com histerese entre andar e correr.
Pausar ou abrir um menu zera o impulso horizontal antigo.

Pequenos degraus usam testes de colisão antes da subida: espaço livre acima,
trajeto desobstruído e apoio caminhável do outro lado. A elevação é limitada a
0,28 m; paredes, cercas e obstáculos altos continuam bloqueados. Ao conversar,
as malhas se orientam sem deslocar as colisões do jogador ou da Lia.

Aterrissagens acima de 3,5 m/s acionam uma nuvem curta de poeira, em conjunto com
a animação de absorção existente. São três emissores reutilizáveis de oito
partículas, com material/gradiente originais, sem custo contínuo quando parados.
O efeito respeita a pausa e não é acionado por pequenos desníveis a cada passo.

## Validação

270 verificações aprovadas, zero falhas. Os testes usam o CharacterBody3D real
sobre uma plataforma de colisão, medindo aceleração, velocidade parcial/total,
frenagem, diagonais, direção relativa à câmera, caminhada/Shift, tolerância de
borda, expiração dessa tolerância e salto armazenado até o pouso. Também enviam
multitoque real para joystick/câmera/pulo, cancelamento de toque, bloqueio sobre
HUD e centralização, incluindo arrastos físicos em telas Retina. Os testes também verificam degraus
baixos, bloqueio em obstáculos altos, disparo/pausa do feedback de aterrissagem
e orientação das malhas na conversa sem desalinhamento de colisão.

A referência foi analisada estaticamente. O SuperMak64 original não foi executado
neste ambiente; a sensação final ainda precisa de avaliação no aparelho do usuário.
A implementação desta entrega cobre locomoção, câmera, assistência ao salto,
degraus baixos, orientação em diálogos e feedback de aterrissagem.
Os sistemas de combate, escalada e saltos acrobáticos do SuperMak64 não fazem
parte desta alteração.

## Reproduzir a análise

```sh
npx -y rea-agents@6.9.0 inspect-artifact /caminho/SuperMak64-Godot-source.zip --detail summary --evidence_output /caminho/novo-evidence.json --json
npx -y rea-agents@6.9.0 extract-artifact --help
```

A extração seletiva usa os `occurrence_id` do inventário. Os relatórios completos
e os arquivos de referência ficam fora do projeto do jogo.
