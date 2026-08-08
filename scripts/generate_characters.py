"""
Pixel Saga — Character Sprite Sheet Generator
Creates 48x48 pixel art sprite sheets for 3 characters.
Style: SNES 16-bit clean, limited palette, no anti-aliasing.
Each sheet: 4 rows (idle, walk, jump, ability) x 4 frames = 4x4 grid
Total sheet size: 192x192 (4 cols * 48px, 4 rows * 48px)
"""

from PIL import Image
import os

def create_sprite_sheet(name, palette, draw_func, output_path):
    """
    Create a 4x4 sprite sheet (192x192).
    Rows: idle(4 frames), walk(4 frames), jump(4 frames), ability(4 frames)
    Each cell: 48x48
    """
    sheet = Image.new('RGBA', (192, 192), (0, 0, 0, 0))
    
    # 4 animation rows
    for row, anim_name in enumerate(['idle', 'walk', 'jump', 'ability']):
        for frame in range(4):
            sprite = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
            pixels = sprite.load()
            draw_func(pixels, palette, anim_name, frame)
            sheet.paste(sprite, (frame * 48, row * 48))
    
    sheet.save(output_path)
    print(f"Saved: {output_path} ({sheet.size})")
    return sheet

def px(pixels, x, y, color):
    """Set a pixel with bounds checking."""
    if 0 <= x < 48 and 0 <= y < 48:
        if color is not None:
            r, g, b, a = color
            pixels[x, y] = (r, g, b, a)

def rect(pixels, x1, y1, w, h, color):
    """Fill a rectangle."""
    for y in range(y1, y1 + h):
        for x in range(x1, x1 + w):
            px(pixels, x, y, color)

def circle(pixels, cx, cy, r, color):
    """Fill a circle (approximate)."""
    for y in range(-r, r + 1):
        for x in range(-r, r + 1):
            if x * x + y * y <= r * r:
                px(pixels, cx + x, cy + y, color)

# ============================================================
# CHARACTER 1: MOSSY — Yellow round creature, green plant, blue body
# ============================================================
MOSSY_PALETTE = {
    'body_yellow': (255, 220, 60, 255),    # Main body
    'body_yellow_dk': (220, 180, 40, 255),  # Shadow
    'body_yellow_lt': (255, 240, 120, 255), # Highlight
    'blue_belly': (70, 130, 200, 255),      # Blue belly/body lower
    'blue_belly_dk': (50, 100, 170, 255),   # Blue shadow
    'plant_green': (80, 180, 70, 255),      # Plant leaves
    'plant_green_dk': (50, 140, 50, 255),   # Plant shadow
    'plant_green_lt': (120, 220, 100, 255), # Plant highlight
    'plant_stem': (60, 100, 50, 255),       # Stem
    'eye_w': (255, 255, 255, 255),           # Eye white
    'eye_b': (30, 30, 30, 255),              # Eye black
    'mouth': (180, 80, 80, 255),             # Mouth
    'outline': (40, 35, 20, 255),            # Dark outline
    'blush': (255, 150, 150, 255),           # Cheeks
}

