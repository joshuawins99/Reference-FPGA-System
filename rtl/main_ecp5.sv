module main_ecp5 (
    input  logic clk_i,
    input  logic reset_i,
    input  logic ex_data_i,
    output logic [7:0] ex_data_o,
    output logic usb_dp_pull,
    inout  logic usb_dp,
    inout  logic usb_dn,
    input  logic uart_rx_i,
    output logic uart_tx_o,
    output logic eth_sclk_o,
    output logic eth_mosi_o,
    input  logic eth_miso_i,
    output logic eth_reset_o,
    output logic dac_sclk_o,
    output logic dac_mosi_o,
    output logic dac_sync_no,
    output logic adc_sclk_o,
    input  logic adc_miso_i,
    output logic adc_sync_no
);
    localparam FPGAClkSpeed  = 40000000;
    localparam BaudRate6502  = 230400;
    localparam address_width = 16;
    localparam data_width    = 8;

    logic clk_48;

    pll_ecp5 pll1 (
        .clkin (clk_i),
        .clkout0 (clk_48),
        .locked ()
    );

    logic [7:0] ex_data;
    //assign ex_data_o = ex_data[0];
    assign ex_data_o = ex_data;

    main_6502 #(
        .FPGAClkSpeed        (FPGAClkSpeed),
        .ETHSPIClkSpeed      (5000000),
        .DACSPIClkSpeed      (5000000),
        .ADCSPIClkSpeed      (2500000),
        .MaxADCBurstReadings (13), //4096 Readings
        .BaudRate6502        (BaudRate6502),
        .address_width       (address_width),
        .data_width          (data_width)
    ) m1 (
        .clk_i               (clk_i),
        .clk_48_i            (clk_48),
        .reset_i             (reset_i),
        .ex_data_i           ({7'b0,ex_data_i}),
        .ex_data_o           (ex_data),
        .uart_tx_o           (uart_tx_o),
        .uart_rx_i           (uart_rx_i),
        .usb_dp_pull         (usb_dp_pull),
        .usb_dp              (usb_dp),
        .usb_dn              (usb_dn),
        .eth_sclk_o          (eth_sclk_o),
        .eth_mosi_o          (eth_mosi_o),
        .eth_miso_i          (eth_miso_i),
        .eth_reset_o         (eth_reset_o),
        .dac_sclk_o          (dac_sclk_o),
        .dac_mosi_o          (dac_mosi_o),
        .dac_sync_no         (dac_sync_no),
        .adc_sclk_o          (adc_sclk_o),
        .adc_miso_i          (adc_miso_i),
        .adc_sync_no         (adc_sync_no)
    );
    
endmodule
