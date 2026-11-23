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
 * @property {Array<Object>} tab_list - Tabs containing section blocks and cockpit metrics.
 * @property {boolean} hide_tabs - Whether tab bar is hidden.
 * @property {boolean} hide_toc - Whether table of contents sidebar is hidden.
 */

window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {NavigationItemDefinition} */
const minimalistDashboardDefinition = {
  item_title: "Minimalist Dashboard",
  icon_name: "speed",
  header_container: {
    title: "Minimalist Cockpit & Customization Engine",
    description: "High-contrast 2-column digital cockpit adhering to GitHub Primer dark aesthetics, featuring animated Edit Mode, drag reordering, fluid corner/edge card resizing, and typography controls.",
    badge_list: [
      { icon_name: "grid_view", badge_label: "2-Column Flow Layout" },
      { icon_name: "animation", badge_label: "Smooth Wobble & Reflow" },
      { icon_name: "open_with", badge_label: "Corner & Edge Resizing" },
      { icon_name: "terminal", badge_label: "200-Line Rolling Drawer" }
    ],
    banner_image: {
      image_path: "assets/icon.png",
      shrink: true
    },
    mockup_card: {
      image_path: "assets/dashboard.png",
      shrink: true
    }
  },
  tab_list: [
    {
      tab_title: "Dashboard UI",
      icon_name: "dashboard",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Cockpit Metrics & Layout",
          content: "The dashboard presents high-contrast digital telemetry readouts arranged in an adaptive 2-column flow layout: Engine Speed (RPM), Throttle Position (TPS %), Manifold Absolute Pressure (MAP kPa), Real-time Volumetric Efficiency (VE %), Coolant Temperature (ECT °C), and Variable Valve Actuation (VVA Status)."
        },
        {
          block_type: "table",
          heading_title: "Cockpit Card Specifications",
          columns: ["Card Label", "Unit", "Font", "Dynamic Visual Accent"],
          rows: [
            ["Engine Speed", "RPM", "Google Sans Code", "Turns Warning Amber at >= 7,400 RPM"],
            ["Throttle (TPS)", "%", "Google Sans Code", "GitHub Accent Blue"],
            ["Manifold Pressure", "kPa", "Google Sans Code", "GitHub Accent Blue"],
            ["Volumetric Eff.", "%", "Google Sans Code", "Permanent Success Green Highlight"],
            ["Coolant Temp", "°C", "Google Sans Code", "Danger Red at >= 100°C; Success Green at >= 60°C"],
            ["VVA Cam Status", "HIGH/LOW-CAM", "Google Sans Code", "Active Warning Amber when engaged"]
          ]
        }
      ]
    },
    {
      tab_title: "Edit Mode & Animations",
      icon_name: "tune",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Interactive Jiggle & Reordering",
          content: "Long-pressing any metric card triggers Edit Mode with an iOS-style cubic downscale entry animation, followed by continuous harmonic jiggling. As cards are dragged across the canvas, surrounding cards smoothly animate apart to open up drop targets."
        },
        {
          block_type: "cards_container",
          heading_title: "Edit Mode Features",
          description: "Fluid gestures and fine-grained card customizations available during Edit Mode.",
          layout_type: "three_cards",
          cards: [
            {
              title: "Smooth Entry & Lift",
              description: "Cards downscale smoothly upon entering Edit Mode, and elevate to 1.05x with dimmed 0.45 opacity when lifted for dragging.",
              label: "Animations",
              link: "",
              image_path: "assets/edit_mode.png",
              shrink: true
            },
            {
              title: "Fluid Corner & Edge Resizing",
              description: "8 interactive touch zones (4 corners and 4 edges) allow dragging to effortlessly toggle colSpan (1x to 2x) and rowSpan.",
              label: "Customization",
              link: "",
              image_path: "assets/edit_mode_selected.png",
              shrink: true
            },
            {
              title: "Contextual Typography Editor",
              description: "Selecting a card illuminates the middle Edit action button in Neon Yellow (0xFFCCFF00), opening the live Font Size dialog.",
              label: "Styling",
              link: "",
              image_path: "assets/font_dialog.png",
              shrink: true
            }
          ]
        }
      ]
    }
  ],
  hide_tabs: false,
  hide_toc: false
};

window.DOCUMENTATION_ITEMS["data/navigation-items/minimalist-dashboard.js"] = minimalistDashboardDefinition;