def draw_mossy(pixels, pal, anim, frame):
    """Draw Mossy — round yellow body, blue lower body, green plant on head."""
    # Animation offsets
    bob = 0
    leg_offset = 0
    arm_offset = 0
    
    if anim == 'idle':
        bob = [0, -1, -1, 0][frame]
    elif anim == 'walk':
        bob = [0, -1, 0, -1][frame]
        leg_offset = [0, 2, 0, -2][frame]
        arm_offset = [0, -1, 0, 1][frame]
    elif anim == 'jump':
        bob = [-3, -4, -3, -2][frame]
        leg_offset = [-2, -3, -2, -1][frame]
    elif anim == 'ability':  # Florir — plant grows
        bob = [0, -1, -2, -1][frame]
    
    cx = 24
    
    # Body — round yellow upper (cx=24, cy=24+bob, r=14)
    body_cy = 26 + bob
    circle(pixels, cx, body_cy, 13, pal['body_yellow'])
    # Shadow lower right
    for y in range(-13, 14):
        for x in range(-13, 14):
            if x * x + y * y <= 13 * 13:
                if x > 4 and y > 2:
                    px(pixels, cx + x, body_cy + y, pal['body_yellow_dk'])
    # Highlight upper left
    for y in range(-13, 0):
        for x in range(-13, 4):
            if x * x + y * y <= 11 * 11 and x < 0 and y < -3:
                px(pixels, cx + x, body_cy + y, pal['body_yellow_lt'])
    
    # Blue belly (lower portion)
    for y in range(2, 13):
        for x in range(-10, 11):
            if x * x + y * y <= 13 * 13:
                px(pixels, cx + x, body_cy + y, pal['blue_belly'])
                if x > 3:
                    px(pixels, cx + x, body_cy + y, pal['blue_belly_dk'])
    
    # Outline
    for angle_step in range(64):
        import math
        a = angle_step * 6.283 / 64
        ox = int(math.cos(a) * 14)
        oy = int(math.sin(a) * 14)
        px(pixels, cx + ox, body_cy + oy, pal['outline'])
    
    # Eyes (two big round)
    eye_y = body_cy - 3
    # Left eye
    circle(pixels, cx - 5, eye_y, 3, pal['eye_w'])
    px(pixels, cx - 5, eye_y, pal['eye_b'])
    px(pixels, cx - 4, eye_y - 1, pal['eye_w'])
    # Right eye
    circle(pixels, cx + 5, eye_y, 3, pal['eye_w'])
    px(pixels, cx + 5, eye_y, pal['eye_b'])
    px(pixels, cx + 6, eye_y - 1, pal['eye_w'])
    
    # Blush
    px(pixels, cx - 8, body_cy + 1, pal['blush'])
    px(pixels, cx + 8, body_cy + 1, pal['blush'])
    
    # Mouth (small smile)
    px(pixels, cx - 2, body_cy + 3, pal['mouth'])
    px(pixels, cx, body_cy + 4, pal['mouth'])
    px(pixels, cx + 2, body_cy + 3, pal['mouth'])
    
    # Plant on head
    plant_base_y = body_cy - 13
    if anim == 'ability':
        # Growing plant
        grow = [1, 3, 5, 3][frame]
        # Stem
        for sy in range(grow):
            px(pixels, cx, plant_base_y - sy, pal['plant_stem'])
        # Leaves
        leaf_y = plant_base_y - grow
        circle(pixels, cx, leaf_y, 3, pal['plant_green'])
        px(pixels, cx - 2, leaf_y - 1, pal['plant_green_lt'])
        px(pixels, cx + 2, leaf_y, pal['plant_green_dk'])
        if frame >= 2:
            # Flower bloom
            px(pixels, cx - 1, leaf_y - 3, pal['plant_green_lt'])
            px(pixels, cx + 1, leaf_y - 3, pal['plant_green_lt'])
            px(pixels, cx, leaf_y - 4, pal['plant_green_lt'])
    else:
        # Normal small plant
        px(pixels, cx, plant_base_y, pal['plant_stem'])
        px(pixels, cx, plant_base_y - 1, pal['plant_stem'])
        circle(pixels, cx, plant_base_y - 2, 2, pal['plant_green'])
        px(pixels, cx - 1, plant_base_y - 3, pal['plant_green_lt'])
    
    # Little feet/legs
    foot_y = body_cy + 12 + leg_offset
    rect(pixels, cx - 7, foot_y, 5, 3, pal['blue_belly_dk'])
    rect(pixels, cx + 2, foot_y, 5, 3, pal['blue_belly_dk'])
    rect(pixels, cx - 7, foot_y, 5, 1, pal['blue_belly'])
    rect(pixels, cx + 2, foot_y, 5, 1, pal['blue_belly'])
    
    # Arms (small nubs)
    arm_y = body_cy + 2 + arm_offset
    circle(pixels, cx - 14, arm_y, 2, pal['body_yellow'])
    circle(pixels, cx + 14, arm_y, 2, pal['body_yellow'])
    px(pixels, cx - 15, arm_y, pal['body_yellow_dk'])
    px(pixels, cx + 15, arm_y, pal['body_yellow_dk'])

