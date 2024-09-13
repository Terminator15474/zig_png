const std = @import("std");
const png = @import("png.zig");
pub fn main() !void {
    // allocators
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = alloc.deinit();

    // args
    var args = try std.process.argsWithAllocator(alloc.allocator());
    _ = args.skip();
    defer args.deinit();
    const path = args.next() orelse "PngSuite/basn0g01.png";
    // open file and get readers
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var img_data = try png.open(file.reader(), alloc.allocator());
    try png.view(&img_data);
}
