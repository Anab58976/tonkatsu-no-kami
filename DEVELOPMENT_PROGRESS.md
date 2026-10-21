# DEVELOPMENT_PROGRESS — Tonkatsu no Kami

Última atualização: 2026-10-19 · Godot 4.3 · GDScript · 640×360 lógico

## Etapa atual
**ETAPA 10 — Floresta Espiritual** (próxima). Etapas 1–9 concluídas, com exceções
listadas abaixo. O projeto roda do menu principal até o fim da Dungeon 3 (Céu).

## Estado por etapa (§38)

| Etapa | Estado | Evidência |
|---|---|---|
| 1 Auditoria | ✅ Projeto partiu do zero (sem projeto existente). Arte enviada pela equipe guardada intacta em `assets/sprites/source/`. Git iniciado. | `git log` |
| 2 Fundação | ✅ Estrutura modular, 9 autoloads, Input Map completo (teclado/mouse/controle) com remapeamento | `project.godot`, `autoload/` |
| 3 Cutscene inicial | ✅ 10 cenas + transformação + chegada ao HUB + título, pular funcionando | testes "Introdução", capturas |
| 4 Jogador | ✅ 4 direções, corrida, esquiva com i-frames, ataque, ataque carregado, habilidade, interação, câmera com limites | `scripts/player/Player.gd`, testes "Combate" |
| 5 HUB | ✅ Vila 100×76 tiles: praça, castelo (6 salas), 5 lojas + mercador, bairro residencial, jardim espiritual, campo de treino, 6 caminhos | testes "HUB", "Castelo" |
| 6 Sistemas | ✅ Inventário (7 categorias), economia (Koban), equipamentos, aprimoramento, missões, progressão/3 árvores, salvamento versionado, culinária | testes |
| 7 Pântano | ✅ Dungeon completa: nível da água (3 níveis), 6 inimigos + golem, Ogro do Repolho (3 fases), 2 caminhos alternativos, 2 missões secundárias | testes "Dungeon 1" |
| 8 Cidade Fantasma | ✅ Mundo físico/espiritual (lanternas + Visão Espiritual), investigação das 3 lembranças, cripta e teatro (caminhos alternativos), Samurai das Mil Almas (3 fases), HUB evolui (espíritos amigáveis, Taro) | testes "Dungeon 2" |
| 9 Céu | ✅ 6 ilhas flutuantes: correntes de vento com sinos, nuvem-balsa, elevador de lótus, ponte de luz temporária (2 cristais), Corredor da Tempestade; Guardião da Tempestade (Pégaso da equipe, 3 fases); 2 caminhos alternativos (Jardim de Cristal + monge Kumo; Ninho do Dragão + mini-chefe); Impulso Celestial; HUB evolui (vento, bandeiras, pássaros) | testes "Dungeon 3" |
| 10 Floresta | ⏳ Não iniciada (props e chão da floresta já extraídos) | — |
| 11 Reino dos Temperos | ⏳ Não iniciada (sprites do Rei Pimenta-Negra prontos) | — |
| 12 Arena | ⏳ Não iniciada (sprites do Cisne/Ganso Dourado prontos) | — |
| 13 Culinária | 🟡 Minigame de várias etapas e receitas prontos; missão final depende das 6 regiões | `scripts/cooking/` |
| 14 Encerramento | ⏳ Cutscene final, créditos completos de fim de jogo e pós-jogo não implementados | — |
| 15 Polimento | 🟡 Contínuo | — |
| 16 Testes finais | 🟡 Suíte automatizada (123 verificações, todas passando); campanha completa ainda não existe | `TEST_REPORT.md` |

