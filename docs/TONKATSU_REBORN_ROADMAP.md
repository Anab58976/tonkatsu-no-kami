# TONKATSU REBORN — Roadmap de produção

**Ponto de partida:** a versão jogável até o fim do Reino dos Céus (3 de 6 regiões), com:
- 200 testes automáticos passando;
- backup em `pre-reborn-backup` (tag git) + `/home/claude/backups/tonkatsu_pre_reborn_*.tar.gz`.

**Regra:** cada marco é entregue em passos pequenos. Um passo só conta como feito quando:
1. carrega;
2. está integrado;
3. o asset existe;
4. funciona;
5. foi inspecionado visualmente (captura);
6. foi testado;
7. o salvamento continua válido;
8. não quebra os testes existentes.

---

## Decisões tomadas a partir do documento "Tonkatsu Reborn"

| Tema | Antes | Agora | Onde entra |
|---|---|---|---|
| Moeda | Koban | **Ryō** (nome exibido). A chave interna do save continua `koban`, então saves antigos seguem válidos. | Marco 6 |
| Armas | espadas, katanas, lança | **utensílios de cozinha** (colher, espátula, concha, batedor, rolo, frigideira, pegador, hashis + variantes) | Marco 5 |
| Loja de armas | Forja do Dragão | **Oficina de utensílios encantados** (Takeshi continua o ferreiro) | Marco 5 |
| Floresta Espiritual | santuários e raízes | **ilusões** (santuários e raízes viram parte dos puzzles de ilusão) | Marco 7 |
| Reino dos Temperos | combinação elemental | **castelo com infiltração** (furtividade), mantendo o Rei Pimenta-Negra | Marco 7 |
| Arena | torneio | **coliseu**: chefe final das regiões, que exige as habilidades aprendidas | Marco 7 |
| HUB | lojas numa rua só | **distritos**: comercial, oficina culinária, jardim espiritual (alquimista e curandeira), treinamento | Marco 3 |

O que **já existe e funciona** é preservado e reaproveitado:
- história e cutscene de abertura com o discurso oficial;
- Pântano (água), Cidade Fantasma (mundo espiritual), Céu (vento e plataformas);
- chefes, missões, culinária, salvamento, testes.

---

## MARCO 0 — Auditoria ✅
- [x] Backup (tag + arquivo)
- [x] Inspeção técnica: resolução, filtro, snap, importação, câmera, tiles
- [x] Auditoria automática de 451 imagens (`tools/audit_pixels.py`)
- [x] Capturas de todas as telas principais inspecionadas
- [x] `docs/PIXEL_ART_AUDIT.md`, `docs/ASSET_INVENTORY.md`, `docs/BUG_REPORT.md`

## MARCO 1 — Padrão visual 🔶 em andamento
- [x] Resolução 640×360 em escala inteira, nearest, snap (verificados; mantidos)
- [x] Câmera sem tremor (física) + teste automático
- [x] Tabela de tamanhos-alvo e regras de contorno, alfa e animação (`docs/ART_DIRECTION.md`)
- [x] Paletas por região extraídas da arte da equipe (`resources/palettes/palettes.json`)
- [x] Correções imediatas achadas na auditoria: NPCs cortados, spawn em cima da fonte
- [x] Re-pixelizador único (`tools/sprite_gen/repixel.py`: grade → mediana → paleta → contorno interno) — **prova em 5 objetos do HUB** em `docs/img/repixel_proof.png` (ruído: lanterna 30→18%, arbusto 28→18%, torii 14→8%, banco 10→5%; cerejeira 10→13% por textura de flores)
- [ ] Aplicar o re-pixelizador aos 301 objetos (aguardando aprovação visual da prova)
- [ ] Prova de conceito de `TileMapLayer` com terrenos (autotiling + transições) no HUB

## MARCO 2 — Protagonista
- [ ] Lulu porquinha em 40 px, reconstruída a partir das vistas de alta resolução da equipe (`lulu_pig_sheet`: vista girando ~58 px nativos; caminhada lateral ~44 px)
- [ ] Animações completas, 4 direções (lista em `ART_DIRECTION.md` §6)
- [ ] Utensílio em camada separada, sempre na mão, trocando de lado conforme a direção
- [ ] Colisão e hitbox revistas para o novo tamanho
- [ ] NPCs reconstruídos na nova escala, com corpos diferentes por espécie

## MARCO 3 — HUB
- [ ] Novo layout com distritos (praça, comercial, oficina culinária, jardim espiritual, treinamento, castelo)
- [ ] Lojas distribuídas, cada uma com caminho claro e placa
- [ ] Seis portais com visual, animação e nome próprios, longe uns dos outros
- [ ] Transição gradual de bioma em cada estrada (tiles de transição, não só tingimento)
- [ ] Decoração em camadas (pontes, lagos, cercas, bancos, estátuas, segredos)

## MARCO 4 — Minimapa e mapa
- [ ] Sistema de marcadores único (`MapMarker`): cada loja, portal e NPC registra o próprio marcador, que acompanha o nó automaticamente
- [ ] Minimapa no canto superior direito, com moldura oriental, zoom, direção do jogador e seta do objetivo
- [ ] Tela de mapa refeita: sem rótulos sobrepostos, seleção de destino integrada ao minimapa

## MARCO 5 — Utensílios
- [ ] Catálogo de 8 utensílios + 6 variantes, com dano, velocidade, alcance, efeito, preço, raridade, ícone e sprite
- [ ] Identidade de golpe por utensílio (colher rápida, frigideira pesada, concha circular, batedor em rajadas, rolo com atordoamento)
- [ ] Oficina de utensílios: cenário, catálogo com prévia e comparação, comprar, vender, equipar, melhorar
- [ ] Migração de saves: espadas viram o utensílio equivalente

## MARCO 6 — Interface
- [ ] HUD nova (vida, energia, utensílio, poções, objetivo, minimapa) sem sobreposição em 720p e 1080p
- [ ] Inventário com as categorias novas
- [ ] Menu principal com fundo animado e botão "Carregar"
- [ ] Moeda exibida como Ryō

## MARCO 7 — Dungeons
- [ ] Revisão do Pântano, Cidade Fantasma e Céu: objetivos claros na HUD ("Ative as três comportas 1/3"), tutorial curto, checkpoint, saída
- [ ] Floresta (ilusões), Castelo (infiltração), Coliseu (chefe final)
- [ ] Chefes da equipe reconstruídos em escala de chefe (64–140 px)

## MARCO 8 — Polimento
- [ ] Efeitos em pixel art por região
- [ ] Áudio (original ou licenciado). Hoje o projeto não tem nenhum arquivo de som.
- [ ] Balanceamento

## MARCO 9 — Testes finais
- [ ] Campanha completa, salvamento, colisões, interface, desempenho, exportação Windows

---

## Próximo passo imediato
Marco 1, item restante:
1. Re-pixelizador único, testado primeiro num conjunto pequeno de objetos do HUB e comparado lado a lado com os atuais.
2. Prova de conceito de `TileMapLayer` com autotiling.
