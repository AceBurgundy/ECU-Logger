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
    
    // Compute the base directory of the current page (e.g. "https://aceburgundy.github.io/ECU-Logger/")
    const pathSegments = window.location.pathname.split("/").filter(Boolean);
    // If the last segment has an extension (.html), pop it
    if (pathSegments.length > 0 && pathSegments[pathSegments.length - 1].includes(".")) {
      pathSegments.pop();
    }
    const repoBase = pathSegments.length > 0 ? `/${pathSegments.join("/")}/` : "/";
    const cleanPath = navigationPath.startsWith("./")
      ? navigationPath.slice(2)
      : (navigationPath.startsWith("/") ? navigationPath.slice(1) : navigationPath);
    
    const resolvedUrl = `${window.location.origin}${repoBase}${cleanPath}`;
    
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
