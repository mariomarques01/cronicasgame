# Progresso por fase

## 1 — Fundação
Criados `project.godot`, cena principal, autoload, controlador e Input Map em runtime. Movimento, corrida, salto e câmera com colisão implementados. Executar pela Godot/F5. Importação e instanciação headless aprovadas. Limites: personagem cápsula, sem animações/gamepad. Próximo: modelo e AnimationTree.

## 2 — Mundo 3D
Criados terrain.gd e world.gd: 256 m, colinas, caminhos por cor, casa, celeiro, canteiros decorativos, lago visual, cercas, vegetação MultiMesh e árvore ancestral. Colisão do terreno e pouso do jogador testados. Limites: arte provisória, sem fauna/moinho/ponte/streaming, sem colisão nas árvores repetidas. Próximo: assets, setores, texturas e perfil de desempenho.

## 3 — Interação
Lia, diálogo e três pedras únicas integrados; inventário empilha pedras. Testes de coleta anterior à missão e duplicata aprovados. Limites: alvos por proximidade, sem linha de visão; NPC estático, sem navegação; inventário específico da missão. Próximo: recursos de item e componente genérico de NPC.

## 4 — Progressão
Metadados em JSON; transições da missão e abertura real do portão; salvamento validado. Testes de sequência, bloqueios, recompensa única, colisão e persistência aprovados. Falha encontrada: comparação estrita de dicionários com números JSON; corrigida. Limites: apenas missão única; sem sistema genérico de campanha, sem progresso de agricultura/construção. Próximo: QuestDefinition/QuestRuntime e migrações de save.

## 5 — Interface
Menu inicial, continuar condicional, pausa, mochila, diálogo, objetivo, avisos e opções de sombras/ciclo solar. Sair disponível no desktop. Limites: interface básica, sem menus gráficos completos, layout prioritário 1280×720. Próximo: UI responsiva e acessibilidade.

## 6 — Validação e distribuição
Importação, execução headless, integração e exportação Web realizadas. Presets Web/Windows e CI/Pages criados. Consulte validation.md para resultados reais. Ativação administrativa de Pages bloqueada por permissão HTTP 403. Próximo: ativar Pages nas configurações e medir no hardware alvo.

## 7 — Expansão futura
Não implementada. Estabilizar e melhorar o vale, acrescentar inventário genérico, agricultura e reparos; depois capítulo 1 completo, streaming e progressão por dados. Só então acrescentar as outras regiões conforme game_design.md. Priorizar testes de save e regressão em cada expansão.
