const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;
const Step = std.build.Step;
const Crc32WithPoly = std.hash.crc.Crc32WithPoly;
const Polynomial = std.hash.crc.Polynomial;
const ElfHeader = std.elf.Header;

const uf2 = @import("build/uf2.zig");
const UF2 = uf2.UF2;

const FILE_DELIM = switch(builtin.os.tag) {
    .windows => "\\",
    else => "/",            // Are we sure about that?
};

const FlashKind = enum {
    W25Q080,
};

pub fn build(b: *Builder) void {
    const output_name = "rp2040_zig";
    const elf_name = output_name ++ ".elf";
    const uf2_name = output_name ++ ".uf2";

    const flash_kind = b.option(FlashKind, "flash-kind", "The flash memory kind to boot from") orelse FlashKind.W25Q080;
    const is_release_small_boot2 = b.option(bool, "release-small-ipl", "Use space-optimized version of the IPL");

    const mode = b.standardReleaseOptions();

    const rp2040_ras = std.build.Pkg {
        .name = "rp2040_ras",
        .path = 
            std.build.FileSource{
                .path = "rp2040_ras/rp2040_ras.zig",
            },
    };

    const boot2_source = switch (flash_kind) {
        .W25Q080 => "src/ipl/w25q080.zig",
    };
    const boot2 = b.addObject("boot2", boot2_source);
    if(is_release_small_boot2 orelse false) {
        boot2.setBuildMode(.ReleaseSmall);
    } else {
        boot2.setBuildMode(mode);
    }

    const app = b.addObject("app", "src/runtime.zig");
    app.setBuildMode(mode);

    const elf = b.addExecutable(elf_name, null);
    elf.setBuildMode(mode);

    elf.setOutputDir(switch(mode) {
        .Debug => "Binary/Debug",
        .ReleaseSafe => "Binary/ReleaseSafe",
        .ReleaseFast => "Binary/ReleaseFast",
        .ReleaseSmall => "Binary/ReleaseSmall",
    });

    // Set the target to thumbv6m-freestanding-eabi
    const target = std.zig.CrossTarget{
        .os_tag = .freestanding,
        .cpu_arch = .thumb,
        .cpu_model = .{
            .explicit = &std.Target.arm.cpu.cortex_m0plus,
        },
        .abi = .eabi,
    };
    boot2.setTarget(target);
    app.setTarget(target);
    elf.setTarget(target);

    boot2.addPackage(rp2040_ras);
    app.addPackage(rp2040_ras);

    // Use the custom linker script to build a baremetal program
    elf.setLinkerScriptPath(
        std.build.FileSource{
            .path = "src/linker.ld",
        }
    );
    elf.addObject(boot2);
    elf.addObject(app);

    var write_checksum = b.allocator.create(WriteChecksumStep) catch unreachable;
    write_checksum.* = WriteChecksumStep.init(
        b,
        "checksum",
        elf.getOutputSource(),
    );
    write_checksum.step.dependOn(&elf.step);

    var generate_uf2 = b.allocator.create(GenerateUF2Step) catch unreachable;
    const uf2_output_path = std.mem.concat(b.allocator, u8, &[_][]const u8{
        elf.output_dir orelse unreachable,
        FILE_DELIM,
        uf2_name,
    }) catch unreachable;
    generate_uf2.* = GenerateUF2Step.init(
        b,
        "uf2",
        elf.getOutputSource(),
        uf2_output_path,
    );
    generate_uf2.step.dependOn(&write_checksum.step);

    b.default_step.dependOn(&generate_uf2.step);
}

const WriteChecksumStepError = error {
    InvalidExecutableSize,
    IPLSectionNotFound,
};

