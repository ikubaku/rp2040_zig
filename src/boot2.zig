// Tl; dr: This code is the reimplementation of the second stage bootloader
// available in the Raspberry Pi Pico SDK (https://github.com/raspberrypi/pico-sdk/blob/afc10f3599c27147a6f34781b7102d86f58aa5f6/src/rp2_common/boot_stage2/boot2_w25q080.S#L268)
// This source code includes modified codes from the source codes in the 
// Raspberry Pi Pico SDK. Following comments are the original license notices
// in the source code.

// // ----------------------------------------------------------------------------
// // Second stage boot code
// // Copyright (c) 2019-2021 Raspberry Pi (Trading) Ltd.
// // SPDX-License-Identifier: BSD-3-Clause

// End of the original license notice.

// The long story about why I rewrite the bootloader in Zig:
// To make your program work on a RP2040, you must link it against the second stage
// bootloader, which prepares the MCU's XIP and the external flash to run your code
// at the best performance. Normally, the SDK will build and stick the bootloader
// binary to your executable in the SDK's build process. However, the SDK is
// developed to work with codes written in C/C++ language, and there is no simple way
// to integrate the build process with the  Zig's build script (maybe I'm missing
// something). So I decided to write the same code as the bootloader in Zig to
// make the build process simple as all you have to do is to run `zig build`.

const regs = @import("hal/peripheral_access.zig");

fn boot2_main() callconv(.Naked) noreturn {
    asm volatile(
        \\push {lr}
    );

    regs.PADS_QSPI.GPIO_QSPI_SCLK.write_raw(0b00000000_00000000_00000000_01100111);
    regs.PADS_QSPI.GPIO_QSPI_SD0.modify(.{ .SCHMITT = 0 });
    const sd0 = regs.PADS_QSPI.GPIO_QSPI_SD0.read_raw();
    regs.PADS_QSPI.GPIO_QSPI_SD1.write_raw(sd0);
    regs.PADS_QSPI.GPIO_QSPI_SD2.write_raw(sd0);
    regs.PADS_QSPI.GPIO_QSPI_SD3.write_raw(sd0);

    regs.XIP_SSI.SSIENR.write_raw(0);

    regs.XIP_SSI.BAUDR.write_raw(4);    // TODO: Replace the parameter with a constant or a build option value.

    regs.XIP_SSI.RX_SAMPLE_DLY.write_raw(1);

    regs.XIP_SSI.CTRLR0.write_raw(0b00000000_00000111_00000000_00000000);

    regs.XIP_SSI.SSIENR.write_raw(1);

    if (read_flash_sreg(0x35) != 0x02) {
        regs.XIP_SSI.DR0.write_raw(0x06);

        wait_ssi_ready();
        _ = regs.XIP_SSI.DR0.read_raw();

        regs.XIP_SSI.DR0.write_raw(0x01);
        regs.XIP_SSI.DR0.write_raw(0x00);
        regs.XIP_SSI.DR0.write_raw(0x02);

        wait_ssi_ready();
        _ = regs.XIP_SSI.DR0.read_raw();
        _ = regs.XIP_SSI.DR0.read_raw();
        _ = regs.XIP_SSI.DR0.read_raw();

        while(read_flash_sreg(0x05) & 1 == 0) {}
    }

    regs.XIP_SSI.SSIENR.write_raw(0);

    regs.XIP_SSI.CTRLR0.write_raw(0b00000000_01011111_00000011_00000000);

    regs.XIP_SSI.CTRLR1.write_raw(0);

    regs.XIP_SSI.SPI_CTRLR0.write_raw(0b00000000_00000000_00100010_00100001);

    regs.XIP_SSI.SSIENR.write_raw(1);

    regs.XIP_SSI.DR0.write_raw(0xEB);
    regs.XIP_SSI.DR0.write_raw(0xA0);

    wait_ssi_ready();

    regs.XIP_SSI.SSIENR.write_raw(0);

    regs.XIP_SSI.SPI_CTRLR0.write_raw(0b10100000_00000000_00100000_00100010);

    regs.XIP_SSI.SSIENR.write_raw(1);

    asm volatile (
        \\ pop {r0}
        \\ cmp r0, #0
        \\ beq skip_return
        \\ bx r0
        \\ skip_return:
        \\ ldr r0, =0x10000100
        \\ ldr r1, =0xE000ED08
        \\ str r0, [r1]
        \\ ldmia r0, {r0, r1}
        \\ msr msp, r0
        \\ bx r1
    );

    while(true) {}
}

fn read_flash_sreg(cmd: u32) callconv(.Inline) u32 {
    regs.XIP_SSI.DR0.write_raw(cmd);
    regs.XIP_SSI.DR0.write_raw(cmd);

    wait_ssi_ready();

    _ = regs.XIP_SSI.DR0.read_raw();
    return regs.XIP_SSI.DR0.read_raw();
}

fn wait_ssi_ready() callconv(.Inline) void {
    while(regs.XIP_SSI.SR.read_raw() & (1 << 2) == 0) {}
    while(regs.XIP_SSI.SR.read_raw() & 1 != 0) {}
}

comptime {
    @export(boot2_main, .{
        .name = "_boot2_main",
        .linkage = .Strong,
        .section = ".boot2",
    });
}
