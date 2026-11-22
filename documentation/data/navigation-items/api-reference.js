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
 * @property {Array<Object>} tab_list - Tabs containing section blocks and API details.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const apiReferenceDefinition = {
  item_title: "API Reference",
  icon_name: "code",
  header_container: {
    title: "Comprehensive API & Architecture Reference",
    description: "Exhaustive class signatures, static helpers, and event subscriptions across the ECU Logger package.",
    badge_list: [
      { icon_name: "developer_board", badge_label: "Dart Classes" },
      { icon_name: "integration_instructions", badge_label: "Public APIs" }
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
      tab_title: "Classes & Services",
      icon_name: "menu_book",
      section_blocks: [
        {
          block_type: "table",
          heading_title: "Core Services Summary",
          columns: ["Class", "Type", "Responsibilities"],
          rows: [
            ["BleService", "Singleton", "BLE peripheral scanning, service discovery, Rx/Tx characteristics, reconnection, mock simulation."],
            ["Elm327Protocol", "Static Utility", "AT command sequences, response buffer sanitization, Mode 01 PID parsing, CAN frame decoding."],
            ["TelemetryEngine", "ChangeNotifier", "Metric state holder, VE calculations, VVA hysteresis logic, rolling log buffer (200 lines)."],
            ["FileLoggerService", "Singleton", "Buffered asynchronous logging to raw CAN log, telemetry CSV, and remap matrix JSON."],
            ["ToastService", "Static Utility", "Top-centered pill notification presentation with smooth slide and fade animations."]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/api-reference.js"] = apiReferenceDefinition;