# ============================================================
# CHARACTER 2: CAPITÃO POLO — Polar bear, blue uniform & hat
# ============================================================
POLO_PALETTE = {
    'fur_white': (245, 245, 250, 255),       # White fur
    'fur_shadow': (210, 210, 220, 255),       # Fur shadow
    'uniform_blue': (50, 80, 160, 255),       # Blue uniform
    'uniform_blue_dk': (35, 60, 130, 255),    # Uniform shadow
    'uniform_blue_lt': (80, 110, 190, 255),   # Uniform highlight
    'hat_blue': (40, 65, 140, 255),           # Hat
    'hat_blue_dk': (25, 45, 110, 255),        # Hat shadow
    'hat_brass': (200, 170, 50, 255),         # Hat badge gold
    'nose': (30, 30, 35, 255),                # Nose
    'eye_b': (25, 25, 30, 255),               # Eyes
    'mouth': (120, 80, 60, 255),              # Mouth
    'claw': (200, 200, 210, 255),             # Claws
    'outline': (30, 30, 40, 255),             # Outline
    'button': (200, 170, 50, 255),            # Uniform buttons
}

def draw_polo(pixels, pal, anim, frame):
    """Draw Capitão Polo — polar bear in blue uniform."""
    import math
    bob = 0
    leg_offset = 0
    arm_offset = 0
    
    if anim == 'idle':
        bob = [0, -1, 0, -1][frame]
    elif anim == 'walk':
        bob = [0, -1, 0, -1][frame]
        leg_offset = [0, 2, 0, -2][frame]
        arm_offset = [0, 1, 0, -1][frame]
    elif anim == 'jump':
        bob = [-3, -4, -3, -2][frame]
        leg_offset = [-2, -3, -2, -1][frame]
    elif anim == 'ability':  # Escudo Gélido — ice shield
        bob = [0, -1, -1, 0][frame]
    
    cx = 24
    body_cy = 26 + bob
    
    # Body (rounder bear shape)
    circle(pixels, cx, body_cy, 13, pal['fur_white'])
    # Fur shadow lower
    for y in range(2, 14):
        for x in range(-13, 14):
            if x * x + y * y <= 13 * 13:
                if y > 6 or (x > 6 and y > 2):
                    px(pixels, cx + x, body_cy + y, pal['fur_shadow'])
    
    # Uniform (blue torso covering lower 2/3)
    for y in range(0, 13):
        for x in range(-12, 13):
            if x * x + y * y <= 13 * 13 and y > -2:
                px(pixels, cx + x, body_cy + y, pal['uniform_blue'])
                if x > 5:
                    px(pixels, cx + x, body_cy + y, pal['uniform_blue_dk'])
                if x < -5 and y < 4:
                    px(pixels, cx + x, body_cy + y, pal['uniform_blue_lt'])
    
    # Buttons
    for by in range(2, 10, 3):
        px(pixels, cx, body_cy + by, pal['button'])
    
    # Head area (upper white fur)
    for y in range(-13, 0):
        for x in range(-13, 14):
            if x * x + y * y <= 13 * 13:
                px(pixels, cx + x, body_cy + y, pal['fur_white'])
                if x > 5 and y > -5:
                    px(pixels, cx + x, body_cy + y, pal['fur_shadow'])
    
    # Ears (round, on top)
    circle(pixels, cx - 8, body_cy - 11, 3, pal['fur_white'])
    circle(pixels, cx + 8, body_cy - 11, 3, pal['fur_white'])
    px(pixels, cx - 8, body_cy - 11, pal['fur_shadow'])
    px(pixels, cx + 8, body_cy - 11, pal['fur_shadow'])
    
    # Hat (blue cap over head)
    # Hat brim
    rect(pixels, cx - 10, body_cy - 10, 20, 2, pal['hat_blue_dk'])
    # Hat dome
    rect(pixels, cx - 7, body_cy - 14, 14, 4, pal['hat_blue'])
    rect(pixels, cx - 7, body_cy - 14, 14, 1, pal['hat_blue_dk'])
    # Badge
    px(pixels, cx, body_cy - 12, pal['hat_brass'])
    px(pixels, cx - 1, body_cy - 12, pal['hat_brass'])
    px(pixels, cx, body_cy - 11, pal['hat_brass'])
    
    # Snout (bear nose)
    circle(pixels, cx, body_cy - 2, 4, pal['fur_white'])
    px(pixels, cx, body_cy - 4, pal['nose'])
    px(pixels, cx - 1, body_cy - 4, pal['nose'])
    px(pixels, cx + 1, body_cy - 4, pal['nose'])
    
    # Eyes
    px(pixels, cx - 5, body_cy - 6, pal['eye_b'])
    px(pixels, cx + 5, body_cy - 6, pal['eye_b'])
    px(pixels, cx - 4, body_cy - 7, pal['fur_white'])
    px(pixels, cx + 4, body_cy - 7, pal['fur_white'])
    
    # Mouth
    px(pixels, cx - 1, body_cy + 1, pal['mouth'])
    px(pixels, cx + 1, body_cy + 1, pal['mouth'])
    
    # Arms
    arm_y = body_cy + 3 + arm_offset
    circle(pixels, cx - 13, arm_y, 3, pal['uniform_blue'])
    circle(pixels, cx + 13, arm_y, 3, pal['uniform_blue'])
    px(pixels, cx - 14, arm_y, pal['uniform_blue_dk'])
    px(pixels, cx + 14, arm_y, pal['uniform_blue_dk'])
    # Claws
    for i in range(3):
        px(pixels, cx - 15, arm_y - 1 + i, pal['claw'])
        px(pixels, cx + 15, arm_y - 1 + i, pal['claw'])
    
    # Feet
    foot_y = body_cy + 12 + leg_offset
    rect(pixels, cx - 8, foot_y, 6, 4, pal['uniform_blue'])
    rect(pixels, cx + 2, foot_y, 6, 4, pal['uniform_blue'])
    rect(pixels, cx - 8, foot_y, 6, 1, pal['uniform_blue_lt'])
    rect(pixels, cx + 2, foot_y, 6, 1, pal['uniform_blue_lt'])
    # Claw toes
    for i in range(3):
        px(pixels, cx - 7 + i * 2, foot_y + 4, pal['claw'])
        px(pixels, cx + 3 + i * 2, foot_y + 4, pal['claw'])
    
    # Ability: Ice shield
    if anim == 'ability':
        shield_alpha = [0, 100, 200, 255][frame]
        ice_color = (180, 220, 255, shield_alpha)
        ice_glow = (220, 240, 255, shield_alpha)
        # Shield arc in front
        for y in range(-15, 16):
            for x in range(-15, 16):
                d = math.sqrt(x * x + y * y)
                if 14 <= d <= 17:
                    px(pixels, cx + x, body_cy + y, ice_color)
                if 15 <= d <= 16:
                    px(pixels, cx + x, body_cy + y, ice_glow)
        # Ice crystals
        for cy_off in [-8, 0, 8]:
            px(pixels, cx + 16, body_cy + cy_off, ice_glow)
            px(pixels, cx + 17, body_cy + cy_off, ice_color)

