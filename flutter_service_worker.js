'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"version.json": "da3c098c00dfa739350169eefb7ff055",
"browserconfig.xml": "2098376b4d3c13bcdf7ac0abd58120db",
"index.html": "49dda21880caa00705817d1142db9cdf",
"/": "49dda21880caa00705817d1142db9cdf",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"performance_test.html": "383d7a464f52c46fd733632d6a425372",
"flutter_bootstrap.js": "d03cbbd30efc0b19fbf8ab8f4c636f38",
"assets/AssetManifest.bin": "cb1ecc855cf1ac335c7c3f7a4d6dce2b",
"assets/fonts/MaterialIcons-Regular.otf": "1d9a92ca9d25479de2c19d76818cc421",
"assets/AssetManifest.bin.json": "d3709304c933aeae2d5892d734d3b1c0",
"assets/NOTICES": "e76e758c0031bd0233c4e7ae9b8c6de5",
"assets/AssetManifest.json": "e12909cff1dec1eee5ad26143556d120",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size4-Regular.ttf": "85554307b465da7eb785fd3ce52ad282",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Math-Italic.ttf": "a7732ecb5840a15be39e1eda377bc21d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Italic.ttf": "ac3b1882325add4f148f05db8cafd401",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Math-BoldItalic.ttf": "946a26954ab7fbd7ea78df07795a6cbc",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Bold.ttf": "ad0a28f28f736cf4c121bcb0e719b88a",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Script-Regular.ttf": "55d2dcd4778875a53ff09320a85a5296",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Italic.ttf": "d89b80e7bdd57d238eeaa80ed9a1013a",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Fraktur-Regular.ttf": "dede6f2c7dad4402fa205644391b3a94",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size3-Regular.ttf": "e87212c26bb86c21eb028aba2ac53ec3",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Caligraphic-Regular.ttf": "7ec92adfa4fe03eb8e9bfb60813df1fa",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size2-Regular.ttf": "959972785387fe35f7d47dbfb0385bc4",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Bold.ttf": "9eef86c1f9efa78ab93d41a0551948f7",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Caligraphic-Bold.ttf": "a9c8e437146ef63fcd6fae7cf65ca859",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size1-Regular.ttf": "1e6a3368d660edc3a2fbbe72edfeaa85",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Fraktur-Bold.ttf": "46b41c4de7a936d099575185a94855c4",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_AMS-Regular.ttf": "657a5353a553777e270827bd1630e467",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Typewriter-Regular.ttf": "87f56927f1ba726ce0591955c8b3b42d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Regular.ttf": "b5f967ed9e4933f1c3165a12fe3436df",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-BoldItalic.ttf": "e3c361ea8d1c215805439ce0941a1c8d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Regular.ttf": "5a5766c715ee765aa1398997643f1589",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/lucide_icons_flutter/assets/lucide.ttf": "d12b1a40489d6b50f0363df6f0d6d092",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf": "8909e18b2d34b952b6ef8b911c1f1cae",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf": "8242e3c2ccae9cedc14213f26454410d",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf": "5ef7ed6d126034fa4d549208d1490814",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf": "3c46ff7515368b68e570ce96901ccc24",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf": "5d5f12dc9e2d93e421626ce82745b3a5",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf": "f2578f0d282fc7091553c613d78f36a3",
"assets/packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf": "d09f65145228b709a10fa0a06d522d89",
"assets/assets/mermaid.min.js": "f1caff2ea3b92c2704cac1d5afeaad7e",
"assets/assets/icons/internlm-color.svg": "3176a0ddec7638670a36865e47f81a32",
"assets/assets/icons/xai.svg": "76a2073985bec0b3928d172ace7068a9",
"assets/assets/icons/perplexity-color.svg": "0c5b9062bf93eeb9ab841242fbaaf552",
"assets/assets/icons/kelivo.png": "81fceaf615e82bb0eef681eb4ddfc44e",
"assets/assets/icons/siliconflow-color.svg": "c2c2b16a80ce31bcb2c1f580390574f1",
"assets/assets/icons/openrouter.svg": "c771f6bae3be22096f4f7b96c2cef944",
"assets/assets/icons/tensdaq-color.svg": "b4ed132491ca693423a0962e2f42c35f",
"assets/assets/icons/minimax-color.svg": "cf27a08682bb9533098eb4337917654b",
"assets/assets/icons/alibabacloud-color.svg": "ed4fe8d07b02de1bd2b877a46c70bc2c",
"assets/assets/icons/tencent-qq.svg": "b89c6fc75d2797bbe5290feac23769db",
"assets/assets/icons/deepseek-color.svg": "f68fd757111006401b496001ea30ccec",
"assets/assets/icons/stop.svg": "1507e0fd6ca47d185e17509772abf6a8",
"assets/assets/icons/gemma-color.svg": "f958dcbe8075aea70a43df589a25341a",
"assets/assets/icons/claude-color.svg": "6688d76fc19aa873ec7a5022ce557de0",
"assets/assets/icons/web.svg": "6f2b418687ba16dcbbd4901681eedbb4",
"assets/assets/icons/google-color.svg": "80d59ea6c76a91a8bc4804dc0c845949",
"assets/assets/icons/zhipu-color.svg": "afbb69c074e5c2ac93c043f1d396c5aa",
"assets/assets/icons/iflow-color.svg": "e9493f99d19b66a5d7fce5a9b3539026",
"assets/assets/icons/deepthink__.svg": "bcfc5f3585a015a0221d0f685a09c276",
"assets/assets/icons/302ai-color.svg": "ce2708e00c98cf35c7e1d38b3197a997",
"assets/assets/icons/anthropic.svg": "2d331fdf23768f3350e68a901513534a",
"assets/assets/icons/openai.svg": "c2ccf2fe4385cb3045d3bb0fcbf886a5",
"assets/assets/icons/deepthink.svg": "8dabbe0c8a512ade22fbb2f423779a93",
"assets/assets/icons/exa.png": "3b112b2392f0683398107e91e82802c6",
"assets/assets/icons/bing.png": "ea8f00001278e0b29a5d2ba1e8f4fcbb",
"assets/assets/icons/stepfun-color.svg": "37c371f8678ab668dfaefe20eb176756",
"assets/assets/icons/aihubmix-color.svg": "45aa1c370636ae4dfa7e069163c1f3fd",
"assets/assets/icons/bytedance-color.svg": "ee48e89c9f26f561f66dae5dcb553e39",
"assets/assets/icons/gemini-color.svg": "738fc28717976793bc5143d7138eae01",
"assets/assets/icons/qwen-color.svg": "f26fadfc483061670d3917b0c7a3d6e4",
"assets/assets/icons/ollama.svg": "a3fdc24b5276332ba1e70825e069c210",
"assets/assets/icons/list2.svg": "0fd43218bdede4aaf94c6de31a2b3435",
"assets/assets/icons/juhenext.png": "4be7beac1cb13f0a643ccbe8ba1a2071",
"assets/assets/icons/meta-color.svg": "1e5cbf910abd67f82a081f0d547705f4",
"assets/assets/icons/linkup.png": "af9410f1cc57c09007152a0a5d47df1f",
"assets/assets/icons/hunyuan-color.svg": "be63152dee204b10da47ec6cc83f918e",
"assets/assets/icons/github.svg": "7871032a477ee33f2fb8f406cf63450e",
"assets/assets/icons/mistral-color.svg": "f185c642013ad782a6f6a56214503492",
"assets/assets/icons/brave-color.svg": "ca19b7985d814dc026be8be80a65eadd",
"assets/assets/icons/grok.svg": "e9ce694d314205395622bf8af72ea222",
"assets/assets/icons/cloudflare-color.svg": "fe731c6f66a47092dde4cdd74440ea41",
"assets/assets/icons/longcat.png": "4c1f9f537b3af23f8a69245589e4a473",
"assets/assets/icons/cohere-color.svg": "df4e1d810e46b2dbf446033de1ca9157",
"assets/assets/icons/kimi-color.svg": "9ff6645d8041f3be3212909ede51eedb",
"assets/assets/icons/tavily.png": "76933c90f5012d01d3cf6e03b27463fb",
"assets/assets/icons/discord.svg": "43d2b6a26ca6fedd743295da5fcdc3fc",
"assets/assets/icons/list.svg": "0efb4f4f1a3b995121c7ee02d5a9d4b4",
"assets/assets/icons/codex.svg": "e96b66795373820d54a4e961c75fb300",
"assets/assets/icons/doubao-color.svg": "d010601c5abbcf032f0b65550fdbd841",
"assets/assets/app_icon.png": "99a77bae7884bf5ba4d65e92e0fb0c40",
"assets/FontManifest.json": "cd43f5972cec9cdf99a585e8db603ba3",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"manifest.json": "adab06f8b5a55ab2e5fc8ffb385434f1",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"splash/img/dark-4x.png": "222ea43132af2b865fc769789f125a9f",
"splash/img/dark-3x.png": "c2f71d161cbd4a2556f7b8fffc12710f",
"splash/img/light-2x.png": "5e4cdcdc9837fd516ac4b0e7aad9c883",
"splash/img/dark-1x.png": "71dac3eb73620dfc09bfd5cfeac3ced5",
"splash/img/light-3x.png": "c2f71d161cbd4a2556f7b8fffc12710f",
"splash/img/light-4x.png": "222ea43132af2b865fc769789f125a9f",
"splash/img/light-1x.png": "71dac3eb73620dfc09bfd5cfeac3ced5",
"splash/img/dark-2x.png": "5e4cdcdc9837fd516ac4b0e7aad9c883",
"main.dart.js": "cce2e6ae33d6648740cd82579f94abcd",
"sw.js": "2f74f638dde8f1a0faef018b6668ff03",
"favicon.png": "f4982f520239fb2f6f515caceabf3a53",
"icons/Icon-144.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-72.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-96.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-384.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-maskable-192.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-192.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-152.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-128.png": "8a0073a6737297aacfb0b87f9b2903f4",
"icons/Icon-maskable-512.png": "b334ecc79af10b3821a6a0433c655e00",
"icons/Icon-512.png": "b334ecc79af10b3821a6a0433c655e00",
"flutter_build_config.json": "af013814bca6fc0103c7f8afef66786c"};
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
