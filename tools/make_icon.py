#!/usr/bin/env python3
"""Draw the fiat penus launcher icon: the house silhouette in the icon gold,
a lararium on top in cream -- the household shrine of the Penates, gable and
two columns, with the hearth fire burning between them. Writes
icons/harbour-fiatpenus.svg, the four PNG sizes Sailfish wants and the copy the
About page shows in the family list.

    pip install cairosvg
    python3 tools/make_icon.py

The silhouette is the family's: a square whose top-left and bottom-right
corners are replaced by the inscribed circle, drawn as circle, top-right
quadrant and bottom-left quadrant together.

The icon gold is lighter than the app's accent (#926000 in FiatPenusTheme).
Gold only stays gold when it is light, and light gold cannot carry small
text on the cream paper, so the two are kept apart on purpose: the glyph sits
at 1.7:1 on the icon, the accent at 4.7:1 on the page."""
import os

ACCENT = "#E0AE4A"
GLYPH = "#F2E9D8"
SILHOUETTE = ('<circle cx="128" cy="128" r="128"/>'
              '<rect x="128" y="0" width="128" height="128"/>'
              '<rect x="0" y="128" width="128" height="128"/>')

# The lararium: a gable on two columns over a plinth, the fire in between.
GLYPH_SVG = f'''
<polygon points="60,104 128,58 196,104" fill="{GLYPH}"/>
<rect x="64" y="106" width="128" height="12" fill="{GLYPH}"/>
<rect x="74" y="124" width="16" height="64" fill="{GLYPH}"/>
<rect x="166" y="124" width="16" height="64" fill="{GLYPH}"/>
<rect x="60" y="190" width="136" height="12" rx="2" fill="{GLYPH}"/>
<path d="M128 130 C 144 148, 150 160, 146 172 C 142 184, 114 184, 110 172
         C 106 160, 116 150, 120 138 C 124 150, 128 152, 128 130 Z" fill="{GLYPH}"/>'''


def svg():
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
            f'<g fill="{ACCENT}">{SILHOUETTE}</g>{GLYPH_SVG}</svg>\n')


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "icons")
    with open(os.path.join(root, "harbour-fiatpenus.svg"), "w") as f:
        f.write(svg())
    import cairosvg
    for size in (86, 108, 128, 172):
        d = os.path.join(root, f"{size}x{size}")
        os.makedirs(d, exist_ok=True)
        cairosvg.svg2png(bytestring=svg().encode(), write_to=os.path.join(d, "harbour-fiatpenus.png"),
                         output_width=size, output_height=size)
    family = os.path.join(root, "..", "qml", "pages", "images", "family", "harbour-fiatpenus.png")
    cairosvg.svg2png(bytestring=svg().encode(), write_to=family, output_width=172, output_height=172)
    print("icons written")


if __name__ == "__main__":
    main()
