const std = @import("std");
const assert = std.debug.assert;
const rl = @import("raylib");

pub const png_error = error{
    FileIsNoPng,
    PngIsCorrupted,

    // generic errors
    Unexpected,
    SystemResources,
    IsDir,
    WouldBlock,
    InputOutput,
    OperationAborted,
    BrokenPipe,
    ConnectionResetByPeer,
    ConnectionTimedOut,
    NotOpenForReading,
    SocketNotConnected,
    AccessDenied,
    OutOfMemory,
    EndOfStream,
    Canceled,

    // zlib errors
    NoSpaceLeft,
    BadGzipHeader,
    BadZlibHeader,
    WrongGzipChecksum,
    WrongGzipSize,
    WrongZlibChecksum,
    InvalidCode,
    OversubscribedHuffmanTree,
    IncompleteHuffmanTree,
    MissingEndOfBlockCode,
    InvalidMatch,
    InvalidBlockType,
    WrongStoredBlockNlen,
    InvalidDynamicBlockHeader,

    // utf8 url
    Utf8ExpectedContinuation,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
};

const png_data = struct {
    const Self = @This();
    width: u32,
    height: u32,
    bit_depth: u8,
    color: u8,
    compression: u8,
    filter: u8,
    interlace: u8,
    pixels: ?[]u8,

    pub fn getPixel(self: *Self, x: usize, y: usize) u8 {
        if (self.pixels) |pixels| {
            return pixels[self.width * y + (self.width - x - 1)];
        } else {
            return 0;
        }
    }

    pub fn getScanline(self: *Self, y: usize) []u8 {
        assert(y <= self.height);
        if (self.pixels) |pixels| {
            return pixels[self.width * y .. self.width * y + self.height];
        } else {
            return &[_]u8{};
        }
    }
};

const PNG_SIGNATURE = [_]u8{ 137, 80, 78, 71, 13, 10, 26, 10 };

const IHDR = std.mem.nativeToBig(u32, std.mem.bytesToValue(u32, "IHDR"));
const gAMA = std.mem.nativeToBig(u32, std.mem.bytesToValue(u32, "gAMA"));
const IDAT = std.mem.nativeToBig(u32, std.mem.bytesToValue(u32, "IDAT"));
const IEND = std.mem.nativeToBig(u32, std.mem.bytesToValue(u32, "IEND"));

pub fn open(file_reader: anytype, allocator: std.mem.Allocator) png_error!png_data {
    // setup
    var br = std.io.bufferedReader(file_reader);
    const reader = br.reader();
    // read header
    const out_bits = try allocator.alloc(u8, 8);
    assert(try reader.read(out_bits) == 8);

    // check for correct data
    if (!std.mem.eql(u8, out_bits, &PNG_SIGNATURE)) {
        return error.FileIsNoPng;
    }

    // generic chunk metadata
    var chunk_type: u32 = 0;
    var crc_expected: u32 = 0;
    var IDAT_data: []u8 = &[_]u8{};

    var image_data = png_data{
        .width = 0,
        .height = 0,
        .bit_depth = 0,
        .color = 0,
        .compression = 0,
        .filter = 0,
        .interlace = 0,
        .pixels = null,
    };

    // read chunks until IEND
    while (IEND != chunk_type) {
        var crc = std.hash.crc.Crc32IsoHdlc.init();

        // read generic metadata
        const len = try reader.readInt(u32, .big);

        chunk_type = try reader.readInt(u32, .big);
        crc.update(&@as([4]u8, @bitCast(std.mem.bigToNative(u32, chunk_type))));

        const data_buffer = try allocator.alloc(u8, len);
        assert(try reader.read(data_buffer) == @as(usize, len));

        switch (chunk_type) {
            IHDR => image_data = try handle_IHDR(data_buffer),
            IDAT => {
                IDAT_data = try std.mem.concat(allocator, u8, &[_][]u8{ IDAT_data, data_buffer });
                std.log.debug("IDAT: {d}; data_buffer: {d}", .{ IDAT_data.len, data_buffer.len });
            },
            IEND => try handle_IDAT(allocator, &image_data, IDAT_data),
            else => _ = 0,
        }

        crc_expected = try reader.readInt(u32, .big);

        crc.update(data_buffer);
        const crc_calculated = crc.final();
        std.log.debug("Length: {d}, Chunk type: {s}, Expected CRC: {d}, Calculated CRC: {d}\n", .{ len, @as([4]u8, @bitCast(std.mem.bigToNative(u32, chunk_type))), crc_expected, crc_calculated });
        assert(crc_expected == crc_calculated);
    }

    return image_data;
}

