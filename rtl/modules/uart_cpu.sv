module uart_cpu #(
    parameter BaseAddress     = 0,
    parameter FPGAClkSpeed    = 0,
    parameter UARTBaudRate    = 0,
    parameter Address_Wording = 1
)(
    input logic clk_i,
    input logic reset_i,
    input logic [15:0] address_i,
    input logic [7:0] data_i,
    output logic [7:0] data_o,
    input logic rd_wr_i,
    output logic take_controlr_o,
    output logic take_controlw_o,
    output logic uart_tx_o,
    input logic uart_rx_i
);

    localparam TransmitData     = BaseAddress + (0*Address_Wording);
    localparam SendTransmitData = BaseAddress + (1*Address_Wording);
    localparam ReadBusyState    = BaseAddress + (2*Address_Wording);
    localparam ReadFIFO         = BaseAddress + (3*Address_Wording);
    localparam ReadFIFOStatus   = BaseAddress + (4*Address_Wording);

    logic [7:0] transmit_data = '0;
    logic tx_start = 1'b0;
    logic tx_start_reg = 1'b0;
    logic tx_done;
    logic tx_busy;
    logic rx_done;
    logic [7:0] rx_out;
    logic [7:0] fifo_data_out;
    logic fifo_read;
    logic fifo_almost_full;
    logic fifo_empty;
    logic [7:0] data_o_reg;

    always_ff @(posedge clk_i) begin //Data Writes
        take_controlw_o <= 1'b0;
        tx_start <= 1'b0;
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b1) begin
                unique case (address_i)
                    TransmitData : begin
                        take_controlw_o <= 1'b1;
                        transmit_data <= data_i;
                    end
                    SendTransmitData : begin
                        take_controlw_o <= 1'b1;
                        tx_start <= 1'b1;
                    end
                    default : begin
                    take_controlw_o <= 1'b0;
                    tx_start <= 1'b0;
                    end
                endcase
            end
        end else begin
            take_controlw_o <= 1'b0;
            tx_start <= 1'b0;
        end
    end

    always_comb begin
        if (rd_wr_i == 1'b0) begin
            if (address_i == ReadFIFO) begin
                fifo_read = 1'b1;
            end else begin
                fifo_read = 1'b0;
            end
        end else begin
            fifo_read = 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin //Data Reads
        take_controlr_o <= 1'b0;
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b0) begin
                unique case (address_i)
                    ReadBusyState : begin
                        take_controlr_o <= 1'b1;
                        data_o_reg <= !tx_busy;
                    end
                    ReadFIFO : begin
                        take_controlr_o <= 1'b1;
                        data_o_reg <= fifo_data_out;
                    end
                    ReadFIFOStatus : begin
                        take_controlr_o <= 1'b1;
                        data_o_reg <= fifo_empty;
                    end
                    default : begin
                        take_controlr_o <= 1'b0;
                        data_o_reg <= '0;
                    end
                endcase
            end
        end else begin
            data_o_reg <= '0;
        end
    end

    async_fifo #(
        .DSIZE       (8),
        .ASIZE       (9),
        .AWFULLSIZE  (1),
        .AREMPTYSIZE (1),
        .FALLTHROUGH ("TRUE")
    ) async_fifo_uart_6502_1 (
        .wclk   (clk_i),
        .wrst_n ('1),
        .winc   (rx_done),
        .wfull  (),
        .awfull (fifo_almost_full),
        .wdata  (rx_out),
        .rclk   (clk_i),
        .rrst_n ('1),
        .rinc   (fifo_read),
        .rdata  (fifo_data_out),
        .rempty (fifo_empty),
        .arempty ()
    );

    uart #(
        .ClkFreq         (FPGAClkSpeed),
        .BaudRate        (UARTBaudRate),
        .ParityBit       ("none"),
        .UseDebouncer    (1),
        .OversampleRate  (16)
    ) uart_1 (
        .clk_i           (clk_i),
        .reset_i         ('0),
        .uart_txd_o      (uart_tx_o),
        .uart_rxd_i      (uart_rx_i),
        .data_o          (rx_out),
        .data_valid_o    (rx_done),
        .data_i          (transmit_data),
        .data_valid_i    (tx_start),
        .data_in_ready_o (tx_busy)
    );

    assign data_o = data_o_reg;
endmodule