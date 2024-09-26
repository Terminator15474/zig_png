const rl = @import("raylib");
const std = @import("std");
const png = @import("png.zig");

pub fn renderPngInWindow(width: u32, height: u32, img_data: *png.png_data) !void {
    rl.setTraceLogLevel(rl.TraceLogLevel.log_fatal);
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
                var pixel = img_data.getPixel(x, y);
                drawPixelScaledRL(@intCast(x), @intCast(y), scaleX, scaleY, pixel.toRLColor());
            }
        }
    }
}

fn drawPixelScaledRL(x: u32, y: u32, scaleX: u32, scaleY: u32, color: rl.Color) void {
    for (0..scaleX) |i| {
        for (0..scaleY) |j| {
            rl.drawPixel(@intCast(x * scaleX + i), @intCast(y * scaleY + j), color);
        }
    }
}

pub fn renderPngToWriter(writer: anytype, width: u32, height: u32, img_data: *png.png_data) !void {
    _ = width;
    _ = height;
    for (0..img_data.height) |y| {
        for (0..img_data.width) |x| {
            const pixel = img_data.getPixel(x, y);
            try drawPixelANSI(pixel, writer);
        }
        try resetAnsiColors(writer);
        _ = try writer.write("\n");
    }
}

fn drawPixelANSI(color: png.Color, writer: anytype) !void {
    _ = try writer.write(&[_]u8{0x1B});
    try std.fmt.format(writer, "[48;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
    _ = try writer.write("  ");
}

inline fn resetAnsiColors(writer: anytype) !void {
    _ = try writer.write(&[_]u8{0x1B});
    _ = try writer.write("[0m");
}
