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
                const pixel = getPixelRLColor(img_data.getPixel(x, y), img_data);
                drawPixelScaled(@intCast(x), @intCast(y), scaleX, scaleY, pixel);
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

fn getPixelRLColor(pixel: u8, img_data: *png.png_data) rl.Color {
    const max_val = @as(f32, @floatFromInt(std.math.pow(u8, 2, img_data.bit_depth) - 1));

    switch (img_data.color) {
        0 => {
            const f32_pixel = @as(f32, @floatFromInt(pixel));
            const scaled_float: f32 = f32_pixel / max_val;
            const scaled_int = @as(u8, @intFromFloat(scaled_float * 255.0));
            std.log.debug("max: {d}, f32: {d}, sf: {d}, u8: {d}", .{ max_val, f32_pixel, scaled_float, scaled_int });
            return rl.Color.init(scaled_int, scaled_int, scaled_int, 255);
        },
        2 => return rl.Color.init(pixel, pixel, pixel, 255),
        else => unreachable,
    }
}
