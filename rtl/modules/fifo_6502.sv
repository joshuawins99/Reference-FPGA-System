module fifo_6502 #(
    parameter BaseAddress   = 0,
    parameter FIFOSize      = 2,
    parameter address_width = 16,
    parameter data_width    = 8
)(
    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    input  logic [data_width-1:0]    data_i,
    output logic [data_width-1:0]    data_o,
    input  logic                     rd_wr_i
);

    localparam PushData     = BaseAddress + 0;
    localparam PopData      = BaseAddress + 1;
    localparam FIFOStatus   = BaseAddress + 2;

    logic [data_width-1:0] data_to_fifo;
    logic [data_width-1:0] fifo_data_out;
    logic fifo_read;
    logic fifo_empty;
    logic winc;

    always_comb begin
        if (rd_wr_i == 1'b0) begin
            if (address_i == PopData) begin
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
                    PopData : begin
                        data_o <= fifo_data_out;
                    end
                    FIFOStatus : begin
                        data_o <= fifo_empty;
                    end
                    default : begin
                        data_o <= '0;
                    end
                endcase
            end
        end else begin
            data_o <= '0;
        end
    end

    always_ff @(posedge clk_i) begin //Data Writes
        if (reset_i == 1'b0) begin
            winc <= 1'b0;
            if (rd_wr_i == 1'b1) begin
                unique case (address_i)
                    PushData : begin
                        data_to_fifo <= data_i;
                        winc <= 1'b1;
                    end
                    default : begin
                        winc <= 1'b0;
                        data_to_fifo <= '0;
                    end
                endcase
            end
        end else begin
            data_to_fifo <= '0;
            winc <= '0;
        end
    end

    async_fifo #(
        .DSIZE       (data_width),
        .ASIZE       (FIFOSize),
        .AWFULLSIZE  (1),
        .AREMPTYSIZE (1),
        .FALLTHROUGH ("TRUE")
    ) async_fifo_6502_1 (
        .wclk   (clk_i),
        .wrst_n ('1),
        .winc   (winc),
        .wfull  (),
        .awfull (),
        .wdata  (data_to_fifo),
        .rclk   (clk_i),
        .rrst_n ('1),
        .rinc   (fifo_read),
        .rdata  (fifo_data_out),
        .rempty (fifo_empty),
        .arempty ()
    );

endmodule