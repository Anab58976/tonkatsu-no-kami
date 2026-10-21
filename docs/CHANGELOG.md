# CHANGELOG — Tonkatsu no Kami

## [Casas sólidas e objetivo que fecha] — 2026-10-21
- Casas, lojas, salões e o templo de escadas são sólidos em quase toda a altura: a Lulu para na parede e não anda mais por cima das construções (só a beirada do telhado continua passável, com a casa ficando translúcida).
- Caminhada da Lulu refeita: de lado, a cabeça, o chapéu e o avental ficam firmes e só as pernas andam (antes cada quadro "derretia"); de frente e de costas, os pés levantam de verdade; ritmo um pouco mais rápido para os pés não deslizarem; nas diagonais ela não fica trocando de direção.
- Caixa de objetivo com um **x** para fechar; fica uma aba "Objetivo (O)" para abrir de novo (clique ou tecla O; no controle, clique do analógico direito). A escolha fica salva e também está em Configurações. Quando aparece um objetivo novo com a caixa fechada, a aba pisca.
- Portão do templo da Vila Fantasma simétrico (o telhado estava torto para a direita) e portais das regiões alinhados: arco de pedra do pântano, arco de mármore do céu.
- Menu de pausa: as seis abas cabem na tela (antes o painel passava da borda direita); aba Sistema centralizada; nomes das habilidades inteiros.

## [Créditos da Momori Games] — 2026-10-20
- Abertura sem música: o tema do menu se apaga e fica só a voz do Rei Porco (e o fogo baixinho da cozinha).
- Créditos com a Momori Games e a função de cada integrante (menu e cena final).
- Tela cheia por padrão (F11 / Alt+Enter alterna) e som novo de dano da Lulu.

## [As três últimas fases] — 2026-10-20

### Adicionado
- **Floresta Mágica:**
  - Arvorezinhas: o Tronquinho, que cospe sementes, e o toquinho com flor, que salta.
  - Sementes de Luz fazem crescer uma ponte de vitórias-régias sobre o rio.
  - Três flores-espírito abrem as raízes do caminho do lago.
  - Chefe: **Cisne Dourado**, com leque de penas, deslize, rajada das asas, chuva dourada e mergulho.
  - Recompensa: Ovo Dourado.
  - Missão extra: "Os kodamas perdidos".
- **Reino dos Temperos:**
  - Pimentinhas em quatro variações (Monstro Pimenta Coroado da equipe).
  - Três potes de tempero real:
    - Na passarela de grelhas de fogo.
    - Com a Gangue da Páprica.
    - Nos quatro braseiros do jardim.
  - Os potes vão ao grande pilão, que abre o Palácio do Sol.
  - Chefe: **Rei Quente**, com coroa de chamas, chuva de pimenta, raio do meio-dia e pimentinhas convocadas.
  - Recompensa: Temperos Imperiais.
  - Missão extra: "O banquete do Chef Pimenta".
- **Arena Final:**
  - O portal só abre com 5 ingredientes.
  - Três rodadas de Oniguerreiros, guerreiros de oniguiri em quatro tipos.
  - Chefe: **Espadashi Touro**, com investida que o atordoa na parede, corte duplo, pisão em anéis e espadas voadoras.
  - Recompensa: Carne Lendária. Com ela, os seis ingredientes levam à cena final.
- **Desenhos novos no estilo do jogo:** Rei Quente, Espadashi Touro e Oniguerreiros. O Cisne ficou em tamanho de chefe e as pimentinhas e o toquinho foram feitos a partir da arte da equipe.
- **Habilidades:** Manipulação de Raízes (raízes prendem os inimigos ao redor) e Infusão Elemental (giro de fogo).
- **Câmera:** nas lutas de chefe, ela se inclina para o chefe, para ele não ficar cortado na tela.
- **Sons novos para tudo que estava mudo:** acerto, baú, moedas, compra, letras do diálogo e outros. Também ambientes da vila e da cozinha.
- **Minimapa:** usa as cores reais do chão de cada região.

### Corrigido
- Tronquinho com quadros vazios (piscava) e ataque quebrado.
- O som `crystal_off` não existia.

### Testes
- 331 verificações automáticas, todas passando. A bateria agora roda em duas metades (`tools/run_tests.sh`).

## [Master prompt + áudios da equipe] — 2026-10-20

