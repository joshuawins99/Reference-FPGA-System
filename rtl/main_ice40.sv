module main_ice40 (
    //input  logic clk_i,
    input  logic reset_i,
    output logic uart_tx_o,
    input  logic uart_rx_i,
    output logic ex_data_o,
    output logic eth_sclk_o,
    output logic eth_mosi_o,
    input  logic eth_miso_i
);
    localparam FPGAClkSpeed  = 12000000;
    localparam BaudRate6502  = 230400;
    localparam address_width = 16;
    localparam data_width    = 8;

    logic clk;
    //logic clk_48;

     SB_HFOSC u_hfosc (
         .CLKHFPU(1'b1),
         .CLKHFEN(1'b1),
         .CLKHF(clk)
     );

    //0b00 = 48 MHz, 0b01 = 24 MHz, 0b10 = 12 MHz, 0b11 = 6 MHz
    defparam u_hfosc.CLKHF_DIV = "0b10";

    // SB_PLL40_CORE #(
    //     .FEEDBACK_PATH("SIMPLE"),
    //     .DIVR(4'b0000),
    //     .DIVF(7'b0111111),
    //     .DIVQ(3'b100),
    //     .FILTER_RANGE(3'b001)
    // ) uut (
    //     .LOCK(locked),
    //     .RESETB(1'b1),
    //     .BYPASS(1'b0),
    //     .REFERENCECLK(clk_i),
    //     .PLLOUTCORE(clk_48)
    // );

    logic [7:0] ex_data;
    assign ex_data_o = !ex_data[0];

    main_6502 #(
        .FPGAClkSpeed        (FPGAClkSpeed),
        .ETHSPIClkSpeed      (1000000),
        .DACSPIClkSpeed      (1000000),
        .ADCSPIClkSpeed      (1000000),
        .MaxADCBurstReadings (9), //256 Readings
        .BaudRate6502        (BaudRate6502),
        .address_width       (address_width),
        .data_width          (data_width)
    ) m1 (
        .clk_i               (clk),
        .clk_48_i            (),
        .reset_i             ('0),
        .ex_data_i           ('0),
        .ex_data_o           (ex_data),
        .uart_tx_o           (uart_tx_o),
        .uart_rx_i           (uart_rx_i),
        .usb_dp_pull         (),
        .usb_dp              (),
        .usb_dn              (),
        .eth_sclk_o          (eth_sclk_o),
        .eth_mosi_o          (eth_mosi_o),
        .eth_miso_i          (eth_miso_i),
        .eth_reset_o         (),
        .dac_sclk_o          (),
        .dac_mosi_o          (),
        .dac_sync_no         (),
        .adc_sclk_o          (),
        .adc_miso_i          ('0),
        .adc_sync_no         ()
    );


endmodule
