module usb_uart (
  input  clk_48mhz,
  input reset,

  // USB pins
  inout wire pin_usb_p,
  inout wire pin_usb_n,

  // uart pipeline in (out of the device, into the host)
  input [7:0] uart_in_data,
  input       uart_in_valid,
  output      uart_in_ready,

  // uart pipeline out (into the device, out of the host)
  output [7:0] uart_out_data,
  output       uart_out_valid,
  input        uart_out_ready,

  output [11:0] debug
);

    wire usb_p_tx;
    wire usb_n_tx;
    wire usb_p_rx;
    wire usb_n_rx;
    wire usb_tx_en;

    //wire [3:0] debug;

    wire reset_int;

    usb_reset_det usb_reset1 (
      .clk (clk_48mhz),
      .reset (reset_int),
      .usb_p_rx (usb_p_rx),
      .usb_n_rx (usb_n_rx)
    );

    usb_uart_core uart (
        .clk_48mhz  (clk_48mhz),
        .reset      (reset),

        // pins - these must be connected properly to the outside world.  See below.
        .usb_p_tx(usb_p_tx),
        .usb_n_tx(usb_n_tx),
        .usb_p_rx(usb_p_rx),
        .usb_n_rx(usb_n_rx),
        .usb_tx_en(usb_tx_en),

        // uart pipeline in
        .uart_in_data( uart_in_data ),
        .uart_in_valid( uart_in_valid ),
        .uart_in_ready( uart_in_ready ),

        // uart pipeline out
        .uart_out_data( uart_out_data ),
        .uart_out_valid( uart_out_valid ),
        .uart_out_ready( uart_out_ready ),

        .debug( debug )
    );

    wire usb_p_in;
    wire usb_n_in;

    assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
    assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;


    assign pin_usb_p = usb_tx_en ? usb_p_tx : 1'bZ;
    assign usb_p_in = pin_usb_p;

    assign pin_usb_n = usb_tx_en ? usb_n_tx : 1'bZ;
    assign usb_n_in = pin_usb_n;

endmodule
