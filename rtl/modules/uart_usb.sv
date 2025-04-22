module uart_usb #(
    parameter BaseAddress = 0,
    parameter Address_Wording = 1
)(
    input logic clk_i,
    input logic clk_48_i,
    input logic reset_i,
    input logic [15:0] address_i,
    input logic [7:0] data_i,
    output logic [7:0] data_o,
    input logic rd_wr_i,
    inout  pin_usb_p,
    inout  pin_usb_n
);

    localparam TransmitData     = BaseAddress + (0*Address_Wording);
    localparam SendTransmitData = BaseAddress + (1*Address_Wording);
    localparam ReadBusyState    = BaseAddress + (2*Address_Wording);
    localparam ReadFIFO         = BaseAddress + (3*Address_Wording);
    localparam ReadFIFOStatus   = BaseAddress + (4*Address_Wording);

    logic [7:0] transmit_data = '0;
    logic tx_start = 1'b0;
    logic tx_done;
    logic tx_busy;
    logic rx_done;
    logic [7:0] rx_out;
    logic [7:0] fifo_data_out;
    logic fifo_read;
    logic fifo_almost_full;
    logic fifo_empty;
    logic [7:0] data_o_reg;
    logic [7:0] transmit_data_48;
    logic fifo_empty_tran;
    logic fifo_tx_pop = 1'b0;
    logic tx_almost_full;
    logic [7:0] transmit_data_48_hold;
    logic tx_start_ready;
    logic tx_ready;


    always_ff @(posedge clk_i) begin //Data Writes
        tx_start <= 1'b0;
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b1) begin
                unique case (address_i)
                    TransmitData : begin
                        transmit_data <= data_i;
                    end
                    SendTransmitData : begin
                        tx_start <= 1'b1;
                    end
                    default : begin
                    tx_start <= 1'b0;
                    end
                endcase
            end
        end else begin
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
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b0) begin
                unique case (address_i)
                    ReadBusyState : begin
                        data_o_reg <= tx_busy;
                    end
                    ReadFIFO : begin
                        data_o_reg <= fifo_data_out;
                    end
                    ReadFIFOStatus : begin
                        data_o_reg <= fifo_empty;
                    end
                    default : begin
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
        .ASIZE       (8),
        .AWFULLSIZE  (4),
        .AREMPTYSIZE (1),
        .FALLTHROUGH ("TRUE")
    ) async_fifo_uart_recv_1 (
        .wclk    (clk_48_i),
        .wrst_n  ('1),
        .winc    (rx_done),
        .wfull   (),
        .awfull  (fifo_almost_full),
        .wdata   (rx_out),
        .rclk    (clk_i),
        .rrst_n  ('1),
        .rinc    (fifo_read),
        .rdata   (fifo_data_out),
        .rempty  (fifo_empty),
        .arempty ()
    );

    async_fifo #(
        .DSIZE       (8),
        .ASIZE       (8),
        .AWFULLSIZE  (4),
        .AREMPTYSIZE (1),
        .FALLTHROUGH ("TRUE")
    ) async_fifo_uart_tran_1 (
        .wclk    (clk_i),
        .wrst_n  ('1),
        .winc    (tx_start),
        .wfull   (),
        .awfull  (tx_almost_full),
        .wdata   (transmit_data),
        .rclk    (clk_48_i),
        .rrst_n  (!reset_i),
        .rinc    (fifo_tx_pop),
        .rdata   (transmit_data_48),
        .rempty  (fifo_empty_tran),
        .arempty ()
    );

    assign tx_busy = tx_almost_full;

    always_ff @(posedge clk_48_i) begin
        if (tx_ready == 1'b1 && tx_start_ready == 1'b1) begin
            tx_start_ready <= 1'b0;
        end else if (fifo_tx_pop == 1'b1) begin
            transmit_data_48_hold <= transmit_data_48;
            fifo_tx_pop <= 1'b0;
            tx_start_ready <= 1'b1;
        end else if (fifo_empty_tran == 1'b0 && tx_start_ready == 1'b0) begin
            fifo_tx_pop <= 1'b1;
        end else begin
            tx_start_ready <= tx_start_ready;
        end
    end 

    usb_uart usb_uart1 (
        .clk_48mhz      (clk_48_i),
        .reset          (reset_i),
        .pin_usb_p      (pin_usb_p),
        .pin_usb_n      (pin_usb_n),
        .uart_in_data   (transmit_data_48_hold),
        .uart_in_valid  (tx_start_ready),
        .uart_in_ready  (tx_ready),
        .uart_out_data  (rx_out),
        .uart_out_valid (rx_done),
        .uart_out_ready (~fifo_almost_full)
    );

    assign data_o = data_o_reg;
endmodule