module main_artix7 (
    input  logic clk_i,
    output logic [7:0] ex_data_o,
    input  logic uart_rx_i,
    output logic uart_tx_o
);
    localparam FPGAClkSpeed  = 100000000;
    localparam BaudRateCPU   = 230400;
    localparam address_width = 16;
    localparam data_width    = 8;

    logic [7:0] ex_data;
    //assign ex_data_o = ex_data[0];
    assign ex_data_o = ex_data;

    //logic clk_150;

    // pll_artix7 (
    //     .clk_in1  (clk_i),
    //     .reset    ('0),
    //     .locked   (),
    //     .clk_out1 (clk_150)
    // );

    main_6502 #(
        .FPGAClkSpeed        (FPGAClkSpeed),
        .ETHSPIClkSpeed      (10000000),
        .DACSPIClkSpeed      (10000000),
        .ADCSPIClkSpeed      (2500000),
        .MaxADCBurstReadings (13), //4096 Readings
        .BaudRateCPU         (BaudRateCPU),
        .address_width       (address_width),
        .data_width          (data_width)
    ) m1 (
        .clk_i               (clk_i),
        .clk_48_i            (),
        .reset_i             ('0),
        .ex_data_i           ('0),
        .ex_data_o           (ex_data),
        .uart_tx_o           (uart_tx_o),
        .uart_rx_i           (uart_rx_i),
        .usb_dp_pull         (),
        .usb_dp              (),
        .usb_dn              (),
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
