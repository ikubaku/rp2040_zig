const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Writer = std.io.Writer;

// All magics are little-endian values.
const UF2_MAGIC_FIRST: u32 = 0x0A324655;
const UF2_MAGIC_SECOND: u32 = 0x9E5D5157;
const UF2_MAGIC_FINAL: u32 = 0x0AB16F30;

pub const UF2Config = struct {
    family_id: ?u32,
};

const UF2Block = packed struct {
    magic_start_0: u32 = UF2_MAGIC_FIRST,
    magic_start_1: u32 = UF2_MAGIC_SECOND,
    flags: u32,
    target_addr: u32,
    payload_size: u32,
    block_no: u32,
    num_blocks: u32,
    file_size_or_family_id: u32,
    data: [476]u8,
    magic_end: u32 = UF2_MAGIC_FINAL,
};

const UF2Error = error {
    InvalidOffset,
};

pub const UF2 = struct {
    binary: ArrayList(u8),
    binary_offset: u32,
    config: UF2Config,
    allocator: *Allocator,

    const Self = @This();

    pub fn init(allocator: *Allocator, offset: u32, config: UF2Config) Self {
        return Self {
            .binary = ArrayList(u8).init(allocator.*),
            .binary_offset = offset,
            .config = config,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(&self.binary);
    }

    pub fn addData(self: *Self, data: []const u8, offset: u32) !void {
        if(offset < self.binary_offset) return UF2Error.InvalidOffset;
        
        const local_offset = offset - self.binary_offset;
        if(self.binary.items.len < local_offset + data.len) {
            try self.enlargeAndZeroBinaryBuffer(local_offset, data.len);
        }
        try self.binary.replaceRange(local_offset, data.len, data);
    }

    pub fn write(self: *Self, writer: anytype) !void {
        // For now, we assume payload size of 256.
        const total_blocks = self.binary.items.len / 256 + 1;

        var target_address = self.binary_offset;
        var i: u32 = 0;
        while (i < total_blocks) : (i += 1) {
            var binary_index = i * 256;
            try self.writeSingleBlock(writer, self.binary.items[binary_index..], target_address, i, 256, @intCast(u32, total_blocks));
            target_address += 256;
        }
    }

    fn writeSingleBlock(self: *Self, writer: anytype, data: []const u8, target_address: u32, block_number: u32, payload_size: u32, num_blocks: u32) !void {
        var buf = [_]u8{0} ** 476;
        for (buf) |*b, i| {
            if (i >= 256) break;
            if (i >= data.len) {
                b.* = 0;
            } else {
                b.* = data[i];
            }
        }

        var block = UF2Block {
            .flags = if (self.config.family_id == null) 0x00000000 else 0x00002000,
            .target_addr = target_address,
            .payload_size = payload_size,
            .block_no = block_number,
            .num_blocks = num_blocks,
            .file_size_or_family_id = self.config.family_id orelse 0x00000000,
            .data = buf,
        };

        const block_binary = @bitCast([512]u8, block);
        _ = try writer.writeAll(block_binary[0..]);
    }

    fn enlargeAndZeroBinaryBuffer(self: *Self, needed_local_offset: u32, needed_length: usize) !void {
        const previous_last_index = if (self.binary.items.len == 0) 0 else self.binary.items.len - 1;

        try self.binary.resize(needed_local_offset + needed_length);

        var i = previous_last_index + 1;
        while (i < self.binary.items.len) : (i += 1) {
            self.binary.items[i] = 0;
        }
    }
};
