window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};
window.DOCUMENTATION_ITEMS["data/navigation-items/pocket-lock-protection.js"] = {
  "item_title": "Pocket Lock Protection",
  "icon_name": "lock",
  "header_container": {
    "title": "Translucent Pocket Lock Screen Overlay",
    "description": "Full-page translucent protection with dynamic 4-digit PIN challenge and numeric keypad, keeping metrics 100% visible underneath.",
    "badge_list": [
      { "icon_name": "lock_open", "badge_label": "Dynamic 4-Digit Challenge" },
      { "icon_name": "visibility", "badge_label": "100% Background Visibility" }
    ],
    "banner_image": {
      "image_path": "assets/icon.png",
      "shrink": true
    },
    "mockup_card": {
      "image_path": "assets/delete.png",
      "shrink": true
    }
  },
  "tab_list": [
    {
      "tab_title": "Lock Mechanism",
      "icon_name": "security",
      "section_blocks": [
        {
          "block_type": "paragraph",
          "heading_title": "The Accidental Pocket Touch Problem",
          "content": "When riding a motorcycle with the logger running in a pocket or jacket, body fabric touches frequently stop logging, toggle settings, or disconnect Bluetooth. The Translucent Pocket Lock solves this completely by placing a full-screen touch interceptor over the viewport while maintaining full visibility of live engine metrics."
        },
        {
          "block_type": "paragraph",
          "heading_title": "Random PIN Challenge & Keypad",
          "content": "On lock activation, the app generates a randomized 4-digit code (e.g. 'Press 7 2 9 4 to open'). The rider enters this code using large, glove-friendly circular keypad buttons (0-9, CLR, Backspace). If incorrect, an error flash resets the input; matching digits dismiss the overlay immediately."
        }
      ]
    }
  ],
  "hide_tabs": false,
  "hide_toc": false
};
