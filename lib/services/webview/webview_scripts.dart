/// Scripts JavaScript pour le WebView2BrowserEngine
/// Centralisés ici pour une meilleure maintenabilité
library webview_scripts;

/// Scripts d'interception des nouvelles fenêtres (window.open, target="_blank")
class NewWindowScripts {
  /// Script minifié pour intercepter les demandes de nouvelles fenêtres
  static const String interceptScript = '''(function(){var o=window.open;window.open=function(u,t,f){if(!t||t==="_blank"||t==="blank"){if(u&&typeof u==="string"){if(document.body){document.body.setAttribute("data-new-window-url",u);document.body.dispatchEvent(new Event("notilus-new-window"));}}return null;}return o.apply(window,arguments);};var h=function(e){var t=e.target;while(t&&t.tagName!=="A"){t=t.parentElement;}if(t&&t.tagName==="A"){var h=t.getAttribute("href"),a=t.getAttribute("target"),r=(t.getAttribute("rel")||"").toLowerCase(),e=!1,n=a==="_blank"||a==="blank";if(h&&h.startsWith("http")){try{var i=window.location.hostname,c=new URL(h,window.location.href);e=c.hostname!==i;}catch(e){}}if(r.includes("external")){e=!0;}if(n||e){e.preventDefault();e.stopPropagation();if(document.body&&h){try{var u=new URL(h,window.location.href).href;document.body.setAttribute("data-new-window-url",u);document.body.dispatchEvent(new Event("notilus-new-window"));}catch(e){document.body.setAttribute("data-new-window-url",h);document.body.dispatchEvent(new Event("notilus-new-window"));}}return!1;}}};if(window._flutterNewWindowHandler){document.removeEventListener("click",window._flutterNewWindowHandler,!0);}window._flutterNewWindowHandler=h;document.addEventListener("click",h,!0);if(!window._flutterMutationObserver){window._flutterMutationObserver=new MutationObserver(function(e){e.forEach(function(e){e.addedNodes.forEach(function(e){if(1===e.nodeType){var t=e.querySelectorAll?e.querySelectorAll('a[target="_blank"],a[rel*="external"]'):[];t.forEach(function(e){e.addEventListener("click",h,!0);});}});});});window._flutterMutationObserver.observe(document.body,{childList:!0,subtree:!0});}})();''';
  
  /// Script pour récupérer l'URL de nouvelle fenêtre depuis l'attribut data
  static const String getNewWindowUrlScript = '''
    (function() {
      if (!document.body) return null;
      var url = document.body.getAttribute('data-new-window-url');
      if (url) {
        document.body.removeAttribute('data-new-window-url');
        return url;
      }
      return null;
    })();
  ''';
}

/// Scripts pour la détection de sélection de texte
class TextSelectionScripts {
  static const String installScript = '''
(function() {
  if (window._notilusTextSelectionHandler) return;
  
  window._notilusTextSelectionHandler = function() {
    try {
      var selection = window.getSelection();
      if (selection && selection.rangeCount > 0) {
        var text = selection.toString().trim();
        if (text.length > 0) {
          var range = selection.getRangeAt(0);
          var rect = range.getBoundingClientRect();
          
          if (document.body) {
            var x = Math.round(rect.left + rect.width / 2);
            var y = Math.round(rect.top);
            document.body.setAttribute('data-selected-text', encodeURIComponent(text));
            document.body.setAttribute('data-selection-x', x.toString());
            document.body.setAttribute('data-selection-y', y.toString());
          }
        } else {
          if (document.body) {
            document.body.removeAttribute('data-selected-text');
            document.body.removeAttribute('data-selection-x');
            document.body.removeAttribute('data-selection-y');
          }
        }
      } else {
        if (document.body) {
          document.body.removeAttribute('data-selected-text');
          document.body.removeAttribute('data-selection-x');
          document.body.removeAttribute('data-selection-y');
        }
      }
    } catch (e) {
      console.error('Notilus: Erreur dans le handler de sélection:', e);
    }
  };
  
  document.addEventListener('mouseup', function() {
    setTimeout(window._notilusTextSelectionHandler, 100);
  }, true);
  document.addEventListener('keyup', window._notilusTextSelectionHandler, true);
  document.addEventListener('selectionchange', window._notilusTextSelectionHandler, true);
  
  console.log('Notilus: Script de sélection de texte installé');
})();
''';