const WriteChecksumStep = struct {
    step: Step,
    elf_file_source: std.build.FileSource,
    builder: *std.build.Builder,

    pub fn init(
        builder: *std.build.Builder,
        name: []const u8,
        elf_file_source: std.build.FileSource,
    ) WriteChecksumStep {
        return .{
            .step = Step.init(.custom, name, builder.allocator, write_checksum),
            .elf_file_source = elf_file_source,
            .builder = builder,
        };
    }

    fn write_checksum(step: *Step) !void {
        const self = @fieldParentPtr(WriteChecksumStep, "step", step);
        const elf_filename = self.elf_file_source.getPath(self.builder);

        const elf_file = try std.fs.cwd().openFile(
            elf_filename,
            .{
                .read = true,
                .write = true,
            }
        );
        defer elf_file.close();

        const reader = elf_file.reader();
        const writer = elf_file.writer();

        const elf_header = try ElfHeader.read(elf_file);
        var found_file_offset: ?u32 = null;
        var prog_header_it = elf_header.program_header_iterator(elf_file);
        while (try prog_header_it.next()) |header| {
            const file_offset = header.p_offset;
            const section_size = header.p_filesz;
            const target_address = header.p_paddr;
            if(section_size == 256 and target_address == 0x10000000) {
                found_file_offset = @intCast(u32, file_offset);
            }
        }

        const ipl_file_offset = found_file_offset orelse return WriteChecksumStepError.IPLSectionNotFound;

        var boot2_binary: [252]u8 = undefined;
        try elf_file.seekTo(ipl_file_offset);
        const length = try reader.readAll(boot2_binary[0..]);
        if(length != 252) return WriteChecksumStepError.InvalidExecutableSize;

        // Polynomial: 0x04C11DB7 (0xEDB88320 when reversed)
        // Initial value: 0xFFFFFFFF (same as the Zig's implementation)
        // Input/result reflection: no (yes for the Zig's implementation)
        // Final XOR value: 0x00000000 (0xFFFFFFFF for the Zig's implementation)

        // We need to bitReverse both the input bytes and the result.
        // Also, the result should be inverted.
        for (boot2_binary) |b, i| {
            boot2_binary[i] = @bitReverse(u8, b);
        }
        const Crc32RaspberryPi = Crc32WithPoly(@intToEnum(Polynomial, 0xEDB88320));
        const checksum = ~@bitReverse(u32, Crc32RaspberryPi.hash(boot2_binary[0..]));

        var checksum_buf: [4]u8 = undefined;
        std.mem.writeIntLittle(u32, &checksum_buf, checksum);
        try elf_file.seekTo(ipl_file_offset + 252);
        try writer.writeAll(checksum_buf[0..]);
    }
};

const GenerateUF2Step = struct {
    step: Step,
    elf_file_source: std.build.FileSource,
    uf2_filename: []const u8,
    builder: *std.build.Builder,

    pub fn init(
        builder: *std.build.Builder,
        name: []const u8,
        elf_file_source: std.build.FileSource,
        uf2_filename: []const u8,
    ) GenerateUF2Step {
        return .{
            .step = Step.init(.custom, name, builder.allocator, generate_uf2),
            .elf_file_source = elf_file_source,
            .uf2_filename = uf2_filename,
            .builder = builder,
        };
    }

    fn generate_uf2(step: *Step) !void {
        const self = @fieldParentPtr(GenerateUF2Step, "step", step);
        const elf_filename = self.elf_file_source.getPath(self.builder);

        const elf_file = try std.fs.cwd().openFile(
            elf_filename,
            .{
                .read = true,
            },
        );
        defer elf_file.close();
        const uf2_file = try std.fs.cwd().createFile(
            self.uf2_filename,
            .{
                .truncate = true,
            },
        );
        defer uf2_file.close();

        const reader = elf_file.reader();
        const writer = uf2_file.writer();

        var uf2_writer = UF2.init(&self.builder.allocator, 0x10000000, .{ .family_id = 0xe48bff56 });
        defer uf2_writer.deinit();

        const elf_header = try ElfHeader.read(elf_file);
        var prog_header_it = elf_header.program_header_iterator(elf_file);
        while (try prog_header_it.next()) |header| {
            if(header.p_filesz == 0) continue;
            const file_offset = header.p_offset;
            const section_size = header.p_filesz;
            const target_address = header.p_paddr;

            try elf_file.seekTo(file_offset);
            var read_len: usize = 0;
            while (read_len < section_size) {
                var buf: [256]u8 = undefined;
                const bytes = try reader.readAll(buf[0..]);
                const chunk_len = if (read_len + bytes > section_size) section_size - read_len else bytes;
                try uf2_writer.addData(buf[0..chunk_len], @intCast(u32, target_address + read_len));
                read_len += bytes;
            }
        }

        try uf2_writer.write(&writer);
    }
};
