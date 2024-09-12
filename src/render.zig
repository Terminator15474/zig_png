const rl = @import("raylib");
const std = @import("std");
const png = @import("png.zig");

pub fn renderPngInWindow(img_data: *png.png_data) !void {
    rl.initWindow(@intCast(img_data.width * 3), @intCast(img_data.height * 3), "zig-png - example");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        for (0..img_data.height) |x| {
            for (0..img_data.width) |y| {
                const pixel = img_data.getPixel(x, y);
                if (pixel == 1) {
                    rl.drawPixel(@intCast(x * 3), @intCast(y * 3), rl.Color.white);
                    rl.drawPixel(@intCast(x * 3 + 1), @intCast(y * 3), rl.Color.white);
                    rl.drawPixel(@intCast(x * 3 + 2), @intCast(y * 3), rl.Color.white);

                    rl.drawPixel(@intCast(x * 3), @intCast(y * 3 + 1), rl.Color.white);
                    rl.drawPixel(@intCast(x * 3 + 1), @intCast(y * 3 + 1), rl.Color.white);
                    rl.drawPixel(@intCast(x * 3 + 2), @intCast(y * 3 + 1), rl.Color.white);

                    rl.drawPixel(@intCast(x * 3), @intCast(y * 3 + 2), rl.Color.white);
                    rl.drawPixel(@intCast(x * 3 + 1), @intCast(y * 3 + 2), rl.Color.white);
                    rl.drawPixel(@intCast(x * 3 + 2), @intCast(y * 3 + 2), rl.Color.white);
                } else {
                    rl.drawPixel(@intCast(x * 3), @intCast(y * 3), rl.Color.black);
                    rl.drawPixel(@intCast(x * 3 + 1), @intCast(y * 3), rl.Color.black);
                    rl.drawPixel(@intCast(x * 3 + 2), @intCast(y * 3), rl.Color.black);

                    rl.drawPixel(@intCast(x * 3), @intCast(y * 3 + 1), rl.Color.black);
                    rl.drawPixel(@intCast(x * 3 + 1), @intCast(y * 3 + 1), rl.Color.black);
                    rl.drawPixel(@intCast(x * 3 + 2), @intCast(y * 3 + 1), rl.Color.black);

                    rl.drawPixel(@intCast(x * 3), @intCast(y * 3 + 2), rl.Color.black);
                    rl.drawPixel(@intCast(x * 3 + 1), @intCast(y * 3 + 2), rl.Color.black);
                    rl.drawPixel(@intCast(x * 3 + 2), @intCast(y * 3 + 2), rl.Color.black);
                }
            }
        }
    }
}
