fn boot2_main() callconv(.Naked) noreturn {
    // Initialize the stack pointer and jump to IPL
    asm volatile(
        \\bx r1
    );

    while(true) {}
}

comptime {
    @export(boot2_main, .{
        .name = "_boot2_main",
        .linkage = .Strong,
        .section = ".boot2",
    });
}
