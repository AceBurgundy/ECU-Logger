window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const pocketLockProtectionDefinition = {
  item_title: "Pocket Lock Protection",
  icon_name: "lock",
  header_container: {
    title: "Translucent Pocket Lock Screen Overlay",
    description: "Full-page translucent touch barrier with a randomized 4-digit PIN challenge and glove-friendly keypad, keeping live metrics 100% visible underneath.",
    badge_list: [
      { icon_name: "pin", badge_label: "Dynamic 4-Digit Challenge" },
      { icon_name: "visibility", badge_label: "100% Background Visibility" }
    ],
    banner_image: {
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
          heading_title: "Preventing Accidental Pocket Touches",
          paragraph_text: "When riding with your phone stowed inside a jacket pocket or tank bag, stray fabric touches can disconnect Bluetooth, switch layouts, or clear logs. Activating the Pocket Lock places a full-screen translucent modal over the cockpit that blocks all touch input beneath while leaving live telemetry readouts and the rolling log drawer completely legible."
        },
        {
          block_type: "table",
          heading_title: "Keypad & Verification Security",
          table_headers: ["Property", "Specification", "Behavior"],
          table_rows: [
            ["PIN Generation", "Random 4 Digits", "Regenerated on every lock activation and displayed clearly in quotes"],
            ["Keypad Layout", "3x4 Circular Pad", "Large glove-friendly numeric buttons plus CLR and Backspace controls"],
            ["Mismatch Feedback", "Horizontal Shake & Flash", "Keypad shakes with danger-red border glow and clears input automatically"],
            ["Telemetry Continuity", "Non-Blocking Stack", "BLE acquisition, VE math, and disk file streaming run uninterrupted underneath"]
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/pocket-lock-protection.js"] = pocketLockProtectionDefinition;
