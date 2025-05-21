//SystemVerilog Conversion of https://github.com/jakubcabal/uart-for-fpga
module uart #(
    parameter ClkFreq        = 50000000, //In Hz
    parameter BaudRate       = 9600,
    parameter ParityBit      = "none", //type of parity: "none", "even", "odd", "mark", "space"
    parameter UseDebouncer   = 1, //1 to enable; 0 to disable
    parameter OversampleRate = 16
)(
    input  logic       clk_i,
    input  logic       reset_i,
    output logic       uart_txd_o,
    input  logic       uart_rxd_i,
    input  logic [7:0] data_i, //Data to send
    input  logic       data_valid_i, // 1 -> When data to send is valid data
    output logic       data_in_ready_o, //1 -> When the transmitter is ready for more data
    output logic [7:0] data_o, //Received Data
    output logic       data_valid_o, //When the Received Data is valid
    output logic       frame_error_o,
    output logic       parity_error_o
);

    localparam os_clk_div_val = (ClkFreq + (OversampleRate * BaudRate) / 2) / (OversampleRate * BaudRate);
    localparam uart_clk_div_val = (ClkFreq + (os_clk_div_val * BaudRate) / 2) / (os_clk_div_val * BaudRate);

    logic os_clk_en;
    logic uart_rxd_meta_n;
    logic uart_rxd_synced_n;
    logic uart_rxd_debounced_n;
    logic uart_rxd_debounced;

    //*****************************************************
    //UART Oversampling Clock Divider and Clock Enable Flag
    //*****************************************************

    uart_clk_div #(
        .DivMaxVal  (os_clk_div_val),
        .DivMarkPos (os_clk_div_val-1)
    ) uart_clk_div_1 (
        .clk_i      (clk_i),
        .clear_i    (reset_i),
        .enable_i   (1'b1),
        .div_mark_o (os_clk_en)
    );

    //******************************
    //UART RXD Cross Domain Crossing
    //******************************

    always_ff @(posedge clk_i) begin
        uart_rxd_meta_n   <= ~uart_rxd_i;
        uart_rxd_synced_n <= uart_rxd_meta_n;
    end

    //******************
    //UART RXD Debouncer
    //******************

    generate
        if (UseDebouncer == 1) begin
            uart_debouncer #(
                .Latency (4)
            ) uart_debouncer_1 (
                .clk_i (clk_i),
                .deb_i (uart_rxd_synced_n),
                .deb_o (uart_rxd_debounced_n)
            );
        end else begin
            assign uart_rxd_debounced_n = uart_rxd_synced_n;
        end
    endgenerate

    assign uart_rxd_debounced = ~uart_rxd_debounced_n;

    //*************
    //UART Receiver
    //*************

    uart_rx #(
        .ClkDivVal (uart_clk_div_val),
        .ParityBit (ParityBit)
    ) uart_rx_1 (
        .clk_i          (clk_i),
        .reset_i        (reset_i),
        .uart_clk_en_i  (os_clk_en),
        .uart_rxd_i     (uart_rxd_debounced),
        .data_o         (data_o),
        .data_valid_o   (data_valid_o),
        .frame_error_o  (frame_error_o),
        .parity_error_o (parity_error_o)
    );

    //****************
    //UART Transmitter
    //****************

    uart_tx #(
        .ClkDivVal (uart_clk_div_val),
        .ParityBit (ParityBit)
    ) uart_tx_1 (
        .clk_i           (clk_i),
        .reset_i         (reset_i),
        .uart_clk_en_i   (os_clk_en),
        .uart_txd_o      (uart_txd_o),
        .data_i          (data_i),
        .data_valid_i    (data_valid_i),
        .data_in_ready_o (data_in_ready_o)
    );

endmodule