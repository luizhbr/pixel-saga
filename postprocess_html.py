#!/usr/bin/env python3
"""
postprocess_html.py — Aplica melhorias mobile ao index.html exportado pelo Godot.
Rode APÓS cada export do Godot para manter o CSS de preenchimento de tela.
Uso: python postprocess_html.py
"""
import re
import sys
from pathlib import Path

HTML_PATH = Path(__file__).parent / "export" / "html5" / "index.html"

# CSS mobile que substitui o bloco <style> original
MOBILE_CSS = """html, body, #canvas {
\tmargin: 0;
\tpadding: 0;
\tborder: 0;
\twidth: 100%;
\theight: 100%;
}

body {
\tcolor: white;
\tbackground-color: black;
\toverflow: hidden;
\ttouch-action: none;
\t-webkit-user-select: none;
\tuser-select: none;
\t-webkit-touch-callout: none;
\tposition: fixed;
\tinset: 0;
}

#canvas {
\tdisplay: block;
\twidth: 100%;
\theight: 100%;
\tobject-fit: contain;
\timage-rendering: pixelated;
\timage-rendering: crisp-edges;
}

#canvas:focus {
\toutline: none;
}"""

# Meta tags mobile a adicionar (se ausentes)
MOBILE_META = [
    '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">',
    '<meta name="mobile-web-app-capable" content="yes">',
    '<meta name="apple-mobile-web-app-capable" content="yes">',
    '<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">',
]


def main() -> int:
    if not HTML_PATH.exists():
        print(f"ERRO: {HTML_PATH} não encontrado. Exporte o jogo primeiro.")
        return 1

    html = HTML_PATH.read_text(encoding="utf-8")

    # 1. Substituir o bloco <style>...</style> pelo CSS mobile
    style_pattern = re.compile(r"<style>.*?</style>", re.DOTALL)
    if style_pattern.search(html):
        html = style_pattern.sub(f"<style>{MOBILE_CSS}</style>", html, count=1)
        print("✓ CSS mobile aplicado")
    else:
        print("⚠ Bloco <style> não encontrado")

    # 2. Adicionar meta tags mobile (se ausentes)
    for meta in MOBILE_META:
        if meta not in html:
            html = html.replace("<title>", f"{meta}\n\t\t<title>", 1)
            print(f"✓ Meta adicionada: {meta.split(' ')[0]}")

    # 3. Garantir viewport-fit=cover no viewport existente
    if "viewport-fit=cover" not in html:
        html = html.replace(
            'name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0"',
            'name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover"',
        )
        print("✓ viewport-fit=cover aplicado")

    HTML_PATH.write_text(html, encoding="utf-8")
    print(f"✓ {HTML_PATH} atualizado")
    return 0


if __name__ == "__main__":
    sys.exit(main())
