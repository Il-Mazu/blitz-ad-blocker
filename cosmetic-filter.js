(() => {
  'use strict';
  const hosts = ['blitz.gg', 'blitzapp.gg', 'agentselect.net', 'championselect.net',
    'lolstats.com', 'probuilds.net', 'tftcomps.gg'];
  if (location.protocol !== 'https:' || !hosts.includes(location.hostname) ||
      !/^\/v[^/]+\//.test(location.pathname) || !document.querySelector('main.blitz-app')) {
    return { active: false, reason: 'Not the Blitz desktop interface' };
  }

  // These are semantic classes observed in Blitz's live desktop renderer.
  // Avoid generated Svelte class names and generic matches for "premium".
  const adClass = '\u{1f911}';
  const selectors = [
    `[class~="${adClass}-wrapper"]`,
    `[class~="${adClass}-column"]`,
    `[class~="${adClass}-sidebar"]`,
    `[class~="${adClass}-rectangle"]`,
    'a[href*="/premium?"][href*="ref=right-rail-ads"]',
    'a[href*="/premium?"]:has(img[src*="/self-promotion/premium/"])',
    'a[href*="/premium?"]:has(img[src*="/blitz/premium/cta/"])'
  ];
  const css = `
    ${selectors.join(',\n')} { display: none !important; }
    main.blitz-app:has(> [class~="${adClass}-wrapper"]) {
      --right-rail-width: 0px !important;
      --rail-gap: 0px !important;
    }
  `;
  const id = 'blitz-local-cosmetic-filter';
  let style = document.getElementById(id);
  if (!style) {
    style = document.createElement('style');
    style.id = id;
    (document.head || document.documentElement).appendChild(style);
  }
  if (style.textContent !== css) style.textContent = css;
  return { active: true, matchedElements: document.querySelectorAll(selectors.join(',')).length };
})();
