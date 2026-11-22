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
 * @property {Array<Object>} tab_list - Tabs containing section blocks and protocol specifications.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const bleAndProtocolEngineDefinition = {
  item_title: "BLE & Protocol Engine",
  icon_name: "bluetooth",
  header_container: {
    title: "BLE Connection & ELM327 Protocol Engine",
    description: "Robust Bluetooth Low Energy transport layer supporting NEXAS NexLink BLE and standard ELM327 command sets.",
    badge_list: [
      { icon_name: "bluetooth_audio", badge_label: "BLE 5.0 UART" },
      { icon_name: "memory", badge_label: "ELM327 AT Command Set" }
    ],
    banner_image: {
      image_path: "assets/icon.png",
      shrink: true
    },
    mockup_card: {
      image_path: "assets/selection.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "BLE Protocol",
      icon_name: "settings_input_antenna",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Bluetooth Connection Management",
          content: "BleService manages automated peripheral discovery, SPP UART characteristic binding, and reconnection loops. A floating action button dynamically reflects connection status: Grey (Disconnected), Orange (Scanning / Connecting), Green (Connected)."
        },
        {
          block_type: "table",
          heading_title: "ELM327 Command Initialization Sequence",
          columns: ["Command", "Action", "Purpose"],
          rows: [
            ["ATZ", "Reset Chip", "Clears pending buffers and resets ELM firmware"],
            ["ATE0", "Echo Off", "Prevents duplicate command echoes in the data stream"],
            ["ATL0", "Linefeeds Off", "Suppresses trailing carriage returns for higher baud rate"],
            ["ATH1", "Headers On", "Preserves CAN 11-bit identifier headers (e.g. 770, 212)"],
            ["ATSP6", "Set Protocol 6", "Locks protocol to ISO 15765-4 CAN (11-bit ID, 500 kbaud)"]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/ble-and-protocol-engine.js"] = bleAndProtocolEngineDefinition;
