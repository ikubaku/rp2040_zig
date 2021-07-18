const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const bin_name = "rp2040_zig.elf";

    const mode = b.standardReleaseOptions();
    const bin = b.addExecutable(bin_name, "src/ipl.zig");
    bin.setOutputDir("Debug");
    bin.setBuildMode(mode);

    // Set the target to thumbv6m-freestanding-eabi
    const target = std.zig.CrossTarget{
        .os_tag = .freestanding,
        .cpu_arch = .thumb,
        .cpu_model = .{
            .explicit = &std.Target.arm.cpu.cortex_m0plus,
        },
        .abi = .eabi,
    };
    bin.setTarget(target);

    // Use the custom linker script to build a baremetal program
    bin.setLinkerScriptPath("src/linker.ld");
    const run_objcopy = b.addSystemCommand(&[_][]const u8{
        "llvm-objcopy", bin.getOutputPath(),
        "-O",           "elf32-littlearm",
        bin_name,
    });
    run_objcopy.step.dependOn(&bin.step);

    b.default_step.dependOn(&run_objcopy.step);
}
