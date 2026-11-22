import os
from PIL import Image, ImageDraw, ImageFilter

CANVAS_DARK = (13, 17, 23, 255)       # GitHub Primer Dark #0D1117
PULSE_BLUE = (88, 166, 255, 255)      # Primer Accent Blue #58A6FF
PULSE_GLOW = (88, 166, 255, 140)      # Primer Accent Glow
PULSE_CYAN = (121, 192, 255, 220)     # Luminous Cyan #79C0FF
NODE_CORE = (240, 246, 252, 255)      # Primer White #F0F6FC
MONO_WHITE = (255, 255, 255, 255)     # Flat White for Android 13+ Themed Icons

def render_pulse_layer(canvas_size, is_monochrome=False):
    """
    Renders the minimalist telemetry pulse layer with supersampling for razor-sharp antialiasing.
    Coordinates are normalized to canvas_size and stay strictly within the 56% safe zone circle.
    """
    scale = 4
    size = canvas_size * scale
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    center_x = size * 0.5
    center_y = size * 0.5

    # Normalized pulse path coordinates perfectly centered in the safe zone (span: 0.56w x 0.31h)
    points = [
        (center_x - size * 0.28, center_y),
        (center_x - size * 0.12, center_y),
        (center_x - size * 0.07, center_y + size * 0.04),
        (center_x, center_y - size * 0.20),
        (center_x + size * 0.07, center_y + size * 0.11),
        (center_x + size * 0.13, center_y - size * 0.04),
        (center_x + size * 0.18, center_y),
        (center_x + size * 0.28, center_y),
    ]

    line_width = max(2, int(size * 0.024))
    radius = line_width / 2.0
    peak_x, peak_y = points[3]

    if is_monochrome:
        # Monochrome silhouette for Material You themed icons
        draw = ImageDraw.Draw(img)
        for i in range(len(points) - 1):
            draw.line([points[i], points[i + 1]], fill=MONO_WHITE, width=line_width)
        for point in points:
            draw.ellipse(
                [point[0] - radius, point[1] - radius, point[0] + radius, point[1] + radius],
                fill=MONO_WHITE
            )
        node_radius = int(size * 0.034)
        draw.ellipse(
            [peak_x - node_radius, peak_y - node_radius, peak_x + node_radius, peak_y + node_radius],
            fill=MONO_WHITE
        )
    else:
        # Soft atmospheric telemetry pulse glow
        glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_img)
        glow_width = int(line_width * 2.2)
        glow_radius = glow_width / 2.0
        for i in range(len(points) - 1):
            glow_draw.line([points[i], points[i + 1]], fill=PULSE_GLOW, width=glow_width)
        for point in points:
            glow_draw.ellipse(
                [point[0] - glow_radius, point[1] - glow_radius, point[0] + glow_radius, point[1] + glow_radius],
                fill=PULSE_GLOW
            )
        peak_glow_r = int(size * 0.045)
        glow_draw.ellipse(
            [peak_x - peak_glow_r, peak_y - peak_glow_r, peak_x + peak_glow_r, peak_y + peak_glow_r],
            fill=PULSE_CYAN
        )
        glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=int(size * 0.012)))
        img.alpha_composite(glow_img)

        # Razor-sharp foreground telemetry line
        draw = ImageDraw.Draw(img)
        for i in range(len(points) - 1):
            draw.line([points[i], points[i + 1]], fill=PULSE_BLUE, width=line_width)
        for point in points:
            draw.ellipse(
                [point[0] - radius, point[1] - radius, point[0] + radius, point[1] + radius],
                fill=PULSE_BLUE
            )

        # Luminous pulse peak telemetry node
        node_radius = int(size * 0.028)
        inner_radius = int(size * 0.018)
        draw.ellipse(
            [peak_x - node_radius, peak_y - node_radius, peak_x + node_radius, peak_y + node_radius],
            fill=PULSE_BLUE
        )
        draw.ellipse(
            [peak_x - inner_radius, peak_y - inner_radius, peak_x + inner_radius, peak_y + inner_radius],
            fill=NODE_CORE
        )

    return img.resize((canvas_size, canvas_size), Image.Resampling.LANCZOS)

def render_legacy_icon(size, is_round=False):
    """Renders complete legacy icons with #0D1117 background."""
    scale = 4
    render_size = size * scale
    img = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if is_round:
        draw.ellipse([0, 0, render_size, render_size], fill=CANVAS_DARK)
    else:
        corner_radius = int(render_size * 0.22)
        draw.rounded_rectangle([0, 0, render_size, render_size], radius=corner_radius, fill=CANVAS_DARK)

    pulse = render_pulse_layer(size, is_monochrome=False)
    # Scale pulse to supersampled canvas and composite
    pulse_upscaled = pulse.resize((render_size, render_size), Image.Resampling.NEAREST)
    img.alpha_composite(pulse_upscaled)
    return img.resize((size, size), Image.Resampling.LANCZOS)

def generate_all():
    base_res = "D:/Documents/Programming/Frameworks/Flutter/projects/ecu_logger/android/app/src/main/res"

    # Android density mapping: (legacy_dim, adaptive_dim)
    densities = {
        "mipmap-mdpi": (48, 108),
        "mipmap-hdpi": (72, 162),
        "mipmap-xhdpi": (96, 216),
        "mipmap-xxhdpi": (144, 324),
        "mipmap-xxxhdpi": (192, 432),
    }

    for folder, (dim, fg_dim) in densities.items():
        folder_path = os.path.join(base_res, folder)
        os.makedirs(folder_path, exist_ok=True)

        # 1. Standard square/squircle legacy icon
        img_square = render_legacy_icon(dim, is_round=False)
        img_square.save(os.path.join(folder_path, "ic_launcher.png"), "PNG", optimize=True)

        # 2. Round legacy icon
        img_round = render_legacy_icon(dim, is_round=True)
        img_round.save(os.path.join(folder_path, "ic_launcher_round.png"), "PNG", optimize=True)

        # 3. Adaptive icon foreground (transparent background, safe zone centered)
        img_fg = render_pulse_layer(fg_dim, is_monochrome=False)
        img_fg.save(os.path.join(folder_path, "ic_launcher_foreground.png"), "PNG", optimize=True)

        # 4. Adaptive icon monochrome (for Android 13+ Material You themed icons)
        img_mono = render_pulse_layer(fg_dim, is_monochrome=True)
        img_mono.save(os.path.join(folder_path, "ic_launcher_monochrome.png"), "PNG", optimize=True)

        print(f"Generated {dim}x{dim} legacy & {fg_dim}x{fg_dim} adaptive for {folder}")

    # Generate adaptive XML manifests in mipmap-anydpi-v26
    anydpi_folder = os.path.join(base_res, "mipmap-anydpi-v26")
    os.makedirs(anydpi_folder, exist_ok=True)

    adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
"""
    with open(os.path.join(anydpi_folder, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)

    with open(os.path.join(anydpi_folder, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)

    print("All launcher icons and adaptive XMLs generated successfully!")

if __name__ == "__main__":
    generate_all()
