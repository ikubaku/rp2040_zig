const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;
const Step = std.build.Step;
const Crc32WithPoly = std.hash.crc.Crc32WithPoly;
const Polynomial = std.hash.crc.Polynomial;

const FILE_DELIM = switch(builtin.os.tag) {
    .windows => "\\",
    else => "/",            // Are we sure about that?
};

pub fn build(b: *Builder) void {
    const output_name = "rp2040_zig";
    const elf_name = output_name ++ ".elf";
    const bin_name = output_name ++ ".bin";

    //const flash_kind = b.option([]const u8, "flash-kind", "The flash memory kind to boot from");
    const is_release_small_boot2 = b.option(bool, "release-small-boot2", "Use space-optimized version of the stage 2 bootloader");

    const mode = b.standardReleaseOptions();

    const boot2 = b.addObject("boot2", "src/boot2.zig");
    if(is_release_small_boot2 orelse false) {
        boot2.setBuildMode(.ReleaseSmall);
    } else {
        boot2.setBuildMode(mode);
    }

    const app = b.addObject("app", "src/ipl.zig");
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

    // Use the custom linker script to build a baremetal program
    elf.setLinkerScriptPath("src/linker.ld");
    elf.addObject(boot2);
    elf.addObject(app);

    const bin_output_path = std.mem.concat(b.allocator, u8, &[_][]const u8{
        elf.output_dir orelse unreachable,
        FILE_DELIM,
        bin_name,
    }) catch unreachable;
    const run_objcopy = b.addSystemCommand(&[_][]const u8 {
        "arm-none-eabi-objcopy", elf.getOutputPath(),
        "-O", "binary",
        bin_output_path,
    });

    run_objcopy.step.dependOn(&elf.step);

    var write_checksum = b.allocator.create(WriteChecksumStep) catch unreachable;
    write_checksum.* = WriteChecksumStep.init(
        b.allocator,
        "checksum",
        bin_output_path,
    );
    write_checksum.step.dependOn(&run_objcopy.step);

    b.default_step.dependOn(&write_checksum.step);
}

const WriteChecksumStepError = error {
    InvalidExecutableSize,
};

const WriteChecksumStep = struct {
    step: Step,
    bin_filename: []const u8,

    pub fn init(
        allocator: *std.mem.Allocator,
        name: []const u8,
        bin_filename: []const u8,
    ) WriteChecksumStep {
        return .{
            .step = Step.init(.Custom, name, allocator, write_checksum),
            .bin_filename = bin_filename,
        };
    }

    fn write_checksum(step: *Step) !void {
        const self = @fieldParentPtr(WriteChecksumStep, "step", step);

        const bin_file = try std.fs.cwd().openFile(
            self.bin_filename,
            .{
                .read = true,
                .write = true,
            }
        );
        defer bin_file.close();

        const reader = bin_file.reader();
        const writer = bin_file.writer();
        var boot2_binary: [252]u8 = undefined;
        const length = try reader.readAll(boot2_binary[0..]);
        if(length != 252) return WriteChecksumStepError.InvalidExecutableSize;

        const Crc32RaspberryPi = Crc32WithPoly(@intToEnum(Polynomial, 0x04C11DB7));
        // The Zig's CRC32 implementation inverts the internal result (which means
        // it uses 0xFFFFFFFF as the final XOR value). We must invert the return value to
        // meet the checksum specification.
        const checksum = ~Crc32RaspberryPi.hash(boot2_binary[0..]);

        var checksum_buf: [4]u8 = undefined;
        std.mem.writeIntLittle(u32, &checksum_buf, checksum);
        try bin_file.seekTo(252);
        try writer.writeAll(checksum_buf[0..]);
    }
};
