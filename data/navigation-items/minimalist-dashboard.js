window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};
window.DOCUMENTATION_ITEMS["data/navigation-items/minimalist-dashboard.js"] = {
  "item_title": "Minimalist Dashboard",
  "icon_name": "speed",
  "header_container": {
    "title": "Option 3 Minimalist Dashboard & Log Drawer",
    "description": "High-contrast 6-card digital cockpit conforming to GitHub Primer dark aesthetics, paired with a collapsible bottom monospace log drawer.",
    "badge_list": [
      { "icon_name": "grid_view", "badge_label": "6 Digital Readouts" },
      { "icon_name": "terminal", "badge_label": "200-Line Rolling Drawer" }
    ],
    "banner_image": {
      "image_path": "assets/icon.png",
      "shrink": true
    },
    "mockup_card": {
      "image_path": "assets/prompt.png",
      "shrink": true
    }
  },
  "tab_list": [
    {
      "tab_title": "Dashboard UI",
      "icon_name": "dashboard",
      "section_blocks": [
        {
          "block_type": "paragraph",
          "heading_title": "Digital Readout Metrics",
          "content": "Conforming to Option 3 selected by the user, the dashboard presents six clean digital metrics: Engine Speed (RPM), Throttle Position (TPS %), Manifold Absolute Pressure (MAP kPa), Real-time Volumetric Efficiency (VE %), Coolant Temperature (ECT °C), and Variable Valve Actuation (VVA Status)."
        },
        {
          "block_type": "table",
          "heading_title": "Cockpit Card Specifications",
          "columns": ["Card Label", "Unit", "Font", "Dynamic Visual Accent"],
          "rows": [
            ["Engine Speed", "RPM", "Google Sans Code", "Turns Warning Amber at >= 7,400 RPM"],
            ["Throttle (TPS)", "%", "Google Sans Code", "GitHub Accent Blue"],
            ["Manifold Pressure", "kPa", "Google Sans Code", "GitHub Accent Blue"],
            ["Volumetric Eff.", "%", "Google Sans Code", "Permanent Success Green Highlight"],
            ["Coolant Temp", "°C", "Google Sans Code", "Danger Red at >= 100°C; Success Green at >= 60°C"],
            ["VVA Cam Status", "HIGH/LOW-CAM", "Google Sans Code", "Active Warning Amber when engaged"]
          ]
        }
      ]
    }
  ],
  "hide_tabs": false,
  "hide_toc": false
};
