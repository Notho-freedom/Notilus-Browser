/// Optimisations de performance pour le WebView2BrowserEngine
/// Gère l'accélération GPU, le rendu HD, et les optimisations réseau
library webview_optimizations;

/// Scripts d'optimisation GPU et rendu
class GpuOptimizationScripts {
  /// Script d'optimisation GPU complète
  static const String gpuAccelerationScript = '''
(function() {
  'use strict';
  if (window._notilusGpuOptimized) return;
  window._notilusGpuOptimized = true;
  
  // Forcer l'accélération GPU sur tous les éléments
  var style = document.createElement('style');
  style.id = 'notilus-gpu-accel';
  style.textContent = \`
    * {
      -webkit-transform: translateZ(0);
      transform: translateZ(0);
      -webkit-backface-visibility: hidden;
      backface-visibility: hidden;
    }
    a, button, input, select, textarea {
      will-change: transform;
    }
    body, html {
      -webkit-overflow-scrolling: touch;
      overflow-scrolling: touch;
    }
  \`;
  
  if (!document.getElementById('notilus-gpu-accel')) {
    document.head.appendChild(style);
  }
  
  console.log('Notilus: Optimisations GPU activées');
})();
''';
}

/// Scripts pour améliorer la netteté du rendu
class HdRenderingScripts {
  /// Script pour forcer le rendu HD et la netteté maximale
  static const String hdRenderingScript = '''
(function() {
  'use strict';
  if (window._notilusHdOptimized) return;
  window._notilusHdOptimized = true;
  
  // Optimiser la netteté du texte
  var style = document.createElement('style');
  style.id = 'notilus-hd-text';
  style.textContent = \`
    * {
      -webkit-font-smoothing: antialiased !important;
      -moz-osx-font-smoothing: grayscale !important;
      text-rendering: optimizeLegibility !important;
    }
    img, svg, canvas, video {
      image-rendering: -webkit-optimize-contrast !important;
      image-rendering: crisp-edges !important;
    }
  \`;
  
  if (!document.getElementById('notilus-hd-text')) {
    document.head.appendChild(style);
  }
  
  console.log('Notilus: Rendu HD activé');
})();
''';
}

/// Scripts pour les optimisations réseau
class NetworkOptimizationScripts {
  /// Script pour précharger les liens au survol
  static const String prefetchScript = '''
(function() {
  'use strict';
  if (window._notilusPrefetchInstalled) return;
  window._notilusPrefetchInstalled = true;
  
  var prefetchTimer = null;
  document.addEventListener('mouseover', function(e) {
    var link = e.target.closest('a[href]');
    if (link && link.href && !link.dataset.prefetched) {
      clearTimeout(prefetchTimer);
      prefetchTimer = setTimeout(function() {
        var prefetchLink = document.createElement('link');
        prefetchLink.rel = 'prefetch';
        prefetchLink.href = link.href;
        prefetchLink.as = 'document';
        document.head.appendChild(prefetchLink);
        link.dataset.prefetched = 'true';
      }, 100);
    }
  }, { passive: true });
  
  console.log('Notilus: Prefetch réseau activé');
})();
''';
}

/// Scripts pour les optimisations critiques au chargement
class CriticalOptimizationScripts {
  /// Script d'optimisations critiques pré-chargement
  static const String criticalScript = '''
(function() {
  'use strict';
  if (window._notilusCriticalOptimized) return;
  window._notilusCriticalOptimized = true;
  
  // Désactiver les fonctionnalités non essentielles
  Object.defineProperty(navigator, 'webdriver', {
    get: function() { return false; },
    configurable: true
  });
  
  // Précharger les ressources critiques
  var link = document.createElement('link');
  link.rel = 'preconnect';
  link.href = 'https://fonts.googleapis.com';
  document.head.appendChild(link);
  
  console.log('Notilus: Optimisations critiques activées');
})();
''';

