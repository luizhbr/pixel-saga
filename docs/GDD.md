# PIXEL SAGA — GDD v0.1

**Título provisório:** Pixel Saga: Trio da Tempestade

**Pitch:** Três heróis improváveis atravessam um mundo onde cidade cyberpunk, vila japonesa e pântano encantado se sobrepõem, cada um usando sua habilidade única para resolver puzzles e sobreviver.

## Core Loop
1. **Mover** — andar, pular (coyote time + input buffer), dash
2. **Trocar personagem** — alterne entre os 3 heróis em tempo real; cada um abre caminhos distintos
3. **Resolver** — puzzles de troca (plataforma que só um personagem ativa, inimigo que só um derrota)
4. **Coletar** — cristais espalhados pelo nível (score + desbloqueio)

## Personagens

| # | Nome | Personalidade | Habilidade Única |
|---|------|--------------|-----------------|
| 1 | **Mossy** (criatura amarela redonda, planta verde na cabeça, corpo azul) | Curioso, ingênuo, fala com plantas | **Florir** — faz brotar cipós de plataformas, criando pontes temporárias |
| 2 | **Capitão Polo** (urso polar, uniforme e chapéu azul) | Valente, formal, líder nato | **Escudo Gélido** — congela inimigos próximos e cria blocos de gelo para pisar |
| 3 | **Garrax** (gato laranja, tapa-olho, chapéu e botas azuis) | Audaz, sarcástico, aventureiro | **Dash Sombrio** — avança em rajada rápida, atravessa portas trancadas e espinhos |

## Mood Visual
Pixel art 16-bit SNES limpo, alto contraste, paleta limitada, sem anti-aliasing — cyberpunk neon colidindo com a calma de uma vila japonesa ao pôr do sol e o mistério de um pântano de rosto gigante.

## Níveis
**5 níveis** (lineares com ramificações de puzzle):
1. Beco Cyberpunk Abandonado (tutorial de movimento + troca)
2. Vila Japonesa ao Pôr do Sol (puzzles de troca + primeiro chef)
3. Pântano do Rosto Gigante (sobrevivência + plataforma precisa)
4. Beco Neon com Helicóptero (perseguição vertical + dash aéreo)
5. Rua Chuvosa Neon (chef final + fusão das 3 habilidades)

## Assets Mínimos
- **Characters:** 3 sprite sheets (idle/walk/jump/abilidade) 48×48
- **Tiles:** tileset 16×16 (grama, pedra, metal, madeira, gelo, cipó)
- **Backgrounds:** 3 cenas parallax (cyberpunk, vila, pântano)
- **UI:** menu principal, seleção de personagem, HUD (vida + cristais)
- **SFX:** pulo, hit, dash, troca de personagem, coletar cristal
- **VFX:** partículas de gelo, cipó, dash, screen shake