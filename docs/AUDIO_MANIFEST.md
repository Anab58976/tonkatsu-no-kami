# AUDIO_MANIFEST — onde cada áudio toca

Formato `.ogg`, `.wav` ou `.mp3`, com **exatamente** o id abaixo como nome. O jogo encontra sozinho; arquivo faltando não trava nada (aquele ponto fica em silêncio ou usa o substituto indicado).
- Música → `assets/music/<id>.ogg` · Efeitos → `assets/audio/sfx/<id>.ogg` · Ambiente → `assets/audio/ambience/<id>.ogg` · Voz → `assets/audio/voice/`

Músicas tocam em loop (menos vitória e derrota), com transição suave, e nunca reiniciam quando dois lugares usam a mesma faixa. Volumes de Música, Efeitos, Ambiente e Vozes ficam em Configurações. Enquanto uma voz fala, a música abaixa um pouco sozinha.

Importação dos arquivos da equipe: `python3 tools/audio_gen/import_team_audio.py <pasta MUSICAS> <pasta EFEITOS>` (converte, normaliza o volume e renomeia). Dublagem: `python3 tools/audio_gen/split_king_voice.py`.

## Música (arquivos da equipe — `tonkatsu no kami MUSICAS`)
| id | arquivo da equipe | onde toca |
|---|---|---|
| `title` | tela inicial tonkatsu no kami | menu inicial e a Vila (não há faixa própria da vila). A abertura fica **sem música**, para a voz do Rei Porco aparecer bem |
| `swamp` | Level Pântano | Pântano dos Esquecidos |
| `ghost_city` | Level Cidade fantasma | Vila Fantasma |
| `sky` | Level céu | Reino dos Céus |
| `spirit_forest` | Level Floresta mágica | Floresta Mágica (quando a fase existir) |
| `spice_kingdom` | Level Reino dos temperos | Reino dos Temperos (quando a fase existir) |
| `arena` | Level Arena final | Arena final (quando a fase existir) |
| `boss` | EXTRA Tema de chefe | todos os chefes |
| `victory` | EXTRA Vitória | ao derrotar um chefe / passar de fase (toca uma vez) |
| `defeat` | EXTRA Derrota | tela de derrota (toca uma vez) |
| `final_recipe` | RECEITA FINAL (tonkatsu completo) | cena final: o Tonkatsu no Kami e os créditos |

Substitutos automáticos: `hub`, `shop`, `castle`, `intro_*` → `title`; `boss_swamp`, `boss_ghost`, `boss_sky`… → `boss`. Para dar uma faixa própria a qualquer um deles, basta colocar o arquivo com aquele id.

## Voz
| arquivo | onde |
|---|---|
| `voice/rei_porco/<id da fala>.ogg` (28 clipes) | abertura: cada página de fala do Rei Porco toca o seu trecho da dublagem da equipe; o texto acompanha a voz e a página fica até ele terminar |
| `voice/source/rei_porco_intro.mp3` | gravação original (fora do jogo exportado; os tempos de cada fala estão em `resources/cutscenes/intro_speech.json`) |