fn handle_IHDR(buf: []u8) png_error!png_data {
    std.log.debug("----------------------------------- PARSING IHDR ---------------------------------\n", .{});

    var stream = std.io.fixedBufferStream(buf);
    var reader = stream.reader();

    const width = try reader.readInt(u32, .big);
    const height = try reader.readInt(u32, .big);
    const bit = try reader.readInt(u8, .big);
    const color = try reader.readInt(u8, .big);
    const compression = try reader.readInt(u8, .big);
    const filter = try reader.readInt(u8, .big);
    const interlace = try reader.readInt(u8, .big);

    const data = png_data{
        .width = width,
        .height = height,
        .bit_depth = bit,
        .color = color,
        .compression = compression,
        .filter = filter,
        .interlace = interlace,
        .pixels = null,
    };
    std.log.debug("IDAT: {any}", .{data});
    return data;
}

fn handle_IDAT(allocator: std.mem.Allocator, img_data: *png_data, buf: []u8) !void {
    std.log.debug("\n----------------------------------- PARSING IDAT ---------------------------------\n", .{});

    var in_stream = std.io.fixedBufferStream(buf);
    const reader = in_stream.reader();
    const data = try allocator.alloc(u8, img_data.width * img_data.height * 2);
    var out_stream = std.io.fixedBufferStream(data);
    const writer = out_stream.writer();

    try std.compress.zlib.decompress(reader, writer);
    std.log.debug("\n Length: {d}", .{data.len});

    var decompressed_stream = std.io.fixedBufferStream(data);
    const decompressed_reader = decompressed_stream.reader();
    var br = std.io.bitReader(.big, decompressed_reader);
    var out_bits: usize = @as(usize, 0);

    const pixel_data = try allocator.alloc(u8, img_data.width * img_data.height);

    // iterate over every pixel
    for (pixel_data, 0..) |_, i| {
        if (i % img_data.width == 0) {
            const filtered = try br.readBits(u8, 8, &out_bits);
            _ = filtered;
            continue;
        }
        pixel_data[i] = try br.readBits(u8, img_data.bit_depth, &out_bits);
    }
    img_data.pixels = pixel_data;
}

pub fn view(img_data: *png_data) !void {
    rl.initWindow(u2i(img_data.width * 3), u2i(img_data.height * 3), "zig-png - example");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        for (0..img_data.height) |x| {
            for (0..img_data.width) |y| {
                const pixel = img_data.getPixel(x, y);
                if (pixel == 1) {
                    rl.drawPixel(u2i(x * 3), u2i(x * 3), rl.Color.white);
                    rl.drawPixel(u2i(x * 3 + 1), u2i(y * 3), rl.Color.white);
                    rl.drawPixel(u2i(x * 3 + 2), u2i(y * 3), rl.Color.white);

                    rl.drawPixel(u2i(x * 3), u2i(x * 3 + 1), rl.Color.white);
                    rl.drawPixel(u2i(x * 3 + 1), u2i(y * 3 + 1), rl.Color.white);
                    rl.drawPixel(u2i(x * 3 + 2), u2i(y * 3 + 1), rl.Color.white);

                    rl.drawPixel(u2i(x * 3), u2i(x * 3 + 2), rl.Color.white);
                    rl.drawPixel(u2i(x * 3 + 1), u2i(y * 3 + 2), rl.Color.white);
                    rl.drawPixel(u2i(x * 3 + 2), u2i(y * 3 + 2), rl.Color.white);
                } else {
                    rl.drawPixel(u2i(x * 3), u2i(x * 3), rl.Color.black);
                    rl.drawPixel(u2i(x * 3 + 1), u2i(y * 3), rl.Color.black);
                    rl.drawPixel(u2i(x * 3 + 2), u2i(y * 3), rl.Color.black);

                    rl.drawPixel(u2i(x * 3), u2i(x * 3 + 1), rl.Color.black);
                    rl.drawPixel(u2i(x * 3 + 1), u2i(y * 3 + 1), rl.Color.black);
                    rl.drawPixel(u2i(x * 3 + 2), u2i(y * 3 + 1), rl.Color.black);

                    rl.drawPixel(u2i(x * 3), u2i(x * 3 + 2), rl.Color.black);
                    rl.drawPixel(u2i(x * 3 + 1), u2i(y * 3 + 2), rl.Color.black);
                    rl.drawPixel(u2i(x * 3 + 2), u2i(y * 3 + 2), rl.Color.black);
                }
            }
        }
    }
}

fn u2i(num: anytype) i32 {
    return @intCast(num);
}
