module uart_tx #(
    parameter ClkDivVal = 16,
    parameter ParityBit = "none"
)(
    input  logic       clk_i,
    input  logic       reset_i,
    input  logic       uart_clk_en_i,
    output logic       uart_txd_o,
    input  logic [7:0] data_i,
    input  logic       data_valid_i,
    output logic       data_in_ready_o
);

    logic       tx_clk_en;
    logic       tx_clk_div_clr;
    logic [7:0] tx_data;
    logic [2:0] tx_bit_count;
    logic       tx_bit_count_en;
    logic       tx_ready;
    logic       tx_parity_bit;
    logic [1:0] tx_data_out_sel;

    typedef enum logic [3:0] {idle_e, txsync_e, startbit_e, databits_e, paritybit_e, stopbit_e} state_t;

    state_t tx_pstate;
    state_t tx_nstate;

    assign data_in_ready_o = tx_ready;

    //****************************************************
    //UART Transmitter Clock Divider and Clock Enable Flag
    //****************************************************

    uart_clk_div #(
        .DivMaxVal  (ClkDivVal),
        .DivMarkPos (1)
    ) tx_clk_divider_1 (
        .clk_i      (clk_i),
        .reset_i    (reset_i),
        .clear_i    (tx_clk_div_clr),
        .enable_i   (uart_clk_en_i),
        .div_mark_o (tx_clk_en)
    );

    //************************************
    //UART Transmitter Input Data Register
    //************************************

    always_ff @(posedge clk_i) begin
        if (data_valid_i == 1'b1 && tx_ready == 1'b1) begin
            tx_data <= data_i;
        end
    end

    //****************************
    //UART Transmitter Bit Counter
    //****************************

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            tx_bit_count <= '0;
        end else if (tx_bit_count_en == 1'b1 && tx_clk_en == 1'b1) begin
            if (tx_bit_count == 7) begin
                tx_bit_count <= '0;
            end else begin
                tx_bit_count <= tx_bit_count + 1'b1;
            end
        end
    end

    //*********************************
    //UART Transmitter Parity Generator
    //*********************************

    generate
        if (ParityBit != "none") begin
            uart_parity #(
                .DataWidth  (8),
                .ParityType (ParityBit)
            ) uart_tx_parity_gen_1 (
                .data_i     (tx_data),
                .parity_o   (tx_parity_bit)
            );
        end else begin
            assign tx_parity_bit = '0;
        end
    endgenerate

    //*************************************
    //UART Transmitter Output Data Register
    //*************************************

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            uart_txd_o <= 1'b1;
        end else begin
            unique case (tx_data_out_sel)
                1 : begin //Start Bit
                    uart_txd_o <= 1'b0;
                end
                2 : begin //Data Bits
                    uart_txd_o <= tx_data[tx_bit_count];
                end
                3 : begin //Parity Bit
                    uart_txd_o <= tx_parity_bit;
                end
                default : begin
                    uart_txd_o <= 1'b1;
                end
            endcase
        end
    end

    //********************
    //UART Transmitter FSM
    //********************

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            tx_pstate <= idle_e;
        end else begin
            tx_pstate <= tx_nstate;
        end
    end

    always_comb begin
        unique case (tx_pstate)
            idle_e : begin
                tx_ready        = 1;
                tx_data_out_sel = 0;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 1;

                if (data_valid_i == 1'b1) begin
                    tx_nstate = txsync_e;
                end else begin
                    tx_nstate = idle_e;
                end
            end
            txsync_e : begin
                tx_ready        = 0;
                tx_data_out_sel = 0;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 0;

                if (tx_clk_en == 1'b1) begin
                    tx_nstate = startbit_e;
                end else begin
                    tx_nstate = txsync_e;
                end
            end
            startbit_e : begin
                tx_ready        = 0;
                tx_data_out_sel = 1;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 0;

                if (tx_clk_en == 1'b1) begin
                    tx_nstate = databits_e;
                end else begin
                    tx_nstate = startbit_e;
                end
            end
            databits_e : begin
                tx_ready        = 0;
                tx_data_out_sel = 2;
                tx_bit_count_en = 1;
                tx_clk_div_clr = 0;

                if (tx_clk_en == 1'b1 && tx_bit_count == 7) begin
                    if (ParityBit == "none") begin
                        tx_nstate = stopbit_e;
                    end else begin
                        tx_nstate = paritybit_e;
                    end
                end else begin
                    tx_nstate = databits_e;
                end
            end
            paritybit_e : begin
                tx_ready        = 0;
                tx_data_out_sel = 3;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 0;

                if (tx_clk_en == 1'b1) begin
                    tx_nstate = stopbit_e;
                end else begin
                    tx_nstate = paritybit_e;
                end
            end
            stopbit_e : begin
                tx_ready        = 1;
                tx_data_out_sel = 0;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 0;

                if (data_valid_i == 1'b1) begin
                    tx_nstate = txsync_e;
                end else if (tx_clk_en == 1'b1) begin
                    tx_nstate = idle_e;
                end else begin
                    tx_nstate = stopbit_e;
                end
            end
            default : begin
                tx_ready        = 0;
                tx_data_out_sel = 0;
                tx_bit_count_en = 0;
                tx_clk_div_clr  = 0;
                tx_nstate = idle_e;
            end
        endcase
    end

endmodule