#!/usr/bin/env bash
# Prépare le site GitHub Pages de DDZ Runner à partir de ../index.html.
# Usage (Git Bash) : ./publish.sh          → prépare seulement les fichiers
#                    ./publish.sh --push   → prépare puis commit + push (action publique)
set -euo pipefail
cd "$(dirname "$0")"

# Dépendances locales (mêmes fichiers que l'APK) : le jeu marche hors ligne et sans CDN
rm -rf vendor fonts
cp -r ../android/app/assets/vendor ../android/app/assets/fonts .

python - <<'PY'
import re
src = open('../index.html', encoding='utf-8').read()
reps = [
    ('<link rel="preconnect" href="https://fonts.googleapis.com">\n', ''),
    ('<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n', ''),
    ('https://fonts.googleapis.com/css2?family=Lilita+One&family=Rajdhani:wght@600;700&display=swap', 'fonts/fonts.css'),
    ('https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js', './vendor/three/build/three.module.js'),
    ('https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/', './vendor/three/examples/jsm/'),
]
for a, b in reps:
    assert a in src, 'introuvable dans index.html : ' + a
    src = src.replace(a, b)
version = re.search(r"GAME_VERSION = '([^']+)'", src).group(1)
# Appli installable (iPhone + Android) + mode hors ligne
head = '''<link rel="manifest" href="manifest.webmanifest">
<link rel="apple-touch-icon" href="icon-180.png">
<link rel="icon" type="image/png" sizes="192x192" href="icon-192.png">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="DDZ Runner">
'''
sw = '''<script>
  if ('serviceWorker' in navigator && location.protocol === 'https:') {
    navigator.serviceWorker.register('sw.js').catch(() => { /* hors ligne indisponible : le jeu marche quand même */ });
  }
</script>
'''
src = src.replace('</head>', head + '</head>', 1).replace('</body>', sw + '</body>', 1)
open('index.html', 'w', encoding='utf-8').write(src)
s = open('sw.js', encoding='utf-8').read()
s = re.sub(r"const CACHE = 'ddz-runner-[^']*';", f"const CACHE = 'ddz-runner-{version}';", s)
open('sw.js', 'w', encoding='utf-8').write(s)
print('Site préparé : version', version)
PY

if [ "${1:-}" = "--push" ]; then
  git add -A
  git commit -m "DDZ Runner v$(grep -o "GAME_VERSION = '[^']*'" index.html | cut -d"'" -f2)"
  git push
fi