## Efeitos da equipe (`EFEITOS Tonkatsu no kami`)
| pasta / nota | som | id no jogo | onde toca |
|---|---|---|---|
| LULU · PULO | 8-bit jump | `jump` (também `land_soft`) | salto celestial no céu, pousos |
| LULU · ATAQUE | pig grunt | `swing` | golpe da espátula |
| LULU · SOM DA LULU | oink | `oink` | ao falar com NPCs, primeiro "oinc" na chegada à vila |
| LULU · ANDAR | passos na madeira | `step`, `step_2..4` | passos (sorteia uma das 4 gravações) |
| LULU · DANO | porquinho gritando | (fora do jogo) | o grito ficou grande demais para a Lulu: o dano agora é um "oinc!" curtinho feito do SOM DA LULU (`tools/audio_gen/lulu_hurt.py`) → `hurt` |
| LULU · DASH | fast whoosh | `dodge` (também `spin`, `wind_whoosh`) | esquiva, giro, correntes de vento |
| COLETA · INGREDIENTE | spacey 1up | `pickup` (também `ingredients`) | pegar itens e ingredientes |
| COLETA · VIDA EXTRA | 1up | `heart` | pegar coração |
| COLETA · INGREDIENTE PRINCIPAL | item pickup chime | `legendary` (também `fanfare`) | ingrediente lendário sobe do chefe derrotado |
| CHEFES · GOLEM | passo de trator | `boss_golem` (também `slam`) | rugido/golpe do Golem de Pedra, impactos no chão |
| CHEFES · LOBO FANTASMA | lobo agressivo | `boss_lobo` | Lobo Fantasma |
| CHEFES · PÉGASO | relincho | `boss_pegaso` | Pégaso Dourado |
| CHEFES · CISNE | magic15 | `boss_cisne` | Cisne (Floresta Mágica, quando existir) |
| CHEFES · REI QUENTE | explosão 8-bit | `boss_rei_quente` | Rei Quente (quando existir) |
| CHEFES · TOURO | beast of burden | `boss_touro` | Espadashi Touro (quando existir) |
| INIMIGOS · COGUMELOS | pop-up | `enemy_cogumelo` | ataque (mais agudo) e derrota dos cogumelos |
| INIMIGOS · FANTASMINHAS | breath ghost vanish | `enemy_fantasminha` | fantasminhas |
| INIMIGOS · ESPÍRITOS DO CÉU | fading fire flame | `enemy_espirito_ceu` | espíritos do céu |
| INIMIGOS · ARVOREZINHAS | dropping wood | `enemy_arvorezinha` | arvorezinhas (quando a fase existir) |
| INIMIGOS · PIMENTINHAS | electric | `enemy_pimentinha` | pimentinhas (quando a fase existir) |
| AMBIENTE · SINO | town bells | `town_bells` / `bell` (curto) | sinos da vila de tempos em tempos, santuário de salvar, sino do céu |
| AMBIENTE · VENTANIA | big cold winter wind | ambiente `high_wind` (e `ghost_wind`, mais baixo) | fundo do Reino dos Céus e da Vila Fantasma |
| AMBIENTE · SAPOS | cigarras e sapos | ambiente `swamp` | fundo do Pântano |
| AMBIENTE · PORTAL | fast warp in | `portal_enter` (também `teleport`, `portal_open`, `realm_shift`) | entrar nos portais, troca de mundo |

## Gerados pelo projeto (`tools/audio_gen/ui_sfx.py` e `tools/audio_gen/game_sfx.py`)
Feitos no mesmo estilo dos efeitos da equipe (um pouco retrô, com madeira e sinos japoneses). Para trocar qualquer um, basta colocar um arquivo com o mesmo nome.

| grupo | ids |
|---|---|
| Menu | `ui_hover`, `ui_select`, `ui_confirm`, `ui_back`, `ui_open`, `ui_error`, `game_start` |
| Combate | `hit` (acertar inimigo), `hit_boss`, `hit_straw` (boneco de treino), `clank`, `deflect`, `iai`, `throw`, `spit`, `roots`, `thunder`, `defeat` |
| Exploração | `chest` (baú), `coin` (moedas), `door_slide`, `lever`, `wheel`, `water_flow`, `secret`, `save`, `region_enter`, `wind_gust`, `crystal_on`, `magic_rise`, `magic_fade`, `magic_soft`, `magic_bridge`, `magic_circle` |
| Lojas e interface | `buy` (comprar), `shop_bell`, `equip`, `use_item`, `blip` (letras do diálogo), `tap`, `soft_chime`, `scroll_open`, `level_up` |
| Culinária | `chop`, `cook_good`, `plate` |
| Abertura | `title_hit`, `transform_charge`, `transform_burst` |
| Ambiente | `village` (pássaros e brisa na vila), `kitchen` (fogo e panela) |

Agora todo som que o jogo pede tem um arquivo.
