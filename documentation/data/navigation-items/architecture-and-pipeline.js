window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const architectureAndPipelineDefinition = {
  item_title: "Architecture & Pipeline",
  icon_name: "account_tree",
  header_container: {
    title: "System Architecture & Telemetry Pipeline",
    description: "From passive ELM327 CAN broadcast sniffing and 4-column grid packing to real-time Volumetric Efficiency calculation and multi-format disk serialization.",
    badge_list: [
      { icon_name: "layers", badge_label: "Decoupled Modules" },
      { icon_name: "sync", badge_label: "Reactive Streams" },
      { icon_name: "grid_4x4", badge_label: "2D Grid Packer" }
    ],
    banner_image: {
      image_path: "assets/console_log.png",
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
          paragraph_text: "ECU Logger is structured into cleanly separated runtime layers: BleService (BLE peripheral discovery and UART streaming), Elm327Protocol (AT command loops and raw CAN/PID frame parsing), TelemetryEngine (Speed-Density VE math and VVA hysteresis), DashboardLayoutService (JSON layout persistence and frozen previews), FileLoggerService (buffered CSV/LOG/JSON sinks), and the DashboardFlowLayout 4-column animated grid."
        },
        {
          block_type: "code_block",
          heading_title: "Telemetry Pipeline Flow",
          header_label: "Dart • Telemetry Pipeline",
          language_identifier: "dart",
          code_content: "// 1. BLE Rx Buffer -> Elm327Protocol\nfinal rawCan = Elm327Protocol.parseRawCanFrame(line);\n\n// 2. Telemetry Engine Metrics Update\n_updateMetrics(newRpm: rpm, newTps: tps);\n\n// 3. Speed-Density Volumetric Efficiency Formula\nfinal veDensity = (mapKpa / baroKpa) * (293.15 / (273.15 + iatC)) * 100.0;\nfinal veCorrected = veDensity * (1.0 + ((stft + ltft) / 100.0));\n\n// 4. Buffered Disk Sink\nFileLoggerService.instance.logTelemetryRow(...);"
        },
        {
          block_type: "code_block",
          heading_title: "Order-Preserving 4-Column 2D Packer",
          header_label: "Dart • computeDashboardGridLayout",
          language_identifier: "dart",
          code_content: "final DashboardGridLayout layout = computeDashboardGridLayout(\n  cards: displayCards,\n  unitColWidth: (availableWidth - (3 * gap)) / 4.0,\n  unitRowHeight: 52.0,\n  gap: isEditMode ? 14.0 : 12.0,\n);"
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/architecture-and-pipeline.js"] = architectureAndPipelineDefinition;
