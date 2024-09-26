const std = @import("std");
const png = @import("png.zig");
const render = @import("render.zig");

pub fn main() !void {
    // allocators
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = alloc.deinit();

    // args
    var args = try std.process.argsWithAllocator(alloc.allocator());
    _ = args.skip();
    defer args.deinit();
    const path = args.next() orelse "PngSuite/basn2c08.png";

    // open file and get readers
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var img_data = try png.open(file.reader(), alloc.allocator());

    _ = try std.io.getStdOut().write("\n--------------- IMAGE OUTPUT ---------------\n\n\n");
    // try render.renderPngToWriter(std.io.getStdOut().writer(), 10, 10, &img_data);
    try render.renderPngInWindow(1920, 1080, &img_data);

    var out_file = try std.fs.cwd().createFile("./out.txt", .{ .read = true });
    defer out_file.close();
    try render.renderPngToWriter(out_file.writer(), 100, 100, &img_data);
}
