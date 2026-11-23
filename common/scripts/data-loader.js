/**
 * Asynchronously fetches and parses documentation navigation item specifications.
 * Uses window.DOCUMENTATION_ITEMS cache when available.
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
    
    // Resolve relative to the application base URI so GitHub Pages sub-paths work perfectly
    const cleanPath = navigationPath.startsWith("./")
      ? navigationPath.slice(2)
      : (navigationPath.startsWith("/") ? navigationPath.slice(1) : navigationPath);
    
    const baseUrl = new URL("./", window.location.href);
    const resolvedUrl = new URL(cleanPath, baseUrl).href;
    
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