# ============================================================
# CHARACTER 3: GARRAX — Orange cat, eyepatch, blue hat & boots
# ============================================================
GARRAX_PALETTE = {
    'fur_orange': (240, 150, 50, 255),       # Orange fur
    'fur_orange_dk': (200, 110, 30, 255),     # Fur shadow
    'fur_orange_lt': (255, 180, 80, 255),     # Fur highlight
    'fur_cream': (250, 230, 200, 255),       # Cream belly/muzzle
    'hat_blue': (50, 80, 160, 255),           # Blue hat
    'hat_blue_dk': (35, 60, 130, 255),        # Hat shadow
    'hat_band': (200, 50, 50, 255),          # Red hat band
    'eyepatch': (20, 20, 25, 255),           # Eyepatch black
    'eyepatch_strap': (40, 40, 45, 255),     # Strap
    'eye_g': (255, 220, 60, 255),            # Gold eye (visible eye)
    'eye_p': (20, 20, 25, 255),              # Pupil
    'nose': (180, 100, 80, 255),             # Nose pink
    'mouth': (120, 60, 60, 255),             # Mouth
    'boots_blue': (50, 80, 160, 255),         # Blue boots
    'boots_blue_dk': (35, 60, 130, 255),      # Boot shadow
    'belt': (100, 60, 30, 255),               # Belt brown
    'outline': (40, 25, 15, 255),             # Outline
    'whisker': (255, 240, 220, 255),          # Whiskers
}

