module main_ice40 (
    //input  logic clk_i,
    input  logic reset_i,
    output logic uart_tx_o,
    input  logic uart_rx_i,
    output logic ex_data_o,
    output logic spi_clk_o,
    output logic spi_mosi_o,
    input  logic spi_miso_i
    //output logic usb_dp_pull,
    //inout  logic usb_dp,
    //inout logic usb_dn
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
        .FPGAClkSpeed  (FPGAClkSpeed),
        .BaudRate6502  (BaudRate6502),
        .address_width (address_width),
        .data_width    (data_width)
    ) m1 (
        .clk_i         (clk),
        //.clk_48_i      (clk_48),
        .reset_i       ('0),
        .ex_data_o     (ex_data),
        .uart_tx_o     (uart_tx_o),
        .uart_rx_i     (uart_rx_i),
        .spi_clk_o     (spi_clk_o),
        .spi_mosi_o    (spi_mosi_o),
        .spi_miso_i    (spi_miso_i)
        //.usb_dp_pull   (usb_dp_pull),
        //.usb_dp        (usb_dp),
        //.usb_dn        (usb_dn)
    );


endmodule
