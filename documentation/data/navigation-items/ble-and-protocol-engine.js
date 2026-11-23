window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const bleAndProtocolEngineDefinition = {
  item_title: "BLE & Protocol Engine",
  icon_name: "bluetooth",
  header_container: {
    title: "BLE Connection & ELM327 Protocol Engine",
    description: "Resilient Bluetooth Low Energy UART transport layer supporting NEXAS NexLink BLE 5.0 and standard ELM327 OBD-II AT command sequences.",
    badge_list: [
      { icon_name: "bluetooth_searching", badge_label: "BLE 5.0 UART" },
      { icon_name: "memory", badge_label: "ELM327 AT Sequence" },
      { icon_name: "sensors", badge_label: "Mode 01 + Raw CAN" }
    ],
    banner_image: {
      image_path: "assets/console_log.png",
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
          paragraph_text: "BleService manages BLE peripheral scanning, RSSI/OBD device prioritization (placing NEXAS NexLink and FFF0 UART adapters first), characteristic notification binding, and automatic state reporting. The bottom-right Bluetooth FAB communicates status immediately: Grey (Disconnected), Amber (Scanning or Connecting), Green (Connected & Streaming), and Red (Error)."
        },
        {
          block_type: "table",
          heading_title: "ELM327 Command Initialization Sequence",
          table_headers: ["Command", "Action", "Purpose"],
          table_rows: [
            ["ATZ", "Reset Chip", "Clears pending buffers and resets ELM327 firmware"],
            ["ATE0", "Echo Off", "Prevents command echo duplication in Rx data stream"],
            ["ATL0", "Linefeeds Off", "Reduces frame overhead for faster throughput"],
            ["ATH1", "Headers On", "Preserves 11-bit CAN IDs (e.g. 770, 212, 236, 240)"],
            ["ATSP6", "Set Protocol 6", "Locks adapter to ISO 15765-4 CAN (11-bit ID, 500 kbaud)"]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/ble-and-protocol-engine.js"] = bleAndProtocolEngineDefinition;
