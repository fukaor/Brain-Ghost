// bootstrap.js — injects the React runtime and compiles local JSX at runtime.
// We keep this logic in an external JS file so the HTML stays script-tag-free.

(function () {
  function addScript(src, opts) {
    return new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src = src;
      if (opts && opts.integrity) { s.integrity = opts.integrity; s.crossOrigin = 'anonymous'; }
      s.onload = function () { resolve(s); };
      s.onerror = reject;
      document.body.appendChild(s);
    });
  }

  async function boot() {
    await addScript(
      'https://unpkg.com/react@18.3.1/umd/react.development.js',
      { integrity: 'sha384-hD6/rw4ppMLGNu3tX5cjIb+uRZ7UkRJ6BPkLpg4hAu/6onKUg4lLsHAs9EBPT82L' }
    );
    await addScript(
      'https://unpkg.com/react-dom@18.3.1/umd/react-dom.development.js',
      { integrity: 'sha384-u6aeetuaXnQ38mYT8rp6sbXaQe3NL9t+IBXmnYxwkUI2Hw4bsp2Wvmx4yRQF1uAm' }
    );
    await addScript(
      'https://unpkg.com/@babel/standalone@7.29.0/babel.min.js',
      { integrity: 'sha384-m08KidiNqLdpJqLq95G/LEi8Qvjl/xUYll3QILypMoQ65QorJ9Lvtp2RXYGBFj1y' }
    );

    // Fetch + transpile each JSX file in order, then inject as plain inline scripts
    var files = ['android-frame.jsx', 'components.jsx', 'screens.jsx', 'app.jsx'];
    for (var i = 0; i < files.length; i++) {
      var res = await fetch(files[i]);
      if (!res.ok) throw new Error('fetch ' + files[i] + ': ' + res.status);
      var src = await res.text();
      var out = window.Babel.transform(src, { presets: ['react'] }).code;
      var s = document.createElement('script');
      s.textContent = out;
      document.body.appendChild(s);
    }
  }

  boot().catch(function (e) {
    var d = document.createElement('pre');
    d.style.cssText = 'padding:16px;color:#b00;white-space:pre-wrap;font-family:monospace';
    d.textContent = 'Bootstrap error: ' + (e && e.message || e);
    document.body.appendChild(d);
  });
})();