  /// Script pour désactiver temporairement les animations pendant le chargement
  static const String disableAnimationsScript = '''
(function() {
  var style = document.createElement('style');
  style.id = 'notilus-disable-anim-load';
  style.textContent = \`
    *, *::before, *::after {
      animation-duration: 0s !important;
      animation-delay: 0s !important;
      transition-duration: 0s !important;
      transition-delay: 0s !important;
    }
  \`;
  document.head.appendChild(style);
  
  window.addEventListener('load', function() {
    setTimeout(function() {
      var styleEl = document.getElementById('notilus-disable-anim-load');
      if (styleEl) styleEl.remove();
    }, 500);
  }, { once: true });
})();
''';
}

/// Scripts pour l'optimisation du scroll
class ScrollOptimizationScripts {
  /// Script pour optimiser le scroll avec passive listeners
  static const String optimizeScrollScript = '''
(function() {
  'use strict';
  if (window._notilusScrollOptimized) return;
  window._notilusScrollOptimized = true;
  
  var ticking = false;
  var optimizedScrollHandler = function() {
    if (!ticking) {
      window.requestAnimationFrame(function() {
        ticking = false;
      });
      ticking = true;
    }
  };
  
  window.addEventListener('scroll', optimizedScrollHandler, { passive: true });
  window.addEventListener('wheel', optimizedScrollHandler, { passive: true });
  window.addEventListener('touchmove', optimizedScrollHandler, { passive: true });
})();
''';
}

/// Classe utilitaire pour appliquer toutes les optimisations
class WebViewOptimizations {
  /// Retourne tous les scripts d'optimisation à injecter
  static List<String> getAllOptimizationScripts() {
    return [
      CriticalOptimizationScripts.criticalScript,
      GpuOptimizationScripts.gpuAccelerationScript,
      HdRenderingScripts.hdRenderingScript,
      NetworkOptimizationScripts.prefetchScript,
      ScrollOptimizationScripts.optimizeScrollScript,
    ];
  }
  
  /// Retourne un script combiné pour toutes les optimisations de base
  static String getCombinedOptimizationScript() {
    return '''
(function() {
  'use strict';
  if (window._notilusFullyOptimized) return;
  window._notilusFullyOptimized = true;
  
  // GPU Acceleration
  var gpuStyle = document.createElement('style');
  gpuStyle.id = 'notilus-optimizations';
  gpuStyle.textContent = \`
    * {
      -webkit-transform: translateZ(0);
      transform: translateZ(0);
      -webkit-backface-visibility: hidden;
      backface-visibility: hidden;
      -webkit-font-smoothing: antialiased !important;
      -moz-osx-font-smoothing: grayscale !important;
      text-rendering: optimizeLegibility !important;
    }
    img, svg, canvas, video {
      image-rendering: -webkit-optimize-contrast !important;
      image-rendering: crisp-edges !important;
    }
    a, button, input, select, textarea {
      will-change: transform;
    }
    body, html {
      -webkit-overflow-scrolling: touch;
    }
  \`;
  
  if (!document.getElementById('notilus-optimizations')) {
    document.head.appendChild(gpuStyle);
  }
  
  // Prefetch on hover
  var prefetchTimer = null;
  document.addEventListener('mouseover', function(e) {
    var link = e.target.closest('a[href]');
    if (link && link.href && !link.dataset.prefetched && link.href.startsWith('http')) {
      clearTimeout(prefetchTimer);
      prefetchTimer = setTimeout(function() {
        try {
          var prefetchLink = document.createElement('link');
          prefetchLink.rel = 'prefetch';
          prefetchLink.href = link.href;
          document.head.appendChild(prefetchLink);
          link.dataset.prefetched = 'true';
        } catch(e) {}
      }, 150);
    }
  }, { passive: true });
  
  // Optimized scroll
  var ticking = false;
  var scrollHandler = function() {
    if (!ticking) {
      window.requestAnimationFrame(function() { ticking = false; });
      ticking = true;
    }
  };
  window.addEventListener('scroll', scrollHandler, { passive: true });
  window.addEventListener('wheel', scrollHandler, { passive: true });
  
  console.log('Notilus: Toutes les optimisations activées');
})();
''';
  }
}

