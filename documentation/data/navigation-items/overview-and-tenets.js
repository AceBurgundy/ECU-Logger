/**
 * @typedef {Object} NavigationItemHeader
 * @property {string} title - Header display title.
 * @property {string} description - High-level summary of the module.
 * @property {Array<{icon_name: string, badge_label: string}>} badge_list - Status badges.
 * @property {{image_path: string, shrink: boolean}} banner_image - Banner image configuration.
 * @property {{image_path: string, shrink: boolean}} mockup_card - Mockup presentation card.
 */

/**
 * @typedef {Object} NavigationItemDefinition
 * @property {string} item_title - Title shown in navigation tree.
 * @property {string} icon_name - Material icon name.
 * @property {NavigationItemHeader} header_container - Header content container.
 * @property {Array<Object>} tab_list - Tabs containing section blocks and narrative.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const overviewAndTenetsDefinition = {
  item_title: "Overview & Tenets",
  icon_name: "info",
  header_container: {
    title: "ECU Logger Overview & Core Tenets",
    description: "Engineered for high-frequency motorcycle telemetry acquisition, active CAN bus monitoring, and non-intrusive road logging.",
    badge_list: [
      { icon_name: "motorcycle", badge_label: "Motorcycle Telemetry" },
      { icon_name: "bolt", badge_label: "High Frequency" },
      { icon_name: "shield", badge_label: "Pocket Touch Immune" }
    ],
    banner_image: {
      image_path: "assets/icon.png",
      shrink: true
    },
    mockup_card: {
      image_path: "assets/input.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "Overview",
      icon_name: "overview",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Mission & Philosophy",
          content: "ECU Logger is a dedicated, decoupled mobile telemetry logger application designed to capture real-time broadcast CAN bus data from Yamaha motorcycles via the NEXAS NexLink BLE adapter. Its sole mission is seamless, zero-lag background logging to device storage without crashes or accidental pocket touch disruption."
        },
        {
          block_type: "table",
          heading_title: "Core Engineering Tenets",
          columns: ["Tenet", "Implementation", "Operational Impact"],
          rows: [
            ["Zero Touch Lock", "Dynamic 4-digit challenge overlay", "Allows rider to place phone into pocket without stopping logging or triggering buttons."],
            ["Dual-Stream File Engine", "Buffered asynchronous file sink", "Simultaneously writes raw CAN frames, structured CSV, and JSON remap matrix."],
            ["Lifecycle Auto-Save", "WidgetsBindingObserver hooks", "Automatically flushes and saves logs when app is paused, backgrounded, or BLE disconnects."],
            ["Option 3 Minimalist Dashboard", "GitHub Primer dark palette", "High-contrast digital readouts visible in direct sunlight and night riding."]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/overview-and-tenets.js"] = overviewAndTenetsDefinition;