def draw_garrax(pixels, pal, anim, frame):
    """Draw Garrax — orange cat with eyepatch, blue hat and boots."""
    import math
    bob = 0
    leg_offset = 0
    arm_offset = 0
    tail_swing = 0
    
    if anim == 'idle':
        bob = [0, -1, -1, 0][frame]
        tail_swing = [0, 1, 0, -1][frame]
    elif anim == 'walk':
        bob = [0, -1, 0, -1][frame]
        leg_offset = [0, 2, 0, -2][frame]
        arm_offset = [0, -1, 0, 1][frame]
        tail_swing = [1, 2, 1, 0][frame]
    elif anim == 'jump':
        bob = [-3, -4, -3, -2][frame]
        leg_offset = [-2, -3, -2, -1][frame]
        tail_swing = [-2, -3, -2, -1][frame]
    elif anim == 'ability':  # Dash Sombrio
        bob = [0, -1, -2, -1][frame]
        tail_swing = [0, -2, -3, -1][frame]
    
    cx = 24
    body_cy = 26 + bob
    
    # Body (cat shaped, slightly oval)
    circle(pixels, cx, body_cy, 12, pal['fur_orange'])
    # Shadow
    for y in range(2, 13):
        for x in range(-12, 13):
            if x * x + y * y <= 12 * 12:
                if x > 4 and y > 2:
                    px(pixels, cx + x, body_cy + y, pal['fur_orange_dk'])
    # Highlight
    for y in range(-12, -2):
        for x in range(-12, 2):
            if x * x + y * y <= 10 * 10 and x < -2 and y < -4:
                px(pixels, cx + x, body_cy + y, pal['fur_orange_lt'])
    
    # Cream belly/muzzle
    for y in range(-1, 10):
        for x in range(-6, 7):
            if x * x + y * y <= 12 * 12 and y > -1:
                px(pixels, cx + x, body_cy + y, pal['fur_cream'])
    
    # Cat ears (pointy)
    # Left ear
    for i in range(4):
        rect(pixels, cx - 10 + i, body_cy - 12 - i, 1, 2 + i, pal['fur_orange'])
    px(pixels, cx - 9, body_cy - 13, pal['fur_orange'])
    px(pixels, cx - 10, body_cy - 12, pal['fur_orange'])
    px(pixels, cx - 8, body_cy - 14, pal['fur_orange'])
    px(pixels, cx - 7, body_cy - 13, pal['fur_orange'])
    # Inner ear
    px(pixels, cx - 9, body_cy - 12, pal['nose'])
    
    # Right ear
    for i in range(4):
        rect(pixels, cx + 7 - i, body_cy - 12 - i, 1, 2 + i, pal['fur_orange'])
    px(pixels, cx + 8, body_cy - 13, pal['fur_orange'])
    px(pixels, cx + 10, body_cy - 12, pal['fur_orange'])
    px(pixels, cx + 7, body_cy - 14, pal['fur_orange'])
    px(pixels, cx + 9, body_cy - 13, pal['fur_orange'])
    px(pixels, cx + 9, body_cy - 12, pal['nose'])
    
    # Hat (blue adventurer hat)
    # Brim
    rect(pixels, cx - 9, body_cy - 9, 18, 2, pal['hat_blue_dk'])
    # Crown
    rect(pixels, cx - 6, body_cy - 13, 12, 4, pal['hat_blue'])
    rect(pixels, cx - 6, body_cy - 13, 12, 1, pal['hat_blue_dk'])
    # Red band
    rect(pixels, cx - 6, body_cy - 10, 12, 1, pal['hat_band'])
    
    # Eyepatch (left eye)
    rect(pixels, cx - 8, body_cy - 4, 5, 4, pal['eyepatch'])
    # Strap
    for x in range(-10, 3):
        px(pixels, cx + x, body_cy - 5, pal['eyepatch_strap'])
    
    # Right eye (visible, gold)
    circle(pixels, cx + 5, body_cy - 3, 2, pal['eye_g'])
    px(pixels, cx + 5, body_cy - 3, pal['eye_p'])
    px(pixels, cx + 6, body_cy - 4, (255, 255, 255, 255))
    
    # Nose
    px(pixels, cx, body_cy, pal['nose'])
    px(pixels, cx - 1, body_cy, pal['nose'])
    px(pixels, cx + 1, body_cy, pal['nose'])
    
    # Mouth (cat smile)
    px(pixels, cx - 2, body_cy + 2, pal['mouth'])
    px(pixels, cx, body_cy + 3, pal['mouth'])
    px(pixels, cx + 2, body_cy + 2, pal['mouth'])
    
    # Whiskers
    for wy in [-1, 0, 1]:
        px(pixels, cx - 12, body_cy + wy, pal['whisker'])
        px(pixels, cx - 11, body_cy + wy, pal['whisker'])
        px(pixels, cx + 12, body_cy + wy, pal['whisker'])
        px(pixels, cx + 11, body_cy + wy, pal['whisker'])
    
    # Belt
    rect(pixels, cx - 10, body_cy + 6, 20, 2, pal['belt'])
    
    # Arms
    arm_y = body_cy + 2 + arm_offset
    circle(pixels, cx - 12, arm_y, 2, pal['fur_orange'])
    circle(pixels, cx + 12, arm_y, 2, pal['fur_orange'])
    px(pixels, cx - 13, arm_y, pal['fur_orange_dk'])
    px(pixels, cx + 13, arm_y, pal['fur_orange_dk'])
    
    # Boots (blue)
    foot_y = body_cy + 11 + leg_offset
    rect(pixels, cx - 8, foot_y, 6, 5, pal['boots_blue'])
    rect(pixels, cx + 2, foot_y, 6, 5, pal['boots_blue'])
    rect(pixels, cx - 8, foot_y, 6, 1, pal['boots_blue_dk'])
    rect(pixels, cx + 2, foot_y, 6, 1, pal['boots_blue_dk'])
    # Boot details
    rect(pixels, cx - 7, foot_y + 2, 4, 1, pal['hat_band'])
    rect(pixels, cx + 3, foot_y + 2, 4, 1, pal['hat_band'])
    
    # Tail
    tail_base_x = cx + 11
    tail_base_y = body_cy + 4
    for i in range(6):
        tx = tail_base_x + i
        ty = tail_base_y - i + tail_swing
        px(pixels, tx, ty, pal['fur_orange'])
        px(pixels, tx, ty + 1, pal['fur_orange_dk'])
    # Tail tip
    circle(pixels, tail_base_x + 6, tail_base_y - 6 + tail_swing, 2, pal['fur_orange_lt'])
    
    # Ability: Dash shadow trail
    if anim == 'ability':
        trail_alpha = [0, 80, 150, 100][frame]
        shadow_color = (100, 60, 200, trail_alpha)  # Purple shadow
        for i in range(4):
            offset = -(i + 1) * 3
            for y in range(-10, 11):
                for x in range(-10, 11):
                    if x * x + y * y <= 10 * 10:
                        px(pixels, cx + x + offset, body_cy + y, shadow_color)