### Adicionado
- **Áudios da equipe:** veja `docs/AUDIO_MANIFEST.md` e `docs/AUDIO_CREDITS.md`.
  - 11 músicas: fases, chefe, vitória, derrota, tela inicial, receita final.
  - Efeitos do Freesound conforme as notas das pastas.
  - Dublagem do Rei Porco recortada em 28 falas sincronizadas com o texto; a música abaixa enquanto ele fala.
- **Cena final** (`scenes/cutscenes/FinalCooking.tscn`): Tonkatsu no Kami, Lulu volta a ser menina e os créditos rolam com "Receita Final". Antes, a cozinha do castelo apontava para uma cena inexistente.
- **Portais temáticos físicos** para as 6 regiões e portal de volta em cada região, com animação de entrada, partículas, luz, som, nome do destino e trava contra teleporte repetido.
- **Minimapa** no canto superior direito:
  - Ícones: porquinho para a Lulu, objetivo, lojas, portais, saídas, moradores e santuários.
  - Névoa sobre o que não foi explorado e indicação do norte.
  - Clicar no minimapa ou apertar M abre o mapa completo, que tem legenda e nomes que não se sobrepõem.
- **Vila reorganizada em bairros:**
  - Forja na rua dos artesãos.
  - Mil Sabores nas residências.
  - Caldeirão no jardim espiritual.
  - Relíquias na estrada sul.
  - Proteção da Sakura e Casa de Chá na rua leste.
- **Placas legíveis** em todos os cruzamentos, perto dos portais e na chegada de cada região.
- **Integrantes do grupo** (Julia, Heloisa, Ana, Leandro, Kong, Higa) como porquinhos andando pela vila.
- **Sons do menu**, cursor animado e transições de painel.
- **Movimento ambiente por região** (pétalas, vaga-lumes, espíritos, vento), que respeita a qualidade gráfica.
- **Configurações:** tela cheia salva, "Pixels perfeitos" e Qualidade gráfica (Alta/Média/Baixa).
- **Céu:** a casa foi removida; raios com aviso e rajadas de projéteis aleatórias e justas.

### Corrigido
- Lulu duplicada no ataque (quadro com dois porcos).
- Direções das animações da Lulu.
- Borda preta ao jogar em tela cheia (escala fracionária).
- "Vila do Rei Porco" aparecendo como objetivo na Vila Fantasma.
- Vilões de cada fase agora são os da equipe:
  - Pântano: cogumelos e Golem de Pedra.
  - Vila Fantasma: fantasminhas e Lobo Fantasma.
  - Céu: espíritos do céu e Pégaso.
- Objetivo do HUD sobrepondo o cartão de entrada da região.
- Casas e árvores grandes agora ficam translúcidas quando Lulu passa atrás delas.

### Testes
- 272 verificações automáticas, todas passando.

## [Reborn — Marco 0 + início do Marco 1] — 2026-10-19

### Adicionado
- `tools/audit_pixels.py`: auditoria automática de todas as imagens. Cobre transparência, fundo opaco, cortes, deriva de pés e centro, altura × padrão, contorno e ruído. Gera `docs/ASSET_INVENTORY.md`.
- `tools/sprite_gen/build_palettes.py` → `resources/palettes/palettes.json` + `docs/img/palettes.png`: núcleo de cores comum + rampa por região, extraída da arte da equipe.
- Documentos: `PIXEL_ART_AUDIT.md`, `ART_DIRECTION.md`, `TONKATSU_REBORN_ROADMAP.md`, `ASSET_INVENTORY.md`, `UI_DESIGN.md`, `BUG_REPORT.md`, `CHANGELOG.md` (em `docs/`).
- Teste "Câmera (pixel art sem tremor)": 3 verificações.

- `tools/sprite_gen/repixel.py`: re-pixelizador único + prova comparativa (`docs/img/repixel_proof.png`).

### Corrigido
- Tremor de 1 px da Lulu ao andar (câmera agora no passo de física). Medido: 109 → 0 inversões.
- NPCs cortados no topo (célula 32×32 → 40×44).
- Lulu nascendo em cima da fonte da praça.

### Backup
- Tag git `pre-reborn-backup` e `/home/claude/backups/tonkatsu_pre_reborn_20261019_2200.tar.gz` (306 MB).

### Testes
- 200 verificações automáticas, todas passando.

## [Versão base] — 2026-10-19
Jogável até o fim do Reino dos Céus. Ver `DEVELOPMENT_PROGRESS.md`.
