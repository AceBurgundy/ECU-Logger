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
 * @property {Array<Object>} tab_list - Tabs containing section blocks and lock specifications.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const pocketLockProtectionDefinition = {
  item_title: "Pocket Lock Protection",
  icon_name: "lock",
  header_container: {
    title: "Translucent Pocket Lock Screen Overlay",
    description: "Full-page translucent protection with dynamic 4-digit PIN challenge and numeric keypad, keeping metrics 100% visible underneath.",
    badge_list: [
      { icon_name: "lock_open", badge_label: "Dynamic 4-Digit Challenge" },
      { icon_name: "visibility", badge_label: "100% Background Visibility" }
    ],
    banner_image: {
      image_path: "assets/icon.png",
      shrink: true
    },
    mockup_card: {
      image_path: "assets/lock_overlay.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "Lock Mechanism",
      icon_name: "security",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "The Accidental Pocket Touch Problem",
          content: "When riding a motorcycle with the logger running in a pocket or jacket, body fabric touches frequently stop logging, toggle settings, or disconnect Bluetooth. The Translucent Pocket Lock solves this completely by placing a full-screen touch interceptor over the viewport while maintaining full visibility of live engine metrics."
        },
        {
          block_type: "table",
          heading_title: "Keypad & Verification Security",
          columns: ["Property", "Specification", "Behavior"],
          rows: [
            ["PIN Generation", "Random 4 Digits", "Regenerated on every activation; displayed prominently in quotes"],
            ["Keypad Layout", "3x4 Telephone Pad", "Large glove-friendly circular buttons with tactile sound/vibration"],
            ["Wrong Input", "Shake & Red Flash", "Keypad shakes horizontally with red glow and clears entry on mismatch"],
            ["Pass-through", "Active Telemetry", "Underlying stream metrics update continuously at 50-100Hz"]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/pocket-lock-protection.js"] = pocketLockProtectionDefinition;
