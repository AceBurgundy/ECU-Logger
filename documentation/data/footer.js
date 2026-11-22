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
 * @typedef {Object} FooterDefinition
 * @property {string} brand_name - Application brand string.
 * @property {string} brand_description - High-level summary of package purpose.
 * @property {Array<SocialLink>} social_links - Author and community links.
 * @property {Array<FooterColumn>} columns - Footer structured links.
 * @property {Array<ColumnLink>} legal_links - Legal policy links.
 * @property {string} copyright_text - Legal copyright and attribution notice.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {FooterDefinition} */
const footerDefinition = {
  brand_name: "ECU Logger • AceBurgundy",
  brand_description: "Dedicated mobile telemetry application designed for Yamaha motorcycle ECU diagnostics, active CAN broadcast logging, and Speed-Density VE fuel mapping over Bluetooth Low Energy.",
  social_links: [
    {
      icon_name: "code",
      platform_name: "GitHub",
      url: "https://github.com/AceBurgundy/ecu_logger"
    },
    {
      icon_name: "deployed_code",
      platform_name: "Repository",
      url: "https://github.com/AceBurgundy/ecu_logger"
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
        { label: "Project Overview", url: "https://github.com/AceBurgundy/ecu_logger#readme" },
        { label: "Installation & Setup", url: "https://github.com/AceBurgundy/ecu_logger#requirements--installation" },
        { label: "Quick Start Guide", url: "https://github.com/AceBurgundy/ecu_logger#quick-start--usage-examples" }
      ]
    },
    {
      column_title: "Core Modules",
      links: [
        { label: "Option 3 Dashboard", url: "#" },
        { label: "Pocket Lock Screen", url: "#" },
        { label: "Monospace Log Drawer", url: "#" }
      ]
    },
    {
      column_title: "Protocols",
      links: [
        { label: "ELM327 Command Loop", url: "#" },
        { label: "Yamaha CAN Frame Sniffing", url: "#" },
        { label: "Speed-Density VE Calculation", url: "#" }
      ]
    },
    {
      column_title: "Architecture",
      links: [
        { label: "Dual-Stream File Engine", url: "#" },
        { label: "16x11 Fuel Remap Matrix", url: "#" },
        { label: "Lifecycle Auto-Save", url: "#" }
      ]
    },
    {
      column_title: "Resources",
      links: [
        { label: "GitHub Repository", url: "https://github.com/AceBurgundy/ecu_logger" },
        { label: "Issue Tracker", url: "https://github.com/AceBurgundy/ecu_logger/issues" },
        { label: "License (MPL-2.0)", url: "https://github.com/AceBurgundy/ecu_logger/blob/main/LICENSE" }
      ]
    }
  ],
  legal_links: [
    { label: "License Terms", url: "https://github.com/AceBurgundy/ecu_logger/blob/main/LICENSE" },
    { label: "Repository", url: "https://github.com/AceBurgundy/ecu_logger" },
    { label: "Issue Tracker", url: "https://github.com/AceBurgundy/ecu_logger/issues" }
  ],
  copyright_text: "This project is licensed under the Mozilla Public License Version 2.0 (MPL-2.0). Copyright © 2026 AceBurgundy. Engineered with Flutter and Material Design 3."
};

window.DOCUMENTATION_ITEMS["data/footer.js"] = footerDefinition;
