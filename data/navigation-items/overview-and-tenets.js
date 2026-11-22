window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};
window.DOCUMENTATION_ITEMS["data/navigation-items/overview-and-tenets.js"] = {
  "item_title": "Overview & Tenets",
  "icon_name": "info",
  "header_container": {
    "title": "ECU Logger Overview & Core Tenets",
    "description": "Engineered for high-frequency motorcycle telemetry acquisition, active CAN bus monitoring, and non-intrusive road logging.",
    "badge_list": [
      { "icon_name": "motorcycle", "badge_label": "Motorcycle Telemetry" },
      { "icon_name": "bolt", "badge_label": "High Frequency" },
      { "icon_name": "shield", "badge_label": "Pocket Touch Immune" }
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
      "tab_title": "Overview",
      "icon_name": "overview",
      "section_blocks": [
        {
          "block_type": "paragraph",
          "heading_title": "Mission & Philosophy",
          "content": "ecu_logger is a dedicated, decoupled mobile telemetry logger application designed to capture real-time broadcast CAN bus data from Yamaha motorcycles via the NEXAS NexLink BLE adapter. Its sole mission is seamless, zero-lag background logging to device storage without crashes or accidental pocket touch disruption."
        },
        {
          "block_type": "table",
          "heading_title": "Core Engineering Tenets",
          "columns": ["Tenet", "Implementation", "Operational Impact"],
          "rows": [
            ["Zero Touch Lock", "Dynamic 4-digit challenge overlay", "Allows rider to place phone into pocket without stopping logging or triggering buttons."],
            ["Dual-Stream File Engine", "Buffered asynchronous file sink", "Simultaneously writes raw CAN frames, structured CSV, and JSON remap matrix."],
            ["Lifecycle Auto-Save", "WidgetsBindingObserver hooks", "Automatically flushes and saves logs when app is paused, backgrounded, or BLE disconnects."],
            ["Option 3 Minimalist Dashboard", "GitHub Primer dark palette", "High-contrast digital readouts visible in direct sunlight and night riding."]
          ]
        }
      ]
    }
  ],
  "hide_tabs": false,
  "hide_toc": false
};
