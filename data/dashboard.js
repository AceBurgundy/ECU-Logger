window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const dashboardDefinition = {
  item_title: "Dashboard",
  icon_name: "dashboard",
  header_container: {
    title: "ECU Logger",
    description: "High-frequency CAN bus and OBD-II telemetry logger for motorcycle ECU tuning and real-time volumetric efficiency analysis. Built with Flutter, featuring customizable 4-column cockpit layouts and resilient background data acquisition.",
    badge_list: [
      { icon_name: "palette", badge_label: "GitHub Primer Theme" },
      { icon_name: "speed", badge_label: "50-100Hz CAN Sniffing" },
      { icon_name: "grid_view", badge_label: "4-Col / 2x2 Default Grid" },
      { icon_name: "open_with", badge_label: "Pixel-Tracked 4x4 Resize" },
      { icon_name: "lock", badge_label: "Pocket Touch Overlay" }
    ],
    banner_image: {
      image_path: "assets/dashboard.png",
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
          description: "Essential capabilities engineered for rock-solid road telemetry acquisition, fluid cockpit customization, and safe in-pocket logging.",
          layout_type: "three_cards",
          cards: [
            {
              title: "4-Column Fluid Cockpit & Edit Mode",
              description: "Defaults to 2x2 cards on a 4-column grid, resizable pixel-for-pixel up to 4x4 via 8 corner/edge handles with drag-only jiggle and smooth physical slide-away reflow.",
              label: "UI & Customization",
              link: "data/navigation-items/minimalist-dashboard.js",
              image_path: "assets/edit_mode.png",
              shrink: true
            },
            {
              title: "Translucent Pocket Lock",
              description: "Dynamic 4-digit PIN challenge overlay preventing accidental pocket touches while keeping telemetry metrics 100% visible and actively logging underneath.",
              label: "Safety & Integrity",
              link: "data/navigation-items/pocket-lock-protection.js",
              image_path: "assets/lock_overlay.png",
              shrink: true
            },
            {
              title: "Dual-Stream File Engine",
              description: "Streams raw_can.log, telemetry.csv, and 16x11 remap_matrix.json simultaneously with lifecycle auto-flush on pause or BLE disconnect.",
              label: "Storage & Tuning",
              link: "data/navigation-items/telemetry-and-matrix.js",
              image_path: "assets/console_log.png",
              shrink: true
            }
          ]
        },
        {
          heading_title: "Architecture & Developer References",
          block_type: "cards_container",
          description: "Deep dive into the ELM327 command pipeline, Speed-Density VE math, and Flutter service architecture.",
          layout_type: "two_cards",
          cards: [
            {
              title: "Architecture & Data Pipeline",
              description: "Complete breakdown of the BLE UART transport, ELM327 CAN frame parsing, and 2D cockpit grid packer.",
              label: "Architecture",
              link: "data/navigation-items/architecture-and-pipeline.js",
              image_path: "assets/scale.png",
              shrink: true
            },
            {
              title: "Full API & Service Reference",
              description: "Complete class references, LayoutService persistence formats, and telemetry data schemas.",
              label: "API Reference",
              link: "data/navigation-items/api-reference.js",
              image_path: "assets/font_dialog.png",
              shrink: true
            }
          ]
        }
      ]
    }
  ]
};

window.DOCUMENTATION_ITEMS["data/dashboard.js"] = dashboardDefinition;
