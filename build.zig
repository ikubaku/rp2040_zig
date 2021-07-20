const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const bin_name = "rp2040_zig.elf";

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

    const bin = b.addExecutable(bin_name, null);
    bin.setBuildMode(mode);

    bin.setOutputDir(switch(mode) {
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
    bin.setTarget(target);

    // Use the custom linker script to build a baremetal program
    bin.setLinkerScriptPath("src/linker.ld");
    bin.addObject(boot2);
    bin.addObject(app);

    b.default_step.dependOn(&bin.step);
}
