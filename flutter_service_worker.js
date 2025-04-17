'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "ab4f6b290258604ab877463d76b9e52c",
"version.json": "942919ac6d569966f308439c5b011f1c",
"favicon.ico": "78d45b6b149f5a0c0af48afe01eaa70b",
"index.html": "dcaf35ccd7aab79cd9bc6f62b43f51ca",
"/": "dcaf35ccd7aab79cd9bc6f62b43f51ca",
"apple-touch-icon.png": "1cadd0b09c0f32e42577566eaed5d62a",
"main.dart.js": "dea8088e6fee5f1acdef9f91672b409f",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"icons/icon-192.png": "63f6a82aca13434e978e52e41c55e434",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/icon-192-maskable.png": "37d692fb5c64e6e2ab0cb1ba8fdd65d7",
"icons/icon-512-maskable.png": "b885ce2e2d1372d547d7c73ae7befec7",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/icon-512.png": "c0ba7f891e3d2eb0ddfc7065c04388e8",
"manifest.json": "67212d1ce52f3010f3ce0580e2ab6d09",
"assets/web/assets/garrison/garrison_intro.mp4": "ed323832e797c56a221b1a8825882b4b",
"assets/garrison/mp.png": "04b61f699f7800f0011ea03068713367",
"assets/garrison/garrison_intro.mp4": "ed323832e797c56a221b1a8825882b4b",
"assets/garrison/good_youth.png": "210a4fbee2411b3d739663f959ff776f",
"assets/garrison/vendor.png": "d871a5446ecb14ea33083247168ebaa2",
"assets/garrison/garrison_sticker.png": "ec9a0ca3f53d0756f85e2b3e6f0e259d",
"assets/garrison/concrete.jpg": "4dd04446e7b2012f209c09307c24fe5d",
"assets/garrison/garrison.png": "52e62570e26ca2789eb0bedb03abdf53",
"assets/garrison/jp.png": "49c98d8b80a75b3b2f4c483dd7ae376e",
"assets/garrison/background.png": "576380195f084986e580021edb711610",
"assets/garrison/garrison_logo.png": "6fe410aa01bc4a71ecb7c71d8f33d751",
"assets/garrison/don.png": "27620a44f8a0dfa22ace8822453ef761",
"assets/garrison/babylon.png": "389900ce9dfaf68c228e331dda1e7476",
"assets/garrison/onboarding_background.png": "493fb660bd0150394e4db84588622989",
"assets/AssetManifest.json": "539f42897523948eb50394631cfe8b72",
"assets/NOTICES": "2aafc1896d12660c8d869b32e6e0edeb",
"assets/FontManifest.json": "ec0f37493bda7c90f9e7190d9ef5ad64",
"assets/AssetManifest.bin.json": "a54be378930cba16b413c9e9d362073e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "391ff5f9f24097f4f6e4406690a06243",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "18f97bc7175eb12247f7b86928ccb6b4",
"assets/fonts/MaterialIcons-Regular.otf": "c2bd257e27cbb83b060f21c9fa131495",
"assets/assets/birth_paper_bg.jpg": "67d66fedb992b403665c2986b882d86b",
"assets/assets/cards.json": "451186ff819cbabffe6ec0558646b9dd",
"assets/assets/fonts/BebasNeue-Regular.ttf": "21bb70b62317f276f2e97a919ff5bd8c",
"assets/assets/assets/garrison/mp.png": "04b61f699f7800f0011ea03068713367",
"assets/assets/assets/garrison/garrison_intro.mp4": "ed323832e797c56a221b1a8825882b4b",
"assets/assets/assets/garrison/good_youth.png": "210a4fbee2411b3d739663f959ff776f",
"assets/assets/assets/garrison/vendor.png": "d871a5446ecb14ea33083247168ebaa2",
"assets/assets/assets/garrison/garrison_sticker.png": "ec9a0ca3f53d0756f85e2b3e6f0e259d",
"assets/assets/assets/garrison/concrete.jpg": "4dd04446e7b2012f209c09307c24fe5d",
"assets/assets/assets/garrison/garrison.png": "52e62570e26ca2789eb0bedb03abdf53",
"assets/assets/assets/garrison/jp.png": "49c98d8b80a75b3b2f4c483dd7ae376e",
"assets/assets/assets/garrison/background.png": "576380195f084986e580021edb711610",
"assets/assets/assets/garrison/garrison_logo.png": "6fe410aa01bc4a71ecb7c71d8f33d751",
"assets/assets/assets/garrison/don.png": "27620a44f8a0dfa22ace8822453ef761",
"assets/assets/assets/garrison/babylon.png": "389900ce9dfaf68c228e331dda1e7476",
"assets/assets/assets/garrison/onboarding_background.png": "493fb660bd0150394e4db84588622989",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
