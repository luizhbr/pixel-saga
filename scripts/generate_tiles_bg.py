"""
Pixel Saga — Tileset & Background Generator
ETAPA 3: Tileset 16x16 + 3 Parallax Backgrounds

Tileset: 6 terrain types x variants = grid sheet
Backgrounds: 3 layers each (far, mid, near) for parallax
Style: SNES 16-bit, limited palette, no anti-aliasing
"""

from PIL import Image
import os
import math
import random

random.seed(42)

# ============================================================
# TILESET — 16x16 tiles
# Grid: 8 cols x 6 rows = 48 tiles
# Row 0: Grass (solid, top, left, right, bottom, inner, slope_L, slope_R)
# Row 1: Stone (solid, top, left, right, bottom, inner, crack, mossy)
# Row 2: Metal (solid, top, plate, rivet, panel, warning, vent, edge)
# Row 3: Wood (solid, plank, top, side, nail, crack, platform_L, platform_R)
# Row 4: Ice (solid, top, crack, shiny, corner, edge, slippery, crystal)
# Row 5: Vine (bridge, vine_L, vine_R, vine_mid, hang, leaf, flower, root)
# ============================================================

TILE = 16
COLS = 8
ROWS = 6
SHEET_W = COLS * TILE  # 128
SHEET_H = ROWS * TILE  # 96

TILE_PALETTES = {
    'grass': {
        'main': (90, 160, 60, 255),
        'dark': (60, 120, 40, 255),
        'light': (120, 200, 80, 255),
        'dirt': (120, 80, 50, 255),
        'dirt_dk': (90, 60, 35, 255),
        'detail': (70, 130, 45, 255),
    },
    'stone': {
        'main': (140, 140, 150, 255),
        'dark': (100, 100, 110, 255),
        'light': (170, 170, 180, 255),
        'crack': (70, 70, 80, 255),
        'moss': (80, 140, 60, 255),
    },
    'metal': {
        'main': (90, 95, 105, 255),
        'dark': (60, 65, 75, 255),
        'light': (130, 135, 145, 255),
        'rust': (150, 90, 50, 255),
        'warn': (220, 180, 30, 255),
        'vent': (50, 55, 65, 255),
    },
    'wood': {
        'main': (160, 110, 60, 255),
        'dark': (120, 80, 40, 255),
        'light': (190, 140, 80, 255),
        'nail': (80, 50, 30, 255),
        'grain': (140, 95, 50, 255),
    },
    'ice': {
        'main': (160, 210, 255, 255),
        'dark': (110, 170, 230, 255),
        'light': (200, 240, 255, 255),
        'crack': (80, 130, 200, 255),
        'crystal': (140, 200, 250, 255),
    },
    'vine': {
        'main': (60, 130, 50, 255),
        'dark': (40, 100, 35, 255),
        'light': (90, 180, 70, 255),
        'stem': (50, 80, 40, 255),
        'flower': (220, 100, 180, 255),
    },
}

def fill_tile(pixels, tx, ty, color):
    """Fill entire 16x16 tile area."""
    for y in range(16):
        for x in range(16):
            pixels[tx + x, ty + y] = color

def tpx(pixels, tx, ty, x, y, color):
    """Set pixel relative to tile origin."""
    if 0 <= x < 16 and 0 <= y < 16:
        pixels[tx + x, ty + y] = color

def tile_rect(pixels, tx, ty, x1, y1, w, h, color):
    for y in range(y1, y1 + h):
        for x in range(x1, x1 + w):
            tpx(pixels, tx, ty, x, y, color)

def tile_noise(pixels, tx, ty, base_color, variation=20, density=0.3):
    """Add noise texture to tile."""
    for y in range(16):
        for x in range(16):
            if random.random() < density:
                r = max(0, min(255, base_color[0] + random.randint(-variation, variation)))
                g = max(0, min(255, base_color[1] + random.randint(-variation, variation)))
                b = max(0, min(255, base_color[2] + random.randint(-variation, variation)))
                tpx(pixels, tx, ty, x, y, (r, g, b, 255))

def add_outline(pixels, tx, ty, color):
    """Add dark outline on tile borders."""
    for i in range(16):
        tpx(pixels, tx, ty, 0, i, color)
        tpx(pixels, tx, ty, 15, i, color)
        tpx(pixels, tx, ty, i, 0, color)
        tpx(pixels, tx, ty, i, 15, color)

