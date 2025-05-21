module uart_rx #(
    parameter ClkDivVal = 16,
    parameter ParityBit = "none"
)(
    input  logic       clk_i,
    input  logic       reset_i,
    input  logic       uart_clk_en_i,
    input  logic       uart_rxd_i,
    output logic [7:0] data_o,
    output logic       data_valid_o,
    output logic       frame_error_o,
    output logic       parity_error_o
);


    logic       rx_clk_en;
    logic [7:0] rx_data;
    logic [2:0] rx_bit_count;
    logic       rx_parity_bit;
    logic       rx_parity_error;
    logic       rx_parity_check_en;
    logic       rx_done;
    logic       fsm_idle;
    logic       fsm_databits;
    logic       fsm_stopbit;

    typedef enum logic [3:0] {idle_e, startbit_e, databits_e, paritybit_e, stopbit_e} state_t;

    state_t fsm_pstate = idle_e;
    state_t fsm_nstate;

    //*************************************************
    //UART Receiver Clock Divider and Clock Enable Flag
    //*************************************************

    uart_clk_div #(
        .DivMaxVal  (ClkDivVal),
        .DivMarkPos (3)
    ) rx_clk_divider_1 (
        .clk_i      (clk_i),
        .enable_i   (uart_clk_en_i),
        .clear_i    (fsm_idle),
        .div_mark_o (rx_clk_en)
    );

    //*************************
    //UART Receiver Bit Counter
    //*************************

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            rx_bit_count <= '0;
        end else if (rx_clk_en == 1'b1 && fsm_databits == 1'b1) begin
            if (rx_bit_count == 7) begin
                rx_bit_count <= '0;
            end else begin
                rx_bit_count <= rx_bit_count + 1'b1;
            end
        end
    end

    //*********************************
    //UART Receiver Data Shift Register
    //*********************************

    always_ff @(posedge clk_i) begin
        if (rx_clk_en == 1'b1 && fsm_databits == 1'b1) begin
            rx_data <= {uart_rxd_i, rx_data[7:1]};
        end
    end

    assign data_o = rx_data;

    //****************************************
    //UART Receiver Parity Generator and Check
    //****************************************
    generate
        if (ParityBit != "none") begin
            uart_parity #(
                .DataWidth  (8),
                .ParityType (ParityBit)
            ) uart_rx_parity_1 (
                .data_i   (rx_data),
                .parity_o (rx_parity_bit)
            );

            always_ff @(posedge clk_i) begin
                if (rx_clk_en == 1'b1) begin
                    rx_parity_error <= rx_parity_bit ^ uart_rxd_i;
                end
            end
        end else begin
            assign rx_parity_error = 0;
        end
    endgenerate

    //*****************************
    //UART Receiver Output Register
    //*****************************

    assign rx_done = rx_clk_en & fsm_stopbit;

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            data_valid_o   <= 1'b0;
            frame_error_o  <= 1'b0;
            parity_error_o <= 1'b0;
        end else begin
            data_valid_o   <= rx_done & ~rx_parity_error & uart_rxd_i;
            frame_error_o  <= rx_done & ~uart_rxd_i;
            parity_error_o <= rx_done & rx_parity_error;
        end
    end

    //*****************
    //UART Receiver FSM
    //*****************

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            fsm_pstate <= idle_e;
        end else begin
            fsm_pstate <= fsm_nstate;
        end
    end

    always_comb begin
        unique case (fsm_pstate)
            idle_e : begin
                fsm_stopbit  = 1'b0;
                fsm_databits = 1'b0;
                fsm_idle     = 1'b1;

                if (uart_rxd_i == 1'b0) begin
                    fsm_nstate = startbit_e;
                end else begin
                    fsm_nstate = idle_e;
                end
            end
            startbit_e : begin
                fsm_stopbit  = 1'b0;
                fsm_databits = 1'b0;
                fsm_idle     = 1'b0;

                if (rx_clk_en == 1'b1) begin
                    fsm_nstate = databits_e;
                end else begin
                    fsm_nstate = startbit_e;
                end
            end
            databits_e : begin
                fsm_stopbit  = 1'b0;
                fsm_databits = 1'b1;
                fsm_idle     = 1'b0;

                if (rx_clk_en == 1'b1 && rx_bit_count == 7) begin
                    if (ParityBit == "none") begin
                        fsm_nstate = stopbit_e;
                    end else begin
                        fsm_nstate = paritybit_e;
                    end
                end else begin
                    fsm_nstate = databits_e;
                end
            end
            paritybit_e : begin
                fsm_stopbit  = 1'b0;
                fsm_databits = 1'b0;
                fsm_idle     = 1'b0;

                if (rx_clk_en == 1'b1) begin
                    fsm_nstate = stopbit_e;
                end else begin
                    fsm_nstate = paritybit_e;
                end
            end
            stopbit_e : begin
                fsm_stopbit  = 1'b1;
                fsm_databits = 1'b0;
                fsm_idle     = 1'b0;

                if (rx_clk_en == 1'b1) begin
                    fsm_nstate = idle_e;
                end else begin
                    fsm_nstate = stopbit_e;
                end
            end
            default : begin
                fsm_stopbit  = 1'b0;
                fsm_databits = 1'b0;
                fsm_idle     = 1'b0;
                fsm_nstate   = idle_e;
            end
        endcase
    end

endmodule