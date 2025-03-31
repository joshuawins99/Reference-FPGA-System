module main_cycloneiv (
    input  logic clk_i,
    input  logic reset_i,
    output logic ex_data_o,
    output logic usb_dp_pull,
    inout  wire  usb_dp,
    inout  wire  usb_dn
);
    localparam FPGAClkSpeed  = 50000000;
    localparam BaudRate6502  = 230400;
    localparam address_width = 16;
    localparam data_width    = 8;

    logic clk_48;

    pll pll1 (
        .inclk0 (clk_i),
        .c0 (clk_48)
    );

    logic [7:0] ex_data;
    assign ex_data_o = ex_data[0];

    main_6502 #(
        .FPGAClkSpeed        (FPGAClkSpeed),
        .ETHSPIClkSpeed      (10000000),
        .DACSPIClkSpeed      (10000000),
        .ADCSPIClkSpeed      (2500000),
        .MaxADCBurstReadings (13), //4096 Readings
        .BaudRate6502        (BaudRate6502),
        .address_width       (address_width),
        .data_width          (data_width)
    ) m1 (
        .clk_i               (clk_i),
        .clk_48_i            (clk_48),
        .reset_i             ('0),
        .ex_data_i           ('0),
        .ex_data_o           (ex_data),
        .uart_tx_o           (),
        .uart_rx_i           (),
        .usb_dp_pull         (usb_dp_pull),
        .usb_dp              (usb_dp),
        .usb_dn              (usb_dn),
        .eth_sclk_o          (),
        .eth_mosi_o          (),
        .eth_miso_i          (),
        .eth_reset_o         (),
        .dac_sclk_o          (),
        .dac_mosi_o          (),
        .dac_sync_no         (),
        .adc_sclk_o          (),
        .adc_miso_i          (),
        .adc_sync_no         ()
    );


endmodule
