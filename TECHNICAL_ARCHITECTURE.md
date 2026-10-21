# TECHNICAL_ARCHITECTURE — Tonkatsu no Kami

## Engine e renderização
- Godot 4.3, renderer *GL Compatibility* (roda em hardware modesto).
- Viewport lógico 640×360, `stretch_mode=viewport`, `scale_mode=integer` → pixels sempre inteiros e nítidos.
- Filtro de textura *nearest* global, snap 2D de transforms e vértices.
- Fontes de pixel (Pixelify Sans, Silkscreen) sem anti-aliasing.

## Autoloads (`autoload/`)
| Autoload | Responsabilidade |
|---|---|
| `Game` | Estado global serializável (`Game.state`): cena, posição, forma, flags, Koban, stats, inventário, equipamento, níveis de arma, buffs, receitas, habilidades, missões, exploração do mapa. Aplica o estado final da introdução (`apply_intro_completion`, usado pela introdução completa **e** pelo pular). |
| `InputConfig` | Registra todas as ações (teclado, mouse, controle) e persiste remapeamentos em `user://input.cfg`. |
| `SpriteLibrary` | Monta `SpriteFrames` a partir de pastas com `anims.json`. Procura primeiro `assets/sprites/characters/<id>/` (arte oficial) e depois `assets/sprites/generated/<id>/`. |
| `AudioDirector` | Buses Music/SFX/Ambience/Voice, crossfade de música, pool de SFX. Arquivos ausentes são ignorados com segurança. |
| `SaveManager` | JSON versionado em `user://saves/slot_N.json`, escrita atômica (tmp + rename), validação, migração, recuperação de HP. |
| `ItemDB` | Itens (`resources/items/items.json`), inventário, equipamento, compra/venda, aprimoramento, ícones, consumo. |
| `QuestManager` | Missões data-driven (`resources/quests/quests.json`), objetivos automáticos (item/flag/abates), progresso monotônico, recompensas. |
| `SceneRouter` | Troca de cena com fade, bloqueio contra trocas duplas. |
| `DialogueManager` | API `await say(...)`, caixa de diálogo com digitação, sinais para lip-sync, `abort()` para pular. |

## Organização
```
scenes/   main, intro, hub (Hub, Castle), shops, dungeons/swamp, ui, cutscenes
scripts/  core (Main, UiTheme, Relay, TestHarness)
          cinematics (CutsceneDirector, IntroDirector, CutsceneActor, CutsceneCamera,
                      MagicPortal, MagicSpace, WorldScroll, RegionVignette,
                      IngredientOrbit, Shockwave, TitleCard, HubArrival, Shichirin)
          dialogue (DialogueBox) · player (Player)
          combat (SlashFx, DamageNumber, Telegraph, Projectile, Pickup, PoisonCloud)
          enemies (Enemy) · bosses (Boss, BossBar, HazardBurst, OgroRepolho)
          world (WorldMap, GroundLayer, InteriorLayer, Prop, Furniture, Npc, Interactable,
                 RegionGate, FastTravel, HubPieces, HubEvolution, Hub, Castle)
          dungeons (Swamp) · shops (ShopUI, ShopInterior) · cooking (CookingGame, CookingUI)
          progression (Progression) · ui (MainMenu, PauseMenu, MapView, Hud, Choice,
                 SettingsPanel, CreditsPanel, GameOverScreen, VictoryBanner)
resources/ items, quests, shops, npcs, enemies, recipes, progression, cutscenes (JSON)
assets/    sprites/{source, extracted, generated, props, tiles}, fonts, music, audio
shaders/   flash, water, stone
tests/     TestRunner (suíte automatizada)
tools/     sprite_gen (pipeline Python de arte), run_tests.sh, capture.sh, check_scripts.sh
```

## Decisões principais
- **Dados separados de lógica**: itens, lojas, missões, NPCs, inimigos, receitas, habilidades e o discurso são JSON em `resources/`. Adicionar conteúdo não exige código.
- **Cutscenes event-driven**: `CutsceneDirector` oferece `say()` (espera o diálogo terminar), `wait()`, `await_tween()`. Toda espera pertence ao nó da cutscene (`Relay`), então ao pular/liberar a cena nenhuma corrotina "acorda" num objeto morto.
- **Mapas construídos em código** (`WorldMap`): `GroundLayer` (grade de tiles + colisão gerada + reconstrução em tempo de execução), camadas decals / entities (y-sort) / overhead, grade de ocupação para espalhar vegetação sem bloquear caminhos.
- **Camadas de colisão**: 1 mundo · 2 corpo do jogador · 4 hurtbox de inimigo · 8 hitbox do jogador · 16 hitbox de inimigo · 32 interagíveis.
- **Comunicação por sinais** (`Game.flag_set`, `ItemDB.inventory_changed`, `QuestManager.quest_updated`, `Enemy.died`, `Boss.defeated`...).
- **Desempenho**: inimigos a mais de 520 px dormem (física e animação pausadas); chão desenhado uma vez (comandos de desenho em cache); colisão de água agrupada por faixas.

## Fluxo de cenas
`Main` → `MainMenu` → (Novo Jogo) `IntroCutscene` → `Hub` (+`HubArrival`) ↔ `Castle` / `ShopInterior` / `Swamp` …
Continuar: `SaveManager.load_game()` → cena salva com `pending_entry = {"arrival": "load"}` (nunca repete a introdução).

## Testes
`tests/TestRunner.tscn` roda dentro da engine com as autoloads reais. Inclui verificação de alcançabilidade com consultas de física reais (props, água, paredes) — detectou e corrigiu um bug real da ponte de jangadas.
