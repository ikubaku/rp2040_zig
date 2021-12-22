const regs = @import("rp2040_ras");

const Peripheral = enum {
    IO_BANK0,
};

pub fn deassert_reset_of(perif: Peripheral) void {
    switch (perif) {
        .IO_BANK0 => regs.RESETS.RESET.modify(.{ .io_bank0 = 0 }),
    }
}
