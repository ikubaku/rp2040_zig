const gpio = @import("hal/gpio.zig");
const sio = @import("hal/sio.zig");

pub fn hako_main() noreturn {
    gpio.set_dir(.P25, .Output);
    gpio.set_function(.P25, .F5);

    sio.set_output_enable(.GPIO25);
    sio.set_output(.GPIO25);

    while (true) {
        //gpio.led_on();
        //uart_api.gets(uart0, &recv_buf, RECV_BUFSIZE);

        //gpio.led_off();
        //uart_api.println(uart0, &recv_buf, RECV_BUFSIZE);
    }
}
