window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};
window.DOCUMENTATION_ITEMS["data/navigation-items/api-reference.js"] = {
  "item_title": "API Reference",
  "icon_name": "code",
  "header_container": {
    "title": "Comprehensive API & Architecture Reference",
    "description": "Exhaustive class signatures, static helpers, and event subscriptions across the ecu_logger package.",
    "badge_list": [
      { "icon_name": "developer_board", "badge_label": "Dart Classes" },
      { "icon_name": "integration_instructions", "badge_label": "Public APIs" }
    ],
    "banner_image": {
      "image_path": "assets/icon.png",
      "shrink": true
    },
    "mockup_card": {
      "image_path": "assets/input.png",
      "shrink": true
    }
  },
  "tab_list": [
    {
      "tab_title": "Classes & Services",
      "icon_name": "menu_book",
      "section_blocks": [
        {
          "block_type": "table",
          "heading_title": "Core Services Summary",
          "columns": ["Class", "Type", "Responsibilities"],
          "rows": [
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
  "hide_tabs": false,
  "hide_toc": false
};
