// Mode hors ligne de DDZ Runner.
// La page passe d'abord par le réseau (nouvelles versions dès qu'on est connecté) et retombe sur
// la copie en cache hors ligne ; le moteur 3D, les polices et les icônes sont servis depuis le cache.
// CACHE est réécrit par publish.sh avec la version du jeu : une nouvelle version vide l'ancien cache.
const CACHE = 'ddz-runner-2.3';
const FILES = [
  './', './index.html', './manifest.webmanifest', './icon-180.png', './icon-192.png', './icon-512.png',
  './fonts/fonts.css', './fonts/LilitaOne.ttf', './fonts/Rajdhani-600.ttf', './fonts/Rajdhani-700.ttf',
  './vendor/three/build/three.module.js',
  ...['EffectComposer', 'RenderPass', 'UnrealBloomPass', 'ShaderPass', 'AfterimagePass', 'OutputPass', 'MaskPass', 'Pass']
    .map(f => `./vendor/three/examples/jsm/postprocessing/${f}.js`),
  ...['CopyShader', 'LuminosityHighPassShader', 'AfterimageShader', 'OutputShader']
    .map(f => `./vendor/three/examples/jsm/shaders/${f}.js`),
];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k.startsWith('ddz-runner-') && k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== self.location.origin) return;
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then(res => {
          const copy = res.clone();
          caches.open(CACHE).then(cache => cache.put('./index.html', copy));
          return res;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }
  event.respondWith(caches.match(req, { ignoreSearch: true }).then(hit => hit || fetch(req)));
});