  static const String getSelectionScript = '''
    (function() {
      if (!document.body) return null;
      var text = document.body.getAttribute('data-selected-text');
      var x = document.body.getAttribute('data-selection-x');
      var y = document.body.getAttribute('data-selection-y');
      if (text && x && y) {
        document.body.removeAttribute('data-selected-text');
        document.body.removeAttribute('data-selection-x');
        document.body.removeAttribute('data-selection-y');
        return JSON.stringify({text: decodeURIComponent(text), x: parseInt(x), y: parseInt(y)});
      }
      return null;
    })();
  ''';
}

/// Scripts pour le menu contextuel
class ContextMenuScripts {
  static const String installScript = '''
(function() {
  if (window._notilusContextMenuHandler) return;
  
  window._notilusContextMenuHandler = function(e) {
    try {
      e.preventDefault();
      
      var target = e.target;
      var elementType = 'text';
      var url = null;
      var imageUrl = null;
      var linkUrl = null;
      var text = null;
      
      if (target.tagName === 'IMG') {
        elementType = 'image';
        imageUrl = target.src || target.getAttribute('data-src') || target.getAttribute('data-lazy-src');
        var parent = target.parentElement;
        while (parent && parent.tagName !== 'A' && parent !== document.body) {
          parent = parent.parentElement;
        }
        if (parent && parent.tagName === 'A') {
          linkUrl = parent.href;
        }
      } else if (target.tagName === 'A') {
        elementType = 'link';
        linkUrl = target.href;
        var img = target.querySelector('img');
        if (img) {
          imageUrl = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src');
        }
        text = target.textContent || target.innerText;
      } else {
        var parent = target;
        while (parent && parent.tagName !== 'A' && parent !== document.body) {
          parent = parent.parentElement;
        }
        if (parent && parent.tagName === 'A') {
          elementType = 'link';
          linkUrl = parent.href;
          var img = parent.querySelector('img');
          if (img) {
            imageUrl = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src');
          }
          text = parent.textContent || parent.innerText;
        } else {
          var selection = window.getSelection();
          if (selection && selection.rangeCount > 0) {
            text = selection.toString().trim();
            if (text.length > 0) {
              elementType = 'text';
            }
          }
        }
      }
      
      if (document.body) {
        var x = Math.round(e.clientX);
        var y = Math.round(e.clientY);
        
        document.body.setAttribute('data-context-type', elementType);
        document.body.setAttribute('data-context-x', x.toString());
        document.body.setAttribute('data-context-y', y.toString());
        
        if (imageUrl) {
          document.body.setAttribute('data-context-image-url', encodeURIComponent(imageUrl));
        }
        if (linkUrl) {
          document.body.setAttribute('data-context-link-url', encodeURIComponent(linkUrl));
        }
        if (text) {
          document.body.setAttribute('data-context-text', encodeURIComponent(text));
        }
      }
    } catch (err) {
      console.error('Notilus: Erreur dans le handler de menu contextuel:', err);
    }
  };
  
  document.addEventListener('contextmenu', window._notilusContextMenuHandler, true);
  
  console.log('Notilus: Script de menu contextuel installé');
})();
''';

  static const String getContextMenuScript = '''
    (function() {
      if (!document.body) return null;
      var type = document.body.getAttribute('data-context-type');
      var x = document.body.getAttribute('data-context-x');
      var y = document.body.getAttribute('data-context-y');
      if (type && x && y) {
        var imageUrl = document.body.getAttribute('data-context-image-url');
        var linkUrl = document.body.getAttribute('data-context-link-url');
        var text = document.body.getAttribute('data-context-text');
        
        document.body.removeAttribute('data-context-type');
        document.body.removeAttribute('data-context-x');
        document.body.removeAttribute('data-context-y');
        document.body.removeAttribute('data-context-image-url');
        document.body.removeAttribute('data-context-link-url');
        document.body.removeAttribute('data-context-text');
        
        return JSON.stringify({
          type: type,
          x: parseInt(x),
          y: parseInt(y),
          imageUrl: imageUrl ? decodeURIComponent(imageUrl) : null,
          linkUrl: linkUrl ? decodeURIComponent(linkUrl) : null,
          text: text ? decodeURIComponent(text) : null
        });
      }
      return null;
    })();
  ''';
}

