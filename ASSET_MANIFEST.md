# ASSET_MANIFEST — Tonkatsu no Kami

## Arte enviada pela equipe (originais intactos em `assets/sprites/source/`)
| Arquivo | Uso no jogo | Estado |
|---|---|---|
| `lulu_human_sheet.jpg` | Lulu humana (cutscenes, transformação) | ✅ integrado |
| `lulu_pig_sheet.jpg` | Retratos, giro, props (frigideira/espátula/laço) | ✅ integrado |
| `lulu_full_sheet.png` | Lulu porquinha e humana em 4 direções (idle/andar/correr/pulo/ataque/dano) — **animação oficial de gameplay** | ✅ integrado |
| `enemy_ghost_sheet.png` | Espírito errante (Cidade Fantasma) | 🟡 convertido, aguardando dungeon |
| `enemy_shadow_wolf.png` | Lobo de sombras | 🟡 convertido |
| `enemy_mushroom_golem.png` | Cogumelo agressivo + Golem de musgo (Pântano) | ✅ integrado |
| `enemy_stump.png` | Tronquinho (quadro único) | 🟡 |
| `boss_golden_swan.png`, `docx/Cisne_Dourado` | Ganso/Cisne Dourado (Arena) | 🟡 convertido, aguardando dungeon |
| `boss_pegasus_side_sheet.png`, `docx/Pegaso_Dourado` | Guardião da Tempestade (Céu) | 🟡 convertido |
| `docx/Monstro_Pimenta_Coroado` | Rei Pimenta-Negra | 🟡 convertido |
| `docx/Lobo_Infernal` | Lobo infernal / Guerreiro do fogo | 🟡 convertido |
| `docx/Espirito_Chama_Azul` | Espírito de chama azul (Cidade Fantasma; espíritos amigáveis do jardim) | ✅ parcialmente usado |
| `docx/Tronquinho_Magico` | Espírito da madeira (Floresta) | ✅ usado na cutscene |
| `item_golden_egg_*.png` | Ovo Dourado (flutuar/girar/coletar) | 🟡 convertido |
| `item_flour_sack*.png` | Saco de farinha | 🟡 convertido |
| `tiles_village_day.png` | HUB inteiro (árvores, casas, torii, pontes, lanternas, campos, Fuji) | ✅ integrado |
| `tiles_village_night.png` | Prédios do castelo (versão "luz do dia"); Cidade Fantasma | ✅/🟡 |
| `tiles_spirit_forest_a/b.png` | Pântano (graduação oliva) e Floresta (original) | ✅/🟡 |
| `ref_map_*.png` | Fundos dos cartões das regiões / menu | ✅ |
| `docs/specs/*.docx` | Documentos de sprites (originais) | guardados |

**Conversão:** `tools/sprite_gen/` remove fundo (flood-fill), recupera a grade de pixels de cada folha, reduz para escala 1:1 e unifica a paleta. Resolução de jogo: Lulu ~24 px de altura; tiles 32×32; construções 1,6× para portas compatíveis.

## Arte gerada (temporária, substituível sem código)
Rei Porco · 16 NPCs da vila · Ogro do Repolho · Sapo guerreiro · Mosquito gigante · Planta carnívora · Espírito do lodo · Caranguejo · cozinha da introdução · portal/espaço mágico/pergaminho/cartões · logotipo · 60 ícones de itens · chão de madeira/tatami · mobília do castelo.
Para substituir: crie `assets/sprites/characters/<id>/` com PNGs por animação + `anims.json` (`cell_w`, `cell_h`, `origin` = pés, `animations{nome: file, frames, fps, loop}`). O `SpriteLibrary` passa a usar essa pasta automaticamente.

## Sprites necessários (faltando arte oficial)
- Rei Porco: idle, walk, talk, talk_stern, inspect, arms_crossed(+talk), point, point_side, warm(+talk), arms_open, grand_talk, point_up_talk, stare(+talk), extend_arm, wave, taste, shocked, joy, thinking (célula 80×80, pés em 40,76)
- NPCs: Takeshi, Hana, Mestre Sapo, Yumi, Tanuki, Comerciante, Kenji, guardas, Fukuro, moradores (idle/walk em down/up/side + talk; 32×32)
- Chefes sem arte: Ogro do Repolho, Samurai das Mil Almas, Unicórnio Ancestral
- Inimigos sem arte: os 5 menores do pântano; Cidade Fantasma (samurai fantasma, armadura possuída, marionete, corvo, guardião do cemitério); Céu (pássaro elétrico, espírito da tempestade, guerreiro das nuvens, harpia, sentinela, dragão de vento); Floresta (lobo espiritual, raposa ilusória, criatura das raízes); Temperos (soldado de pimenta, cavaleiro de sal, mago de canela, golem de especiarias, arqueiro de mostarda, guarda real); Arena (gladiador javali, campeão celestial, samurai veterano, campeão da arena)
- Lulu humana: animações de cutscene finais (provar, comemorar) — hoje derivadas da arte existente

## Áudio — nenhum arquivo ainda
Coloque `.ogg`/`.wav` com estes ids (o jogo toca automaticamente):
- Música (`assets/music/`): `title`, `intro_kitchen`, `intro_king`, `intro_hope`, `intro_grand`, `intro_mystery`, `intro_magic`, `hub`, `castle`, `shop`, `swamp`, `boss_swamp`, `victory`, `defeat`
- Ambiente (`assets/audio/ambience/`): `kitchen`, `village`, `swamp`
- Efeitos (`assets/audio/sfx/`): `blip`, `step`, `swing`, `spin`, `hit`, `hit_boss`, `hit_straw`, `hurt`, `dodge`, `enemy_attack`, `enemy_die`, `spit`, `clank`, `deflect`, `coin`, `heart`, `pickup`, `chest`, `lever`, `wheel`, `water_flow`, `door_slide`, `plate`, `magic_rise`, `magic_circle`, `portal_open`, `portal_enter`, `transform_charge`, `transform_burst`, `land_soft`, `title_hit`, `card_whoosh`, `scroll_open`, `ingredients`, `soft_chime`, `ui_confirm`, `ui_move`, `ui_error`, `menu_open`, `equip`, `use_item`, `buy`, `shop_bell`, `save`, `secret`, `teleport`, `level_up`, `slam`, `roots`, `thunder`, `throw`, `roar`, `boss_down`, `fanfare`, `chop`, `tap`, `cook_good`, `cook_bad`
- Voz: `assets/audio/voice/intro_rei_porco.ogg` (ver `CUTSCENE_PRODUCTION.md`)

## Licenças
- Fontes: Pixelify Sans e Silkscreen — SIL Open Font License (arquivos OFL incluídos em `assets/fonts/`). Texto japonês do logotipo renderizado com IPA Gothic (IPA Font License) apenas no PNG gerado.
- Godot Engine — MIT.
- Nenhuma arte de terceiros/protegida foi usada; toda arte é da equipe ou gerada pelo pipeline do projeto.
