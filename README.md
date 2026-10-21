# Tonkatsu no Kami

RPG de ação e aventura 2D em pixel art, com fantasia japonesa e culinária.

## Como executar

1. Instale o **Godot 4.3 estável**, edição padrão.
2. No gerenciador de projetos, clique em **Importar** e selecione `project.godot`.
3. Aguarde a importação dos recursos e pressione **F5** para jogar.

## Controles

| Ação | Tecla |
| --- | --- |
| Andar | WASD ou setas |
| Correr | Shift |
| Esquivar | Espaço |
| Atacar | J ou clique esquerdo; segure para carregar |
| Habilidade | K ou clique direito |
| Trocar habilidade | Q |
| Interagir / avançar diálogo | E |
| Inventário | I |
| Mapa | M |
| Pausa / pular introdução | Esc |

Também há suporte a gamepad.

## Estrutura

- `scenes/`, `scripts/`, `autoload/`: cenas e lógica do jogo.
- `assets/`: arte, áudio e demais recursos.
- `resources/`, `shaders/`: recursos Godot e shaders.
- `tests/`: testes; execute a cena `tests/TestRunner.tscn` no editor.
- `tools/`: ferramentas de produção de recursos.
- `docs/` e documentos na raiz: design, arquitetura e progresso.

Consulte `COMO_ABRIR.txt` para mais instruções e `DEVELOPMENT_PROGRESS.md` para o progresso do projeto.
