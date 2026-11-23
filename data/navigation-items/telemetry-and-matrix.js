window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const telemetryAndMatrixDefinition = {
  item_title: "Telemetry & Remap Matrix",
  icon_name: "analytics",
  header_container: {
    title: "Speed-Density VE & 16x11 Fuel Matrix",
    description: "Thermodynamic equations for real-time Volumetric Efficiency evaluation, dual-cam VVA binning, and multi-format session serialization.",
    badge_list: [
      { icon_name: "functions", badge_label: "Speed-Density Model" },
      { icon_name: "table_chart", badge_label: "16x11 Bin Matrix" }
    ],
    banner_image: {
      image_path: "assets/dashboard.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "Formulas & Storage",
      icon_name: "calculate",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Volumetric Efficiency Equations",
          paragraph_text: "Volumetric Efficiency is computed using the ideal gas law referenced against standard atmospheric conditions (293.15 K, 101.3 kPa), then fuel-trimmed via STFT + LTFT. When RPM is 0 (engine off with ignition key on), VE safely evaluates to 0.0% rather than reporting spurious ambient calculations."
        },
        {
          block_type: "code_block",
          heading_title: "VE Mathematical Evaluation",
          header_label: "Dart • TelemetryEngine._updateMetrics",
          language_identifier: "dart",
          code_content: "// Speed-Density Base VE (only active when RPM > 0):\nfinal double veDensity = (mapKpa / baroKpa) * (293.15 / (273.15 + iatC)) * 100.0;\n\n// Fuel-Trim Corrected VE:\nfinal double veCorrected = veDensity * (1.0 + ((stft + ltft) / 100.0));"
        },
        {
          block_type: "table",
          heading_title: "Session Log Artifacts",
          table_headers: ["File Name Pattern", "Format", "Contents"],
          table_rows: [
            ["raw_can_YYYYMMDD_HHMMSS.log", "Plaintext Hex", "Timestamped raw incoming ELM327 & CAN lines"],
            ["telemetry_YYYYMMDD_HHMMSS.csv", "RFC 4180 CSV", "timestamp, rpm, tps, map_kpa, ect_c, iat_c, stft, ltft, ve_density, ve_corrected, vva_status"],
            ["remap_matrix_YYYYMMDD_HHMMSS.json", "JSON Map", "16 RPM bins x 11 TPS bins for Low-Cam and High-Cam accumulators"]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/telemetry-and-matrix.js"] = telemetryAndMatrixDefinition;
