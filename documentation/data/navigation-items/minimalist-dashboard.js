window.DOCUMENTATION_ITEMS = window.DOCUMENTATION_ITEMS || {};

/** @type {Object} */
const minimalistDashboardDefinition = {
  item_title: "Minimalist Dashboard",
  icon_name: "speed",
  header_container: {
    title: "Minimalist Cockpit & Fluid Edit Mode",
    description: "Adaptive 4 / 6 / 8-column digital cockpit adhering to GitHub Primer dark aesthetics, featuring 2-span defaults, pixel-tracked resizing up to active max columns, 80pt fonts, physical slide reflow, and miniature saved previews.",
    badge_list: [
      { icon_name: "grid_view", badge_label: "4 / 6 / 8-Col Grid (2-Span)" },
      { icon_name: "open_with", badge_label: "Up to 8x4 Resize" },
      { icon_name: "animation", badge_label: "Physical Slide Reflow" },
      { icon_name: "text_fields", badge_label: "Up to 80.0 pt Fonts" }
    ],
    banner_image: {
      image_path: "assets/edit_mode_selected.png",
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
          heading_title: "Responsive Multi-Column Grid & Default 2-Span Cards",
          paragraph_text: "ECU Logger dynamically adapts grid density by viewport width: phone portrait (<600dp) renders 4 columns (2 cards/row), tablet portrait or phone landscape (600dp-900dp) renders 6 columns (3 cards/row), and large tablets or wide landscapes (>900dp) render 8 columns (4 cards/row). All six default telemetry cards (RPM, TPS, MAP, VE%, ECT, and VVA) start at 2 columns by 2 rows with scaled row heights, rendering flush in View Mode with type-matched zero placeholders (00, 0%, 0.0, OFF)."
        },
        {
          block_type: "table",
          heading_title: "Cockpit Card Specifications",
          table_headers: ["Card Label", "Unit", "Default Span", "Dynamic Visual Accent"],
          table_rows: [
            ["Engine Speed", "RPM", "2 cols x 2 rows", "GitHub Accent Blue highlight when >= 7,400 RPM"],
            ["Throttle (TPS)", "%", "2 cols x 2 rows", "GitHub Accent Blue"],
            ["Manifold Pressure", "kPa", "2 cols x 2 rows", "GitHub Accent Blue"],
            ["Volumetric Eff.", "%", "2 cols x 2 rows", "Success Green highlight when corrected VE active"],
            ["Coolant Temp", "°C", "2 cols x 2 rows", "GitHub Accent Blue highlight when >= 100°C"],
            ["VVA Cam Status", "CAM", "2 cols x 2 rows", "Active Warning Amber when High-Cam engaged (ACTIVE / INACTIVE / OFF)"]
          ]
        }
      ]
    },
    {
      tab_title: "Fluid Edit Mode & Animations",
      icon_name: "tune",
      section_blocks: [
        {
          block_type: "paragraph",
          heading_title: "Quiet Edit Entry & Smooth Exit Scale",
          paragraph_text: "Pressing and holding anywhere on the dashboard smoothly scales cards into Edit Mode without distracting idle wobble. Tapping either Check (Save) or Cancel (Discard) reverses the entry animation controller while keeping the transform tree mounted, smoothly animating every card and border back to 1.0x View Mode scale."
        },
        {
          block_type: "paragraph",
          heading_title: "Drag-Only Jiggle & Physical Slide-Away Reflow",
          paragraph_text: "Cards remain completely steady in Edit Mode until you hold and drag a card to move it. Once dragging starts, the lifted floating card and grid begin jiggling while surrounding cards physically slide out of the way using AnimatedPositioned and stable ValueKeys—opening a clear drop target whenever you hover over or between cards. Dropping immediately halts all jiggling."
        },
        {
          block_type: "paragraph",
          heading_title: "Pixel-Tracking Edge & Corner Resizing (Up to Max Columns x 4 Rows)",
          paragraph_text: "Tapping any card selects it with a Bright Neon Yellow (0xFFCCFF00) border and reveals 8 interactive handles (4 corners and 4 edges) backed by unclipped 28px overlay touch targets. Dragging any edge or corner locks scroll competition, accounts for scale center-offset mathematically, follows the user's hand pixel-for-pixel in real time, and snaps smoothly to the nearest column (1..4, 1..6, or 1..8 depending on screen width) and row (1..4) upon release."
        },
        {
          block_type: "paragraph",
          heading_title: "80.0 pt Per-Card Typography & Deduplicated Saved Layouts",
          paragraph_text: "The contextual Font Size Dialog supports up to 80.0 pt across Title Label, Numeric Value, and Unit Badge Pill with overflow-safe scaling even on 1x1 cards. Pressing Save checks card metric IDs, column/row spans, and font sizes against the protected Factory Cockpit baseline and existing presets—saving only genuinely unique layouts and displaying real miniature card previews inside the Saved Cockpit Layouts carousel."
        },
        {
          block_type: "cards_container",
          heading_title: "Edit Mode Showcase",
          description: "Live captures from Sam's Pixel 8 showing quiet edit entry, active neon resize handles, and custom card typography.",
          layout_type: "three_cards",
          cards: [
            {
              title: "Quiet Edit Entry",
              description: "Long-pressing scales cards smoothly to 0.90x with restored GitHub borders and zero idle jiggle until a drag begins.",
              label: "Entry Animation",
              link: "",
              image_path: "assets/edit_mode.png",
              shrink: true
            },
            {
              title: "8-Point Pixel Resize",
              description: "Unclipped edge & corner overlay zones track finger position 1:1 and snap cleanly across 4, 6, or 8 columns.",
              label: "Resizing",
              link: "",
              image_path: "assets/edit_mode_selected.png",
              shrink: true
            },
            {
              title: "80pt Typography Editor",
              description: "Selecting a card illuminates the Neon Yellow format-size action button with sliders up to 80.0 pt for all 3 texts.",
              label: "Typography",
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
