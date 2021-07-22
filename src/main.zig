const gpio = @import("hal/gpio.zig");
const sio = @import("hal/sio.zig");
const reset = @import("hal/reset.zig");

pub fn hako_main() noreturn {
    reset.deassert_reset_of(.IO_BANK0);

    gpio.set_dir(.P25, .Output);
    gpio.set_function(.P25, .F5);

    sio.set_output_enable(.GPIO25);

    while (true) {
        sio.set_output(.GPIO25);
        busy_wait();

        sio.clear_output(.GPIO25);
        busy_wait();
    }
}

fn busy_wait() void {
    var i: usize = 0;
    while (i < 100_000) : (i += 1) {}
}