# ============================================================
# Generate all sprite sheets
# ============================================================
output_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'characters')
output_dir = os.path.abspath(output_dir)
os.makedirs(output_dir, exist_ok=True)

# Character 1: Mossy
create_sprite_sheet('mossy', MOSSY_PALETTE, draw_mossy,
    os.path.join(output_dir, 'amarelo.png'))

# Character 2: Capitão Polo
create_sprite_sheet('polo', POLO_PALETTE, draw_polo,
    os.path.join(output_dir, 'urso.png'))

# Character 3: Garrax
create_sprite_sheet('garrax', GARRAX_PALETTE, draw_garrax,
    os.path.join(output_dir, 'gato.png'))

# Also create individual idle sprites (first frame of idle row)
for name, pal, draw_func, fname in [
    ('mossy', MOSSY_PALETTE, draw_mossy, 'amarelo_idle.png'),
    ('polo', POLO_PALETTE, draw_polo, 'urso_idle.png'),
    ('garrax', GARRAX_PALETTE, draw_garrax, 'gato_idle.png'),
]:
    sprite = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
    pixels = sprite.load()
    draw_func(pixels, pal, 'idle', 0)
    sprite.save(os.path.join(output_dir, fname))
    print(f"Saved: {os.path.join(output_dir, fname)}")

print("\n=== All character sprites generated! ===")