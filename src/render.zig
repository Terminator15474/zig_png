const rl = @import("raylib");
const std = @import("std");
const png = @import("png.zig");

pub fn renderPngInWindow(width: u32, height: u32, img_data: *png.png_data) !void {
    const scaleX = width / img_data.width;
    const scaleY = height / img_data.height;

    rl.initWindow(@intCast(width), @intCast(height), "zig-png - example");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        for (0..img_data.height) |x| {
            for (0..img_data.width) |y| {
                const pixel = (img_data.getPixel(x, y) / std.math.pow(u8, 2, img_data.bit_depth)) * 255;
                std.log.debug("BD: {d}, val: {d}\n", .{ img_data.bit_depth, pixel });
                drawPixelScaled(@intCast(x), @intCast(y), scaleX, scaleY, rl.Color.init(pixel, pixel, pixel, 255));
            }
        }
    }
}

fn drawPixelScaled(x: u32, y: u32, scaleX: u32, scaleY: u32, color: rl.Color) void {
    for (0..scaleX) |i| {
        for (0..scaleY) |j| {
            rl.drawPixel(@intCast(x * scaleX + i), @intCast(y * scaleY + j), color);
        }
    }
}
