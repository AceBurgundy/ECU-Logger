/**
 * @typedef {Object} SocialLink
 * @property {string} icon_name - Material icon name.
 * @property {string} platform_name - Platform title.
 * @property {string} url - External navigation URL.
 */

/**
 * @typedef {Object} ColumnLink
 * @property {string} label - Anchor label.
 * @property {string} url - Target URL.
 */

/**
 * @typedef {Object} FooterColumn
 * @property {string} column_title - Column header text.
 * @property {Array<ColumnLink>} links - Column hyperlinks.
 */

/**
 * @typedef {Object} FooterLegalLink
 * @property {string} label - Anchor label.
 * @property {string} url - Target URL.
 */

/**
 * @typedef {Object} FooterDefinition
 * @property {string} brand_name - Application brand string.
 * @property {string} brand_description - High-level summary of package purpose.
 * @property {Array<SocialLink>} social_links - Author and community links.
 * @property {Array<FooterColumn>} columns - Footer structured links.
 * @property {Array<FooterLegalLink>} legal_links - Legal policy links.
 * @property {string} copyright_text - Legal copyright and attribution notice.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {FooterDefinition} */
const footerDefinition = {
  brand_name: "ECU Logger • AceBurgundy",
  brand_description: "High-frequency CAN bus and OBD-II telemetry logger for motorcycle ECU tuning and real-time volumetric efficiency analysis. Built with Flutter, featuring responsive 4/6/8-column cockpit layouts and resilient background data acquisition.",
  social_links: [
    {
      icon_name: "code",
      platform_name: "GitHub",
      url: "https://github.com/AceBurgundy/ECU-Logger"
    },
    {
      icon_name: "download",
      platform_name: "Releases",
      url: "https://github.com/AceBurgundy/ECU-Logger/releases"
    },
    {
      icon_name: "mail",
      platform_name: "Contact",
      url: "mailto:samadriansabalo99@gmail.com"
    }
  ],
  columns: [
    {
      column_title: "Getting Started",
      links: [
        { label: "Project Overview", url: "https://github.com/AceBurgundy/ECU-Logger#readme" },
        { label: "Requirements & Setup", url: "https://github.com/AceBurgundy/ECU-Logger#requirements--installation" },
        { label: "Latest APK Release (v1.0.2)", url: "https://github.com/AceBurgundy/ECU-Logger/releases/download/v1.0.2/ecu-logger-v1.0.2.apk" }
      ]
    },
    {
      column_title: "Core Modules",
      links: [
        { label: "Adaptive Cockpit Layout", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/widgets/dashboard_flow_layout.dart" },
        { label: "Pocket Lock Overlay", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/widgets/lock_overlay.dart" },
        { label: "Monospace Log Drawer", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/widgets/log_drawer.dart" }
      ]
    },
    {
      column_title: "Protocols",
      links: [
        { label: "BLE UART Service", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/services/ble_service.dart" },
        { label: "ELM327 & CAN Parser", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/services/elm327_protocol.dart" },
        { label: "Speed-Density VE Engine", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/services/telemetry_engine.dart" }
      ]
    },
    {
      column_title: "Architecture",
      links: [
        { label: "Dual-Stream File Logger", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/services/file_logger_service.dart" },
        { label: "16x11 Remap Matrix", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/models/remap_matrix.dart" },
        { label: "Saved Layout Persistence", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/lib/services/dashboard_layout_service.dart" }
      ]
    },
    {
      column_title: "Resources",
      links: [
        { label: "GitHub Repository", url: "https://github.com/AceBurgundy/ECU-Logger" },
        { label: "Issue Tracker", url: "https://github.com/AceBurgundy/ECU-Logger/issues" },
        { label: "License (MPL-2.0)", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/LICENSE" }
      ]
    }
  ],
  legal_links: [
    { label: "License Terms (MPL-2.0)", url: "https://github.com/AceBurgundy/ECU-Logger/blob/master/LICENSE" },
    { label: "Repository", url: "https://github.com/AceBurgundy/ECU-Logger" },
    { label: "Issue Tracker", url: "https://github.com/AceBurgundy/ECU-Logger/issues" }
  ],
  copyright_text: "This project is licensed under the Mozilla Public License Version 2.0 (MPL-2.0). Copyright © 2026 AceBurgundy. Engineered with Flutter and GitHub Primer aesthetics."
};

window.DOCUMENTATION_ITEMS["data/footer.js"] = footerDefinition;
