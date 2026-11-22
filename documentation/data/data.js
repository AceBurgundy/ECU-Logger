/**
 * @typedef {Object} CategoryGroup
 * @property {string} category_title - Display title of category grouping.
 * @property {Array<string>} navigation_item_paths - Relative paths to member navigation item definitions.
 */

/**
 * @typedef {Object} DocumentationData
 * @property {string} dashboard_path - Path to main dashboard configuration script.
 * @property {string} footer_path - Path to footer configuration script.
 * @property {Array<CategoryGroup>} category_groups - Grouped categories for the documentation sidebar.
 */

/** @type {DocumentationData} */
const documentationData = {
  dashboard_path: "data/dashboard.js",
  footer_path: "data/footer.js",
  category_groups: [
    {
      category_title: "Getting Started",
      navigation_item_paths: [
        "data/navigation-items/overview-and-tenets.js",
        "data/navigation-items/architecture-and-pipeline.js"
      ]
    },
    {
      category_title: "Core Modules & UI",
      navigation_item_paths: [
        "data/navigation-items/minimalist-dashboard.js",
        "data/navigation-items/pocket-lock-protection.js"
      ]
    },
    {
      category_title: "Protocols & Engine",
      navigation_item_paths: [
        "data/navigation-items/ble-and-protocol-engine.js",
        "data/navigation-items/telemetry-and-matrix.js"
      ]
    },
    {
      category_title: "Technical Reference",
      navigation_item_paths: [
        "data/navigation-items/api-reference.js"
      ]
    }
  ]
};

window.DOCUMENTATION_DATA = documentationData;
export default documentationData;
