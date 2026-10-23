"""Bundle local OFL fonts and CSS into Grocy's persistent custom-CSS hook."""
from pathlib import Path
from base64 import b64encode

root = Path(__file__).parent / 'theme'
faces = []
for family, name, weights in [('Prism Fraunces', 'Fraunces', '100 900'), ('Prism Space', 'SpaceGrotesk', '300 700')]:
    data = b64encode((root / 'fonts' / (name + '.woff2')).read_bytes()).decode()
    faces.append("@font-face { font-family:'%s'; src:url(data:font/woff2;base64,%s) format('woff2'); font-weight:%s; font-style:normal; font-display:swap; }" % (family, data, weights))
output = '<!-- Prism Kitchen. Fonts: Fraunces / Space Grotesk, SIL OFL 1.1. -->\n<style id="prism-kitchen-theme">\n' + '\n'.join(faces) + '\n' + (root / 'prism.css').read_text() + '\n</style>\n'
(root / 'custom_css.html').write_text(output)
print('Built custom_css.html: %s bytes' % len(output.encode()))