/// Scripts pour l'interception des téléchargements
class DownloadScripts {
  static const String installScript = '''
    (function() {
      if (window._flutterDownloadHandlerInstalled) return null;
      window._flutterDownloadHandlerInstalled = true;
      window._pendingDownloads = [];
      
      var downloadExtensions = [
        '.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz',
        '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.odt', '.ods', '.odp',
        '.exe', '.msi', '.dmg', '.deb', '.rpm', '.apk', '.ipa', '.app',
        '.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma',
        '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm',
        '.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.bmp', '.ico', '.tiff',
        '.iso', '.img', '.bin', '.torrent',
        '.csv', '.json', '.xml', '.sql', '.db',
        '.ttf', '.otf', '.woff', '.woff2'
      ];
      
      function isDownloadUrl(href) {
        if (!href) return false;
        var lowerHref = href.toLowerCase();
        
        for (var i = 0; i < downloadExtensions.length; i++) {
          var ext = downloadExtensions[i];
          var idx = lowerHref.lastIndexOf(ext);
          if (idx !== -1) {
            var afterExt = lowerHref.substring(idx + ext.length);
            if (afterExt === '' || afterExt.charAt(0) === '?' || afterExt.charAt(0) === '#') {
              return true;
            }
          }
        }
        
        if (lowerHref.indexOf('/download/') !== -1 || 
            lowerHref.indexOf('/downloads/') !== -1 ||
            lowerHref.indexOf('action=download') !== -1 ||
            lowerHref.indexOf('download=') !== -1 ||
            lowerHref.indexOf('/attachment') !== -1 ||
            lowerHref.indexOf('?file=') !== -1 ||
            lowerHref.indexOf('&file=') !== -1) {
          return true;
        }
        
        return false;
      }
      
      function extractFileName(href, downloadAttr) {
        if (downloadAttr) return downloadAttr;
        try {
          var url = new URL(href, window.location.href);
          var path = url.pathname;
          var fileName = path.substring(path.lastIndexOf('/') + 1);
          if (fileName && fileName.indexOf('.') !== -1) {
            return decodeURIComponent(fileName.split('?')[0]);
          }
        } catch(e) {}
        return null;
      }
      
      document.addEventListener('click', function(e) {
        var target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }
        
        if (target && target.tagName === 'A') {
          var href = target.getAttribute('href');
          var download = target.getAttribute('download');
          
          if (download !== null || isDownloadUrl(href)) {
            e.preventDefault();
            e.stopPropagation();
            
            try {
              var fullUrl = new URL(href, window.location.href).href;
              var fileName = extractFileName(href, download);
              
              window._pendingDownloads.push({
                url: fullUrl,
                fileName: fileName
              });
            } catch(err) {
              window._pendingDownloads.push({
                url: href,
                fileName: download || null
              });
            }
            
            return false;
          }
        }
      }, true);
      
      document.addEventListener('submit', function(e) {
        var form = e.target;
        if (form && form.tagName === 'FORM') {
          var action = form.getAttribute('action') || '';
          if (isDownloadUrl(action)) {
            try {
              var fullUrl = new URL(action, window.location.href).href;
              window._pendingDownloads.push({
                url: fullUrl,
                fileName: extractFileName(action, null)
              });
            } catch(e) {}
          }
        }
      }, true);
      
      return null;
    })();
  ''';

  static const String getPendingDownloadsScript = '''
    (function() {
      if (window._pendingDownloads && window._pendingDownloads.length > 0) {
        var downloads = JSON.stringify(window._pendingDownloads);
        window._pendingDownloads = [];
        return downloads;
      }
      return null;
    })();
  ''';
}

/// Scripts pour masquer les scrollbars
class ScrollbarScripts {
  static const String hideScrollbarsScript = '''
    (function() {
      var style = document.createElement('style');
      style.id = 'notilus-hide-scrollbars';
      style.textContent = \`
        * {
          scrollbar-width: none !important;
          -ms-overflow-style: none !important;
        }
        *::-webkit-scrollbar {
          display: none !important;
          width: 0 !important;
          height: 0 !important;
        }
        html, body {
          scrollbar-width: none !important;
          -ms-overflow-style: none !important;
        }
        html::-webkit-scrollbar,
        body::-webkit-scrollbar {
          display: none !important;
          width: 0 !important;
          height: 0 !important;
        }
      \`;
      
      if (!document.getElementById('notilus-hide-scrollbars')) {
        document.head.appendChild(style);
      }
    })();
  ''';
}

