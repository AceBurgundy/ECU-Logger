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
 * @property {Array<Object>} tab_list - Tabs containing section blocks and mathematical formulas.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const telemetryAndMatrixDefinition = {
  item_title: "Telemetry & Remap Matrix",
  icon_name: "analytics",
  header_container: {
    title: "Speed-Density VE & 16x11 Fuel Matrix",
    description: "Mathematical models for real-time Volumetric Efficiency calculation, dual-cam matrix binning, and session disk serialization.",
    badge_list: [
      { icon_name: "functions", badge_label: "Speed-Density Model" },
      { icon_name: "table_chart", badge_label: "16x11 Bin Matrix" }
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
      tab_title: "Formulas & Storage",
      icon_name: "calculate",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Volumetric Efficiency Equations",
          content: "Volumetric Efficiency is calculated via the ideal gas law relative to standard atmospheric conditions (293.15 K, 101.3 kPa). The raw density is then trimmed using short-term and long-term fuel trim corrections (STFT + LTFT)."
        },
        {
          block_type: "code",
          heading_title: "VE Mathematical Evaluation",
          language: "dart",
          code_content: "// Speed-Density Base VE:\nfinal double veDensity = (mapKpa / baroKpa) * (293.15 / (273.15 + iatC)) * 100.0;\n\n// Fuel-Corrected VE:\nfinal double veCorrected = veDensity * (1.0 + ((stft + ltft) / 100.0));",
          filename: "ve_formula.dart"
        },
        {
          block_type: "table",
          heading_title: "Session Log Artifacts",
          columns: ["File Name Pattern", "Format", "Contents"],
          rows: [
            ["raw_can_YYYYMMDD_HHMMSS.log", "Plaintext Hex", "Raw incoming CAN lines stamped with ISO-8601 timestamps."],
            ["telemetry_YYYYMMDD_HHMMSS.csv", "RFC 4180 CSV", "Columns: timestamp, rpm, tps, map_kpa, ect_c, iat_c, stft, ltft, ve_density, ve_corrected, vva_status."],
            ["remap_matrix_YYYYMMDD_HHMMSS.json", "JSON Map", "16 RPM bins x 11 TPS bins for Low-Cam and High-Cam accumulators."]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/telemetry-and-matrix.js"] = telemetryAndMatrixDefinition;
