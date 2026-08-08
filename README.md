# Pixel Saga: Trio da Tempestade
## Protótipo jogável — Godot 4.3+ (GDScript)

### Como rodar (PC)
1. Baixar Godot 4.3+ (Standard): https://godotengine.org/download
2. Abrir Godot → Import → selecionar `project.godot`
3. Pressionar F5 para jogar

### Como jogar no celular (Android)

#### Opção A — HTML5 no navegador (recomendado)
1. No PC: abrir projeto no Godot → Project → Export → HTML5 → Export
2. Hospedar a pasta `export/html5/` no Vercel
3. Abrir o link no Chrome do celular
4. Os botões touch aparecem automaticamente

#### Opção B — APK nativo
1. Instalar Android export templates no Godot
2. Configurar JDK + Android SDK
3. Project → Export → Android → Export → `.apk`
4. Transferir e instalar no celular

### Controles (teclado)
- **Setas / A,D** — Mover
- **Espaço / W** — Pular
- **Q / Shift** — Trocar personagem
- **E / Enter** — Habilidade
  - Mossy: Florir (cipós)
  - Polo: Escudo Gélido (bloqueia dano)
  - Garrax: Dash Sombrio (avança rápido)

### Controles (touch)
- **◀ ▶** (canto inferior esquerdo) — Mover
- **⬆** (canto inferior direito) — Pular
- **⟳** (direita) — Trocar personagem
- **✦** (direita) — Habilidade
- Botões aparecem automaticamente em dispositivos touch

### Estrutura
\`\`\`
pixel-saga/
├── project.godot
├── export_presets.cfg        # HTML5 + PWA
├── scenes/
│   ├── MainMenu.tscn         # Menu principal
│   ├── Level1.tscn           # Beco Cyberpunk
│   ├── Level2.tscn           # Vila Japonesa
│   └── Level3.tscn           # Pântano
├── scripts/
│   ├── autoload/
│   │   ├── GameManager.gd     # Singleton: vida, chars, cristais
│   │   └── AudioManager.gd    # SFX procedural
│   ├── LevelBase.gd          # Base para todos os níveis
│   ├── Level1/2/3.gd         # Configuração de cada nível
│   ├── Player.gd             # Player + 3 personagens
│   ├── Enemy.gd             # Inimigo patrulha
│   ├── TouchControls.gd     # Botões virtuais mobile
│   ├── SmoothCamera.gd      # Câmera suave + shake
│   ├── Checkpoint.gd        # Checkpoint
│   ├── Crystal.gd           # Coletável
│   ├── HUD.gd               # Interface
│   └── MainMenu.gd          # Menu + seleção
├── assets/
│   ├── characters/          # Sprite sheets 48x48
│   ├── tiles/               # Tileset 16x16
│   └── backgrounds/         # 3 backgrounds parallax
└── docs/
    └── GDD.md
\`\`\`