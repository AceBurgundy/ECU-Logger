window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const apiReferenceDefinition = {
  item_title: "API Reference",
  icon_name: "code",
  header_container: {
    title: "Comprehensive API & Service Reference",
    description: "Exhaustive class responsibilities, UI widgets, layout services, and telemetry contracts across ECU Logger.",
    badge_list: [
      { icon_name: "developer_board", badge_label: "Dart & Flutter SDK" },
      { icon_name: "integration_instructions", badge_label: "Public Services & Widgets" }
    ],
    banner_image: {
      image_path: "assets/font_dialog.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "Services & UI Widgets",
      icon_name: "menu_book",
      section_blocks: [
        {
          block_type: "table",
          heading_title: "Core Services & Models",
          table_headers: ["Class", "Type", "Responsibilities"],
          table_rows: [
            ["BleService", "Singleton", "BLE peripheral scanning, OBD adapter prioritization, Rx/Tx GATT streams, and connection management."],
            ["Elm327Protocol", "Static Utility", "AT command sequences, response sanitization, Mode 01 PID parsing, and Yamaha CAN frame decoding."],
            ["TelemetryEngine", "ChangeNotifier", "Live metric state snapshot, Speed-Density VE math, VVA hysteresis, and 200-line rolling log buffer."],
            ["DashboardLayoutService", "ChangeNotifier", "Persists active & saved Cockpit Designs (JSON), manages Edit Mode drafts, and drives Frozen Previews."],
            ["FileLoggerService", "Singleton", "Buffered asynchronous writes for raw CAN logs, CSV telemetry rows, and 16x11 JSON remap matrices."]
          ]
        },
        {
          block_type: "table",
          heading_title: "Cockpit UI Components",
          table_headers: ["Widget", "Role", "Key Capabilities"],
          table_rows: [
            ["DashboardFlowLayout", "StatefulWidget", "4-column 2D grid packer, AnimatedPositioned slide reflow, drag-only jiggle, unclipped 8-point pixel resize overlay."],
            ["MetricCard", "StatelessWidget", "View Mode flush telemetry card & Edit Mode bordered card with active neon yellow handles."],
            ["SavedLayoutsDialog", "StatefulWidget", "Wireframe carousel previewing persisted 4-column cockpit layouts with Delete and Frozen Preview actions."],
            ["LockOverlay", "StatefulWidget", "Translucent pocket-touch protection screen with randomized 4-digit PIN keypad."],
            ["LogDrawer", "StatefulWidget", "Collapsible bottom monospace console drawer rendered in Google Sans Code."]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/api-reference.js"] = apiReferenceDefinition;
