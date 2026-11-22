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
 * @property {Array<Object>} tab_list - Tabs containing section blocks and architecture.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const architectureAndPipelineDefinition = {
  item_title: "Architecture & Pipeline",
  icon_name: "account_tree",
  header_container: {
    title: "System Architecture & Telemetry Pipeline",
    description: "From passive ELM327 CAN broadcast sniffing to real-time Volumetric Efficiency calculation and multi-format disk serialization.",
    badge_list: [
      { icon_name: "layers", badge_label: "Decoupled Layers" },
      { icon_name: "sync", badge_label: "Reactive State Stream" }
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
      tab_title: "Architecture",
      icon_name: "architecture",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Data Flow Architecture",
          content: "The ECU Logger application is divided into five isolated modules: BleService (BLE discovery & transport), Elm327Protocol (frame parsing), TelemetryEngine (Speed-Density VE & hysteresis state machine), FileLoggerService (buffered disk writes), and UI Layer (Option 3 Dashboard & Lock Overlay)."
        },
        {
          block_type: "code",
          heading_title: "Telemetry Pipeline Flow",
          language: "dart",
          code_content: "// 1. BLE Rx Buffer -> Elm327Protocol\nfinal rawCan = Elm327Protocol.parseRawCanFrame(line);\n\n// 2. Telemetry Engine Metrics Update\n_updateMetrics(newRpm: rpm, newTps: tps);\n\n// 3. Volumetric Efficiency Formula\nfinal veDensity = (mapKpa / baroKpa) * (293.15 / (273.15 + iatC)) * 100.0;\nfinal veCorrected = veDensity * (1.0 + ((stft + ltft) / 100.0));\n\n// 4. Disk Sink Stream\nFileLoggerService.instance.logTelemetryRow(...);",
          filename: "pipeline_overview.dart"
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/architecture-and-pipeline.js"] = architectureAndPipelineDefinition;