## Sistemas concluídos
- Menu principal (Novo Jogo, Continuar, Configurações com volumes/tela cheia/remapeamento, Créditos, Sair)
- Cutscene de abertura cinematográfica, event-driven, com o discurso oficial íntegro
- HUB completo e explorável, evolução do HUB por dungeon (`HubEvolution.gd`)
- Castelo: trono (Rei Porco), biblioteca (livros de lore), sala de mapas (viagem rápida), cozinha real (culinária), treino, recompensas (baús por guardião + pedestais dos ingredientes)
- Lojas com comprar/vender/aprimorar, comparação, confirmação, persistência
- Menu de pausa: Inventário, Equipamento, Habilidades, Missões (diário), Mapa (pergaminho com névoa de exploração), Sistema
- Combate: hitboxes, sem dano duplicado, knockback, partículas, números de dano, i-frames, telegrafia de ataques
- Inimigos com máquina de estados completa (9 estados) e 8 comportamentos
- Chefes: barra, apresentação, fases, zonas de perigo, vitória, recompensa
- Viagem rápida, santuários de salvamento, salvamento automático em pontos-chave
- Pipeline de arte (Python) que converte as folhas de referência da equipe em sprites de jogo

## Sistemas incompletos / limitações conhecidas
- **Dungeons 4–6 (Floresta, Temperos, Arena), seus chefes e ingredientes não existem ainda.** Por isso a campanha não pode ser concluída e a cutscene final/créditos/pós-jogo não foram feitos.
- **Áudio:** não há nenhum arquivo de música/efeito/voz no projeto. O `AudioDirector` está pronto (buses Music/SFX/Ambience/Voice, crossfade) e toca qualquer arquivo colocado em `assets/music/<id>.ogg` e `assets/audio/sfx/<id>.ogg` — ver lista de ids em `ASSET_MANIFEST.md`. O jogo funciona em silêncio até lá.
- **Gravação do discurso:** não fornecida; legendas usam o texto oficial e a sincronização é por digitação (ver `CUTSCENE_PRODUCTION.md`).
- **Arte temporária gerada** (marcada `generated` nos `anims.json`): Rei Porco, NPCs, cozinha, Ogro do Repolho, inimigos menores do pântano, ícones. Substituível sem código (ver `ASSET_MANIFEST.md`).
- Controle (gamepad) mapeado, mas não testado com hardware real.
- Export Windows configurado; o .exe é gerado mas não foi executado em Windows nesta sessão (ambiente Linux).

## Notas técnicas desta etapa
- `GroundLayer.passable`: tiles VOID que ficam transitáveis (correntes, pontes de luz); `lip_colors` por mapa.
- `Player.env_force`: força ambiental (vento, rajadas do chefe); `Player.celestial_leap()` (Impulso Celestial) só salta vãos de vazio/água com chão firme do outro lado.
- `scripts/world/sky/`: WindLane, CloudFerry (balsa automática / elevador sob demanda), TempBridge, SkyCrystal, StormCorridor, SkyBackdrop, IslandEdges.
- Testes novos: simulação física por passos (determinística), validação de que objetos/NPCs/sinos/cais ficam em chão firme.
- Importador de tiras (`build_strips.py`) agora separa quadros colados (Pégaso walk/run, Cisne move).

## Bugs conhecidos
- Nenhum crítico conhecido. Avisos de "ObjectDB leaked" ao fechar em modo headless (inofensivos).

## Próximas tarefas (ordem)
1. Floresta Espiritual (santuários/raízes; Tronquinho da equipe; props da floresta já prontos)
2. Reino dos Temperos (combinação de poderes; Monstro Pimenta Coroado da equipe)
3. Arena (torneio de 7 rodadas; Cisne Dourado da equipe como Ganso Dourado)
4. Missão final de culinária + cutscene final + créditos + pós-jogo
5. Áudio (quando houver arquivos), polimento, campanha completa testada, export final

## Como retomar
- `tools/run_tests.sh` — roda a suíte (deve terminar com "0 failed")
- `tools/capture.sh <cena> <pasta> <intervalo> <velocidade> <duração> [args]` — roda o jogo num display virtual e tira capturas
- Pipeline de arte: `tools/sprite_gen/*.py` (ver `ASSET_MANIFEST.md`)
