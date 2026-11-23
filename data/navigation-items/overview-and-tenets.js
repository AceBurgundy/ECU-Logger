window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const overviewAndTenetsDefinition = {
  item_title: "Overview & Tenets",
  icon_name: "info",
  header_container: {
    title: "ECU Logger Overview & Core Tenets",
    description: "Engineered for high-frequency motorcycle telemetry acquisition, active CAN bus monitoring, and distraction-free road logging.",
    badge_list: [
      { icon_name: "two_wheeler", badge_label: "Motorcycle Telemetry" },
      { icon_name: "bolt", badge_label: "50-100Hz Acquisition" },
      { icon_name: "shield", badge_label: "Pocket Touch Immune" }
    ],
    banner_image: {
      image_path: "assets/dashboard.png",
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
          paragraph_text: "ECU Logger is a dedicated mobile telemetry logger engineered to capture real-time broadcast CAN bus and OBD-II data from motorcycles via NEXAS NexLink BLE 5.0 and standard ELM327 adapters. It delivers zero-lag background logging, live Speed-Density Volumetric Efficiency calculation, and a customizable 4-column GitHub Primer cockpit."
        },
        {
          block_type: "table",
          heading_title: "Core Engineering Tenets",
          table_headers: ["Tenet", "Implementation", "Operational Impact"],
          table_rows: [
            ["Adaptive 4-Column Cockpit", "Default 2x2 cards resizable 1..4 cols x 1..4 rows", "Renders clean 2-up default readouts on install while scaling freely up to full-width 4x4 priority gauges."],
            ["Zero-Lag Pixel Resizing", "Unclipped 28px border & corner hit zones", "Dragged corners and edges follow the rider's hand pixel-for-pixel and snap cleanly on release."],
            ["Drag-Only Jiggle & Reflow", "AnimatedPositioned 2D grid packer + drag-gated shake", "Edit Mode stays calm at rest; cards only jiggle while actively dragged as neighboring cards slide away smoothly."],
            ["Translucent Pocket Lock", "Dynamic 4-digit PIN challenge overlay", "Protects against accidental fabric touches in jacket pockets while keeping metrics 100% readable."],
            ["Lifecycle Auto-Save", "WidgetsBindingObserver flush hooks", "Automatically flushes raw CAN logs, CSV rows, and 16x11 VE matrix on pause or disconnect."]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/overview-and-tenets.js"] = overviewAndTenetsDefinition;