# ---- Grass tiles ----
def draw_grass(pixels, tx, ty, variant):
    p = TILE_PALETTES['grass']
    # Dirt base
    fill_tile(pixels, tx, ty, p['dirt'])
    tile_noise(pixels, tx, ty, p['dirt'], 15, 0.4)
    
    if variant == 0:  # Solid grass block
        tile_rect(pixels, tx, ty, 0, 0, 16, 6, p['main'])
        tile_noise(pixels, tx, ty, p['main'], 20, 0.3)
        # Grass blades
        for x in range(0, 16, 2):
            tpx(pixels, tx, ty, x, 0, p['light'])
            tpx(pixels, tx, ty, x + 1, 1, p['light'])
        # Dirt texture below
        for y in range(6, 16):
            if random.random() < 0.15:
                tpx(pixels, tx, ty, random.randint(0, 15), y, p['dirt_dk'])
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 1:  # Top edge (grass on top)
        tile_rect(pixels, tx, ty, 0, 0, 16, 4, p['main'])
        for x in range(0, 16, 2):
            tpx(pixels, tx, ty, x, 0, p['light'])
        # Transition line
        tile_rect(pixels, tx, ty, 0, 4, 16, 1, p['dark'])
        tile_noise(pixels, tx, ty, p['dirt'], 15, 0.3)
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 2:  # Left edge
        tile_rect(pixels, tx, ty, 0, 0, 16, 16, p['dirt'])
        tile_rect(pixels, tx, ty, 0, 0, 4, 16, p['main'])
        tile_noise(pixels, tx, ty, p['main'], 15, 0.3)
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 3:  # Right edge
        tile_rect(pixels, tx, ty, 0, 0, 16, 16, p['dirt'])
        tile_rect(pixels, tx, ty, 12, 0, 4, 16, p['main'])
        tile_noise(pixels, tx, ty, p['main'], 15, 0.3)
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 4:  # Bottom
        tile_rect(pixels, tx, ty, 0, 0, 16, 16, p['main'])
        tile_rect(pixels, tx, ty, 0, 12, 16, 4, p['dirt'])
        tile_noise(pixels, tx, ty, p['main'], 15, 0.3)
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 5:  # Inner (all dirt with grass top)
        fill_tile(pixels, tx, ty, p['dirt'])
        tile_noise(pixels, tx, ty, p['dirt'], 15, 0.4)
        tile_rect(pixels, tx, ty, 0, 0, 16, 2, p['main'])
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 6:  # Slope left
        fill_tile(pixels, tx, ty, p['dirt'])
        for y in range(16):
            w = max(0, 16 - y)
            tile_rect(pixels, tx, ty, 0, y, w, 1, p['main'])
        add_outline(pixels, tx, ty, p['dark'])
    
    elif variant == 7:  # Slope right
        fill_tile(pixels, tx, ty, p['dirt'])
        for y in range(16):
            w = max(0, 16 - y)
            tile_rect(pixels, tx, ty, 16 - w, y, w, 1, p['main'])
        add_outline(pixels, tx, ty, p['dark'])

