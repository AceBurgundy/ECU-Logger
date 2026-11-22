/**
 * @typedef {Object} BadgeItem
 * @property {string} icon_name - Material icon name identifier.
 * @property {string} badge_label - Descriptive label text for badge.
 */

/**
 * @typedef {Object} CardItem
 * @property {string} title - Card header title.
 * @property {string} description - Summary of card contents.
 * @property {string} label - Category badge label.
 * @property {string} link - Destination navigation link.
 * @property {string} image_path - Relative asset path.
 * @property {boolean} shrink - Whether image should be downscaled.
 */

/**
 * @typedef {Object} SectionBlock
 * @property {string} heading_title - Section block heading.
 * @property {string} block_type - Layout block component identifier.
 * @property {string} description - Narrative paragraph description.
 * @property {string} layout_type - Layout grid structure (e.g. three_cards, two_cards).
 * @property {Array<CardItem>} cards - List of card items rendered in the container.
 */

/**
 * @typedef {Object} TabItem
 * @property {string} tab_title - Tab title label.
 * @property {string} icon_name - Material icon identifier.
 * @property {Array<SectionBlock>} section_blocks - Ordered content blocks rendered within the tab.
 */

/**
 * @typedef {Object} DashboardDefinition
 * @property {string} item_title - Page title.
 * @property {string} icon_name - Material icon name.
 * @property {Object} header_container - Header configuration.
 * @property {Array<TabItem>} tab_list - Array of navigation tabs.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {DashboardDefinition} */
const dashboardDefinition = {
  item_title: "Dashboard",
  icon_name: "dashboard",
  header_container: {
    title: "ECU Logger",
    description: "High-performance standalone CAN bus and OBD-II telemetry logging engine with Option 3 Minimalist Dashboard, dynamic 4-digit PIN translucent lock screen, and real-time Volumetric Efficiency (VE%) matrix accumulator.",
    badge_list: [
      { icon_name: "palette", badge_label: "GitHub Primer Theme" },
      { icon_name: "speed", badge_label: "50-100Hz CAN Passive Sniffing" },
      { icon_name: "lock", badge_label: "Pocket Touch Overlay" },
      { icon_name: "verified", badge_label: "MPL-2.0 License" }
    ],
    banner_image: {
      image_path: "assets/icon.png",
      shrink: true
    },
    mockup_card: {
      image_path: "assets/scale.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "Overview",
      icon_name: "dashboard",
      section_blocks: [
        {
          heading_title: "Core Architectural Pillars",
          block_type: "cards_container",
          description: "Essential architectural capabilities engineered for robust background logging on two wheels.",
          layout_type: "three_cards",
          cards: [
            {
              title: "Option 3 Minimalist Dashboard",
              description: "6 high-contrast digital cards (RPM, TPS, MAP kPa, VE%, ECT °C, VVA) and collapsible bottom Monospace Log Drawer.",
              label: "UI & Monitoring",
              link: "data/navigation-items/minimalist-dashboard.js",
              image_path: "",
              shrink: false
            },
            {
              title: "Translucent Pocket Lock",
              description: "Dynamic 4-digit challenge PIN overlay that prevents accidental pocket touches without interrupting continuous logging.",
              label: "Safety & Integrity",
              link: "data/navigation-items/pocket-lock-protection.js",
              image_path: "",
              shrink: false
            },
            {
              title: "Dual-Stream File Engine",
              description: "Streams raw_can.log, telemetry.csv, and remap_matrix.json with automated buffered flushing on app pause or disconnect.",
              label: "Storage & Tuning",
              link: "data/navigation-items/telemetry-and-matrix.js",
              image_path: "",
              shrink: false
            }
          ]
        },
        {
          heading_title: "Getting Started & System Integration",
          block_type: "cards_container",
          description: "Deploying ECU Logger on Pixel 8 and pairing with NEXAS NexLink BLE adapter.",
          layout_type: "two_cards",
          cards: [
            {
              title: "Architecture & Data Pipeline",
              description: "Complete breakdown of the ELM327 command loop, CAN frame parsing, and Speed-Density calculations.",
              label: "Architecture",
              link: "data/navigation-items/architecture-and-pipeline.js",
              image_path: "",
              shrink: false
            },
            {
              title: "Full API & Protocol Reference",
              description: "In-depth class references, packet formats, and remap matrix JSON structure.",
              label: "API Reference",
              link: "data/navigation-items/api-reference.js",
              image_path: "",
              shrink: false
            }
          ]
        }
      ]
    }
  ]
};

window.DOCUMENTATION_ITEMS["data/dashboard.js"] = dashboardDefinition;
