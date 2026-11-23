/**
 * Asynchronously fetches and parses documentation navigation item specifications.
 * Uses window.DOCUMENTATION_ITEMS cache when available and resolves script URLs
 * relative to this module's root directory (immune to SPA history path changes).
 * @param {string} navigationPath - Target navigation item path (e.g. "data/navigation-items/overview-and-tenets.js" or "data/dashboard.js").
 * @returns {Promise<Object>} Resolved navigation item specification.
 */
export async function fetchNavigationItemData(navigationPath) {
  if (typeof window === "undefined") {
    return {};
  }

  window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

  if (window.DOCUMENTATION_ITEMS[navigationPath]) {
    return window.DOCUMENTATION_ITEMS[navigationPath];
  }

  return new Promise((resolve, reject) => {
    /** @type {HTMLScriptElement} */
    const scriptElement = document.createElement("script");

    const cleanPath = navigationPath.startsWith("./")
      ? navigationPath.slice(2)
      : (navigationPath.startsWith("/") ? navigationPath.slice(1) : navigationPath);

    // data-loader.js resides at <docs-root>/common/scripts/data-loader.js
    const resolvedUrl = new URL(`../../${cleanPath}`, import.meta.url).href;

    scriptElement.src = resolvedUrl;
    scriptElement.onload = () => {
      if (window.DOCUMENTATION_ITEMS[navigationPath]) {
        resolve(window.DOCUMENTATION_ITEMS[navigationPath]);
      } else {
        reject(
          new Error(
            `Script loaded for ${navigationPath} but window.DOCUMENTATION_ITEMS["${navigationPath}"] was undefined.`
          )
        );
      }
    };
    scriptElement.onerror = () => {
      reject(
        new Error(
          `Failed to load navigation item script from path: ${resolvedUrl}`
        )
      );
    };
    document.head.appendChild(scriptElement);
  });
}