# ---- Stone tiles ----
def draw_stone(pixels, tx, ty, variant):
    p = TILE_PALETTES['stone']
    fill_tile(pixels, tx, ty, p['main'])
    tile_noise(pixels, tx, ty, p['main'], 15, 0.35)
    
    if variant == 0:  # Solid
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 1:  # Top
        tile_rect(pixels, tx, ty, 0, 0, 16, 3, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 2:  # Left
        tile_rect(pixels, tx, ty, 0, 0, 3, 16, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 3:  # Right
        tile_rect(pixels, tx, ty, 13, 0, 3, 16, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 4:  # Bottom
        tile_rect(pixels, tx, ty, 0, 13, 16, 3, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 5:  # Inner
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 6:  # Crack
        # Draw crack
        tpx(pixels, tx, ty, 5, 2, p['crack'])
        tpx(pixels, tx, ty, 6, 3, p['crack'])
        tpx(pixels, tx, ty, 7, 4, p['crack'])
        tpx(pixels, tx, ty, 7, 5, p['crack'])
        tpx(pixels, tx, ty, 8, 6, p['crack'])
        tpx(pixels, tx, ty, 8, 7, p['crack'])
        tpx(pixels, tx, ty, 9, 8, p['crack'])
        tpx(pixels, tx, ty, 9, 9, p['crack'])
        tpx(pixels, tx, ty, 10, 10, p['crack'])
        tpx(pixels, tx, ty, 10, 11, p['crack'])
        tpx(pixels, tx, ty, 11, 12, p['crack'])
        tpx(pixels, tx, ty, 11, 13, p['crack'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 7:  # Mossy
        # Moss patches
        for _ in range(8):
            mx = random.randint(0, 12)
            my = random.randint(0, 12)
            tpx(pixels, tx, ty, mx, my, p['moss'])
            tpx(pixels, tx, ty, mx + 1, my, p['moss'])
            tpx(pixels, tx, ty, mx, my + 1, p['moss'])
        add_outline(pixels, tx, ty, p['dark'])

# ---- Metal tiles ----
def draw_metal(pixels, tx, ty, variant):
    p = TILE_PALETTES['metal']
    fill_tile(pixels, tx, ty, p['main'])
    tile_noise(pixels, tx, ty, p['main'], 8, 0.2)
    
    if variant == 0:  # Solid plate
        tile_rect(pixels, tx, ty, 0, 0, 16, 1, p['light'])
        tile_rect(pixels, tx, ty, 0, 15, 16, 1, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 1:  # Top
        tile_rect(pixels, tx, ty, 0, 0, 16, 2, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 2:  # Plate with seam
        tile_rect(pixels, tx, ty, 0, 7, 16, 1, p['dark'])
        tile_rect(pixels, tx, ty, 0, 8, 16, 1, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 3:  # Rivets
        for rx, ry in [(2, 2), (13, 2), (2, 13), (13, 13)]:
            tpx(pixels, tx, ty, rx, ry, p['light'])
            tpx(pixels, tx, ty, rx + 1, ry, p['dark'])
            tpx(pixels, tx, ty, rx, ry + 1, p['dark'])
            tpx(pixels, tx, ty, rx + 1, ry + 1, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 4:  # Panel
        tile_rect(pixels, tx, ty, 2, 2, 12, 12, p['dark'])
        tile_rect(pixels, tx, ty, 3, 3, 10, 10, p['main'])
        tile_noise(pixels, tx, ty, p['main'], 8, 0.15)
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 5:  # Warning stripe
        for x in range(0, 16, 4):
            tile_rect(pixels, tx, ty, x, 6, 2, 4, p['warn'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 6:  # Vent
        tile_rect(pixels, tx, ty, 3, 3, 10, 10, p['vent'])
        for y in range(4, 14, 2):
            tile_rect(pixels, tx, ty, 4, y, 8, 1, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 7:  # Edge
        tile_rect(pixels, tx, ty, 0, 0, 8, 16, p['main'])
        tile_rect(pixels, tx, ty, 8, 0, 8, 16, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])

# ---- Wood tiles ----
def draw_wood(pixels, tx, ty, variant):
    p = TILE_PALETTES['wood']
    fill_tile(pixels, tx, ty, p['main'])
    
    if variant == 0:  # Solid plank
        # Wood grain
        for y in range(16):
            if y % 4 == 0:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['dark'])
        tile_noise(pixels, tx, ty, p['main'], 12, 0.2)
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 1:  # Plank with gap
        fill_tile(pixels, tx, ty, p['dark'])
        tile_rect(pixels, tx, ty, 0, 0, 16, 7, p['main'])
        tile_rect(pixels, tx, ty, 0, 9, 16, 7, p['main'])
        for y in range(16):
            if y % 4 == 0 and y < 7:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['grain'])
            if y % 4 == 0 and y > 8:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['grain'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 2:  # Top
        tile_rect(pixels, tx, ty, 0, 0, 16, 2, p['light'])
        for y in range(16):
            if y % 4 == 0:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['grain'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 3:  # Side
        tile_rect(pixels, tx, ty, 0, 0, 2, 16, p['light'])
        tile_rect(pixels, tx, ty, 14, 0, 2, 16, p['dark'])
        for y in range(16):
            if y % 4 == 0:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['grain'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 4:  # Nail
        fill_tile(pixels, tx, ty, p['main'])
        for y in range(16):
            if y % 4 == 0:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['grain'])
        # Nails at corners
        for nx, ny in [(2, 2), (13, 2), (2, 13), (13, 13)]:
            tpx(pixels, tx, ty, nx, ny, p['nail'])
            tpx(pixels, tx, ty, nx, ny + 1, p['nail'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 5:  # Crack
        for y in range(16):
            if y % 4 == 0:
                tile_rect(pixels, tx, ty, 0, y, 16, 1, p['grain'])
        # Crack
        for i in range(8):
            tpx(pixels, tx, ty, 3 + i, i * 2, p['nail'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 6:  # Platform left
        fill_tile(pixels, tx, ty, (0, 0, 0, 0))
        tile_rect(pixels, tx, ty, 0, 8, 16, 4, p['main'])
        tile_rect(pixels, tx, ty, 0, 8, 16, 1, p['light'])
        tile_rect(pixels, tx, ty, 0, 11, 16, 1, p['dark'])
        # Support
        tile_rect(pixels, tx, ty, 1, 12, 2, 3, p['dark'])
        tpx(pixels, tx, ty, 0, 8, p['dark'])
        tpx(pixels, tx, ty, 0, 12, p['dark'])
    elif variant == 7:  # Platform right
        fill_tile(pixels, tx, ty, (0, 0, 0, 0))
        tile_rect(pixels, tx, ty, 0, 8, 16, 4, p['main'])
        tile_rect(pixels, tx, ty, 0, 8, 16, 1, p['light'])
        tile_rect(pixels, tx, ty, 0, 11, 16, 1, p['dark'])
        tile_rect(pixels, tx, ty, 13, 12, 2, 3, p['dark'])
        tpx(pixels, tx, ty, 15, 8, p['dark'])
        tpx(pixels, tx, ty, 15, 12, p['dark'])

# ---- Ice tiles ----
def draw_ice(pixels, tx, ty, variant):
    p = TILE_PALETTES['ice']
    fill_tile(pixels, tx, ty, p['main'])
    tile_noise(pixels, tx, ty, p['main'], 15, 0.25)
    
    if variant == 0:  # Solid
        tile_rect(pixels, tx, ty, 0, 0, 16, 1, p['light'])
        tile_rect(pixels, tx, ty, 0, 15, 16, 1, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 1:  # Top
        tile_rect(pixels, tx, ty, 0, 0, 16, 3, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 2:  # Crack
        for i in range(0, 16, 3):
            tpx(pixels, tx, ty, i, i % 16, p['crack'])
            tpx(pixels, tx, ty, i + 1, (i + 1) % 16, p['crack'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 3:  # Shiny
        # Sparkles
        for _ in range(5):
            sx = random.randint(2, 13)
            sy = random.randint(2, 13)
            tpx(pixels, tx, ty, sx, sy, p['light'])
            tpx(pixels, tx, ty, sx + 1, sy, p['light'])
            tpx(pixels, tx, ty, sx, sy + 1, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 4:  # Corner
        tile_rect(pixels, tx, ty, 0, 0, 16, 4, p['light'])
        tile_rect(pixels, tx, ty, 0, 0, 4, 16, p['light'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 5:  # Edge
        tile_rect(pixels, tx, ty, 0, 0, 8, 16, p['main'])
        tile_rect(pixels, tx, ty, 8, 0, 8, 16, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 6:  # Slippery (smooth, less noise)
        fill_tile(pixels, tx, ty, p['light'])
        tile_rect(pixels, tx, ty, 0, 14, 16, 2, p['dark'])
        add_outline(pixels, tx, ty, p['dark'])
    elif variant == 7:  # Crystal
        fill_tile(pixels, tx, ty, (0, 0, 0, 0))
        # Crystal shape
        cx, cy = 8, 8
        tpx(pixels, tx, ty, cx, cy - 4, p['crystal'])
        tpx(pixels, tx, ty, cx - 1, cy - 3, p['crystal'])
        tpx(pixels, tx, ty, cx + 1, cy - 3, p['crystal'])
        tpx(pixels, tx, ty, cx - 2, cy - 2, p['crystal'])
        tpx(pixels, tx, ty, cx + 2, cy - 2, p['crystal'])
        tpx(pixels, tx, ty, cx - 3, cy - 1, p['crystal'])
        tile_rect(pixels, tx, ty, cx - 3, cy, 7, 3, p['crystal'])
        tpx(pixels, tx, ty, cx - 2, cy + 3, p['crystal'])
        tpx(pixels, tx, ty, cx + 2, cy + 3, p['crystal'])
        # Shine
        tpx(pixels, tx, ty, cx - 1, cy - 2, p['light'])

# ---- Vine tiles ----
def draw_vine(pixels, tx, ty, variant):
    p = TILE_PALETTES['vine']
    fill_tile(pixels, tx, ty, (0, 0, 0, 0))
    
    if variant == 0:  # Bridge (vine platform)
        tile_rect(pixels, tx, ty, 0, 8, 16, 4, p['stem'])
        tile_rect(pixels, tx, ty, 0, 8, 16, 1, p['main'])
        # Leaves on top
        for x in range(0, 16, 3):
            tpx(pixels, tx, ty, x, 7, p['main'])
            tpx(pixels, tx, ty, x + 1, 7, p['light'])
        # Hanging vines
        for x in range(2, 16, 4):
            tpx(pixels, tx, ty, x, 12, p['stem'])
            tpx(pixels, tx, ty, x, 13, p['stem'])
            tpx(pixels, tx, ty, x, 14, p['light'])
    elif variant == 1:  # Vine left end
        tile_rect(pixels, tx, ty, 0, 8, 10, 4, p['stem'])
        tile_rect(pixels, tx, ty, 0, 8, 10, 1, p['main'])
        tpx(pixels, tx, ty, 0, 9, p['dark'])
        tpx(pixels, tx, ty, 1, 12, p['stem'])
        tpx(pixels, tx, ty, 1, 13, p['light'])
    elif variant == 2:  # Vine right end
        tile_rect(pixels, tx, ty, 6, 8, 10, 4, p['stem'])
        tile_rect(pixels, tx, ty, 6, 8, 10, 1, p['main'])
        tpx(pixels, tx, ty, 15, 9, p['dark'])
        tpx(pixels, tx, ty, 14, 12, p['stem'])
        tpx(pixels, tx, ty, 14, 13, p['light'])
    elif variant == 3:  # Vine middle
        tile_rect(pixels, tx, ty, 0, 8, 16, 4, p['stem'])
        tile_rect(pixels, tx, ty, 0, 8, 16, 1, p['main'])
    elif variant == 4:  # Hanging vine
        for y in range(16):
            tpx(pixels, tx, ty, 8, y, p['stem'])
            if y % 3 == 0:
                tpx(pixels, tx, ty, 7, y, p['light'])
                tpx(pixels, tx, ty, 9, y, p['light'])
    elif variant == 5:  # Leaf cluster
        for _ in range(6):
            lx = random.randint(2, 13)
            ly = random.randint(2, 13)
            tpx(pixels, tx, ty, lx, ly, p['main'])
            tpx(pixels, tx, ty, lx + 1, ly, p['light'])
            tpx(pixels, tx, ty, lx, ly + 1, p['dark'])
    elif variant == 6:  # Flower
        tpx(pixels, tx, ty, 8, 4, p['flower'])
        tpx(pixels, tx, ty, 7, 5, p['flower'])
        tpx(pixels, tx, ty, 9, 5, p['flower'])
        tpx(pixels, tx, ty, 8, 5, p['light'])
        tpx(pixels, tx, ty, 8, 6, p['flower'])
        tpx(pixels, tx, ty, 8, 7, p['stem'])
        tpx(pixels, tx, ty, 8, 8, p['stem'])
        tpx(pixels, tx, ty, 7, 9, p['main'])
        tpx(pixels, tx, ty, 9, 9, p['main'])
    elif variant == 7:  # Root
        for y in range(16):
            w = max(1, 4 - y // 4)
            tile_rect(pixels, tx, ty, 8 - w, y, w * 2, 1, p['stem'])
            if y % 3 == 0:
                tpx(pixels, tx, ty, 8 - w - 1, y, p['dark'])
                tpx(pixels, tx, ty, 8 + w, y, p['dark'])

# ============================================================
# Generate Tileset
# ============================================================
sheet = Image.new('RGBA', (SHEET_W, SHEET_H), (0, 0, 0, 0))
pixels = sheet.load()

drawers = [draw_grass, draw_stone, draw_metal, draw_wood, draw_ice, draw_vine]
for row, draw_func in enumerate(drawers):
    for col in range(8):
        ty = row * TILE
        tx = col * TILE
        draw_func(pixels, tx, ty, col)

tiles_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'tiles')
tiles_dir = os.path.abspath(tiles_dir)
os.makedirs(tiles_dir, exist_ok=True)

tileset_path = os.path.join(tiles_dir, 'tileset.png')
sheet.save(tileset_path)
print(f"Tileset saved: {tileset_path} ({sheet.size})")

# Preview (4x)
big = sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST)
big.save(os.path.join(tiles_dir, 'tileset_preview.png'))
print(f"Tileset preview saved (4x)")

# ============================================================
# BACKGROUNDS — Parallax layers
# Each background: 3 layers (far, mid, near)
# Size per layer: 256x192 (will tile/repeat in Godot)
# ============================================================

BG_W = 256
BG_H = 192

# ---- Background 1: Cyberpunk Alley ----
def draw_bg_cyberpunk():
    layers = []
    
    # Far: dark city skyline with neon glow
    far = Image.new('RGBA', (BG_W, BG_H), (15, 10, 30, 255))
    fp = far.load()
    # Buildings
    for bx in range(0, BG_W, 20):
        bh = random.randint(60, 140)
        bw = random.randint(15, 25)
        for y in range(BG_H - bh, BG_H):
            for x in range(bx, min(bx + bw, BG_W)):
                fp[x, y] = (30, 20, 50, 255)
        # Windows
        for wy in range(BG_H - bh + 5, BG_H - 5, 8):
            for wx in range(bx + 2, bx + bw - 2, 5):
                if random.random() < 0.4 and wx + 1 < BG_W:
                    color = random.choice([
                        (255, 200, 50, 255),    # Yellow
                        (255, 100, 200, 255),   # Pink
                        (100, 200, 255, 255),   # Cyan
                    ])
                    fp[wx, wy] = color
                    fp[wx + 1, wy] = color
    # Sky gradient
    for y in range(BG_H):
        fade = y / BG_H
        r = int(15 + fade * 20)
        g = int(10 + fade * 10)
        b = int(30 + fade * 30)
        for x in range(BG_W):
            if fp[x, y] == (15, 10, 30, 255):
                fp[x, y] = (r, g, b, 255)
    layers.append(('far', far))
    
    # Mid: buildings with neon signs
    mid = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    mp = mid.load()
    for bx in range(0, BG_W, 30):
        bh = random.randint(100, 170)
        bw = random.randint(20, 30)
        for y in range(BG_H - bh, BG_H):
            for x in range(bx, min(bx + bw, BG_W)):
                if y < BG_H - 5:
                    mp[x, y] = (25, 20, 40, 255)
        # Neon signs (vertical)
        if random.random() < 0.5:
            sign_x = bx + 3
            sign_y = BG_H - bh + 10
            neon_color = random.choice([
                (255, 50, 150, 255),    # Pink
                (50, 200, 255, 255),    # Cyan
                (255, 200, 50, 255),    # Yellow
                (150, 50, 255, 255),    # Purple
            ])
            for sy in range(max(0, sign_y), min(sign_y + 20, BG_H)):
                if sign_x < BG_W:
                    mp[sign_x, sy] = neon_color
                if sign_x + 1 < BG_W:
                    mp[sign_x + 1, sy] = neon_color
                # Glow
                if sign_x > 0:
                    mp[sign_x - 1, sy] = tuple(min(255, c // 2) for c in neon_color[:3]) + (255,)
    layers.append(('mid', mid))
    
    # Near: pipes, cables, foreground detail
    near = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    np = near.load()
    # Pipes
    for y in [20, 60, 120, 170]:
        for x in range(BG_W):
            for dy in range(4):
                if y + dy < BG_H:
                    colors = [(50, 45, 55, 255), (70, 65, 75, 255), (50, 45, 55, 255), (35, 30, 40, 255)]
                    np[x, y + dy] = colors[dy]
    # Neon cables
    for y in [40, 100, 150]:
        cable_color = random.choice([
            (255, 50, 150, 255),
            (50, 200, 255, 255),
        ])
        for x in range(0, BG_W, 3):
            if y + 1 < BG_H:
                np[x, y] = cable_color
                np[x, y + 1] = cable_color
    layers.append(('near', near))
    
    return layers

# ---- Background 2: Japanese Village at Sunset ----
def draw_bg_japanese_village():
    layers = []
    
    # Far: sunset sky gradient + mountains
    far = Image.new('RGBA', (BG_W, BG_H), (255, 150, 80, 255))
    fp = far.load()
    # Sky gradient (sunset)
    for y in range(BG_H):
        fade = y / BG_H
        if fade < 0.3:
            r = int(255 - fade * 50)
            g = int(180 - fade * 80)
            b = int(100 + fade * 50)
        elif fade < 0.6:
            r = int(255 - fade * 30)
            g = int(140 - fade * 40)
            b = int(120 + fade * 30)
        else:
            r = int(200 - fade * 50)
            g = int(80 - fade * 20)
            b = int(130 - fade * 20)
        for x in range(BG_W):
            fp[x, y] = (r, g, b, 255)
    # Sun
    for y in range(50):
        for x in range(50):
            if x * x + y * y <= 25 * 25:
                px_x = 180 + x
                px_y = 40 + y
                if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                    fp[px_x, px_y] = (255, 220, 100, 255)
                    if x * x + y * y <= 20 * 20:
                        fp[px_x, px_y] = (255, 240, 150, 255)
    # Mountains (far)
    for mx in range(0, BG_W, 60):
        mh = random.randint(40, 80)
        for dx in range(50):
            h = int(mh * (1 - abs(dx - 25) / 25.0))
            for y in range(max(0, BG_H - h), BG_H):
                px_x = mx + dx
                if 0 <= px_x < BG_W:
                    fp[px_x, y] = (80, 60, 100, 255)
    layers.append(('far', far))
    
    # Mid: Japanese houses + cherry trees
    mid = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    mp = mid.load()
    for hx in range(0, BG_W, 40):
        # House base
        house_h = random.randint(40, 60)
        house_w = 35
        for y in range(BG_H - house_h, BG_H):
            for x in range(hx, min(hx + house_w, BG_W)):
                mp[x, y] = (60, 50, 45, 255)
        # Roof (curved japanese style)
        roof_y = BG_H - house_h
        for rx in range(house_w + 4):
            ry = roof_y - 5 + int(3 * math.sin(rx / 5.0))
            for dy in range(6):
                px_x = hx - 2 + rx
                px_y = ry + dy
                if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                    mp[px_x, px_y] = (40, 30, 35, 255)
        # Windows (warm light)
        for wy in range(BG_H - house_h + 10, BG_H - 10, 12):
            for wx in range(hx + 4, hx + house_w - 4, 10):
                if wx + 1 < BG_W and wy + 1 < BG_H:
                    mp[wx, wy] = (255, 200, 100, 255)
                    mp[wx + 1, wy] = (255, 200, 100, 255)
                    mp[wx, wy + 1] = (255, 220, 120, 255)
                    mp[wx + 1, wy + 1] = (255, 220, 120, 255)
    # Cherry blossom tree
    for tx_pos in [20, 120, 200]:
        # Trunk
        for ty in range(BG_H - 50, BG_H):
            if tx_pos < BG_W:
                mp[tx_pos, ty] = (80, 50, 40, 255)
            if tx_pos + 1 < BG_W:
                mp[tx_pos + 1, ty] = (60, 40, 30, 255)
        # Blossoms
        for _ in range(30):
            bx = tx_pos + random.randint(-8, 8)
            by = BG_H - 50 + random.randint(-10, 5)
            if 0 <= bx < BG_W and 0 <= by < BG_H:
                mp[bx, by] = (255, 180, 200, 255)
                if bx + 1 < BG_W:
                    mp[bx + 1, by] = (255, 200, 210, 255)
    layers.append(('mid', mid))
    
    # Near: lanterns + fence
    near = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    npp = near.load()
    # Fence
    for fx in range(0, BG_W - 1, 8):
        for fy in range(BG_H - 20, BG_H):
            npp[fx, fy] = (90, 60, 45, 255)
            npp[fx + 1, fy] = (70, 50, 35, 255)
    # Top fence rail
    for fx in range(BG_W):
        npp[fx, BG_H - 20] = (100, 70, 50, 255)
        npp[fx, BG_H - 19] = (80, 55, 40, 255)
    # Lanterns
    for lx in range(20, BG_W, 50):
        ly = BG_H - 40
        # Lantern body
        for dy in range(12):
            for dx in range(-3, 4):
                px_x = lx + dx
                px_y = ly + dy
                if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                    npp[px_x, px_y] = (220, 80, 60, 255)
                    if dx == 0 and dy < 6:
                        npp[px_x, px_y] = (255, 150, 100, 255)
        # Top/bottom
        if 0 <= lx < BG_W:
            if ly - 1 >= 0:
                npp[lx, ly - 1] = (40, 30, 30, 255)
            if ly + 12 < BG_H:
                npp[lx, ly + 12] = (40, 30, 30, 255)
    layers.append(('near', near))
    
    return layers

# ---- Background 3: Swamp/Fantasy with Giant Face ----
def draw_bg_swamp():
    layers = []
    
    # Far: misty swamp sky + giant face rock
    far = Image.new('RGBA', (BG_W, BG_H), (40, 60, 50, 255))
    fp = far.load()
    # Sky gradient (eerie green/teal)
    for y in range(BG_H):
        fade = y / BG_H
        r = int(40 + fade * 20)
        g = int(60 + fade * 30)
        b = int(50 + fade * 40)
        for x in range(BG_W):
            fp[x, y] = (r, g, b, 255)
    # Mist
    for _ in range(20):
        mx = random.randint(0, BG_W)
        my = random.randint(0, BG_H // 2)
        for dx in range(30):
            for dy in range(10):
                if 0 <= mx + dx < BG_W and 0 <= my + dy < BG_H:
                    a = random.randint(20, 60)
                    old = fp[mx + dx, my + dy]
                    fp[mx + dx, my + dy] = (
                        min(255, old[0] + 40),
                        min(255, old[1] + 40),
                        min(255, old[2] + 40),
                        255
                    )
    # Giant face rock (center)
    fx, fy = 128, 80
    for angle in range(0, 360, 3):
        a = math.radians(angle)
        for r in range(35):
            ox = int(math.cos(a) * r)
            oy = int(math.sin(a) * r * 0.8)
            px_x = fx + ox
            px_y = fy + oy
            if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                shade = 80 + r
                fp[px_x, px_y] = (shade, shade + 10, shade - 10, 255)
    # Eyes (glowing)
    for ex, ey in [(-10, -5), (10, -5)]:
        for dx in range(-4, 5):
            for dy in range(-3, 4):
                if dx * dx + dy * dy <= 9:
                    px_x = fx + ex + dx
                    px_y = fy + ey + dy
                    if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                        fp[px_x, px_y] = (255, 250, 100, 255)
                        if dx * dx + dy * dy <= 4:
                            fp[px_x, px_y] = (255, 255, 200, 255)
    # Mouth
    for mx in range(-12, 13):
        my_off = 8 + int(2 * math.sin(mx / 4.0))
        for dy in range(2):
            px_x = fx + mx
            px_y = fy + my_off + dy
            if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                fp[px_x, px_y] = (40, 30, 20, 255)
    layers.append(('far', far))
    
    # Mid: dead trees + swamp huts
    mid = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    mp = mid.load()
    # Dead trees
    for tx_pos in [30, 80, 160, 210]:
        # Trunk
        for ty in range(BG_H - 80, BG_H):
            if tx_pos < BG_W:
                mp[tx_pos, ty] = (40, 30, 25, 255)
            if tx_pos + 1 < BG_W:
                mp[tx_pos + 1, ty] = (30, 20, 15, 255)
        # Branches
        for _ in range(5):
            bx = tx_pos + random.choice([-1, 1])
            by = BG_H - random.randint(50, 75)
            blen = random.randint(8, 15)
            bdir = random.choice([-1, 1])
            for i in range(blen):
                px_x = tx_pos + (i * bdir // 2)
                px_y = by - i // 2
                if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                    mp[px_x, px_y] = (40, 30, 25, 255)
    # Swamp hut
    for hx in [120]:
        for y in range(BG_H - 30, BG_H):
            for x in range(hx, min(hx + 25, BG_W)):
                mp[x, y] = (50, 40, 35, 255)
        # Roof
        for rx in range(29):
            ry = BG_H - 30 - int(8 * (1 - abs(rx - 14) / 14.0))
            for dy in range(4):
                px_x = hx - 2 + rx
                px_y = ry + dy
                if 0 <= px_x < BG_W and 0 <= px_y < BG_H:
                    mp[px_x, px_y] = (35, 25, 20, 255)
    layers.append(('mid', mid))
    
    # Near: water reflections + foreground plants
    near = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    npp = near.load()
    # Water at bottom
    for y in range(BG_H - 25, BG_H):
        for x in range(BG_W):
            r = 30 + random.randint(-5, 5)
            g = 50 + random.randint(-5, 5)
            b = 60 + random.randint(-5, 5)
            npp[x, y] = (r, g, b, 255)
        # Water highlights
        if y % 3 == 0:
            for x in range(0, BG_W, 8):
                npp[x, y] = (60, 80, 90, 255)
    # Reeds/grass
    for gx in range(0, BG_W - 1, 6):
        gh = random.randint(8, 15)
        for gy in range(gh):
            py = BG_H - 25 - gy
            if 0 <= py < BG_H:
                npp[gx, py] = (40, 70, 30, 255)
                npp[gx + 1, py] = (50, 90, 35, 255)
    # Fireflies
    for _ in range(10):
        fx = random.randint(0, BG_W - 2)
        fy = random.randint(20, BG_H - 30)
        npp[fx, fy] = (200, 255, 100, 255)
        npp[fx + 1, fy] = (150, 220, 80, 255)
    layers.append(('near', near))
    
    return layers

# ============================================================
# Generate Backgrounds
# ============================================================
bg_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'backgrounds')
bg_dir = os.path.abspath(bg_dir)
os.makedirs(bg_dir, exist_ok=True)

bg_generators = [
    ('cyberpunk', draw_bg_cyberpunk),
    ('japanese_village', draw_bg_japanese_village),
    ('swamp', draw_bg_swamp),
]

for name, gen_func in bg_generators:
    layers = gen_func()
    # Save individual layers
    for layer_name, layer_img in layers:
        fname = f'bg_{name}_{layer_name}.png'
        layer_img.save(os.path.join(bg_dir, fname))
        print(f"Saved: {fname} ({layer_img.size})")
    
    # Save composite preview
    composite = Image.new('RGBA', (BG_W, BG_H), (0, 0, 0, 0))
    for layer_name, layer_img in layers:
        composite = Image.alpha_composite(composite, layer_img)
    # Scale 2x for preview
    composite_big = composite.resize((BG_W * 2, BG_H * 2), Image.NEAREST)
    composite_big.save(os.path.join(bg_dir, f'bg_{name}_preview.png'))
    print(f"Saved: bg_{name}_preview.png ({composite_big.size})")

print("\n=== Tileset + Backgrounds generated! ===")