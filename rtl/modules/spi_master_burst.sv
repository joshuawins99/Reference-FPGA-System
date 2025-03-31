module spi_master_burst #(
    parameter BaseAddress = 0,
    parameter BytesPerTransaction = 1,
    parameter MaxADCBurstReadings = 2, //(2^x)/ 2 Readings
    parameter FPGAClkSpeed = 50000000, //In Hz
    parameter SPIClkSpeed = 1000, //In Hz
    parameter address_width = 16,
    parameter data_width = 8

)(
    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    input  logic [data_width-1:0]    data_i,
    output logic [data_width-1:0]    data_o,
    input  logic                     rd_wr_i,
    output logic                     spi_clk_o,
    input  logic                     spi_miso_i,
    output logic                     spi_mosi_o,
    output logic                     spi_sync_no
);

    localparam Write_Byte        = BaseAddress + 0;
    localparam Read_Byte         = BaseAddress + 1;
    localparam Start_Transaction = BaseAddress + 2;
    localparam Busy_Status       = BaseAddress + 3;
    localparam Num_Transactions  = BaseAddress + 4;

    localparam SPIClkDivider = (FPGAClkSpeed/(2*SPIClkSpeed))-1;

    logic [(8*BytesPerTransaction)-1:0] tx_data = '0;
    logic [(8*BytesPerTransaction)-1:0] tx_data_copy = '0;
    logic [(8*BytesPerTransaction)-1:0] rx_data = '0;
    logic [$clog2(SPIClkDivider):0] slow_counter = '0;
    logic [7:0] bit_counter = '0;
    logic busy = 1'b0;
    logic start_transaction = 1'b0;
    logic start_transaction_int = 1'b0;
    logic rx_done = 1'b0;
    logic winc = 1'b0;
    logic [7:0] data_to_fifo = '0;
    logic fifo_read;
    logic [7:0] fifo_count = '0;
    logic [7:0] fifo_data_out;
    logic [15:0] transaction_count = '0;
    logic [15:0] transaction_count_wr = '0;

    initial begin
        if (SPIClkDivider < 1) begin
            $error ("System Clock not fast enough for requested SPI Clock!");
        end
    end

    typedef enum logic [3:0] {idle_e, initial_delay_e, shift_e, sample_e, fifo_e} state_t;

    state_t state = idle_e;

    always_comb begin
        if (rd_wr_i == 1'b0) begin
            if (address_i == Read_Byte) begin
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
                    Read_Byte : begin
                        data_o <= fifo_data_out;
                    end
                    Busy_Status : begin
                        data_o <= busy;
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
        start_transaction <= 1'b0;
        if (reset_i == 1'b0) begin
            if (rx_done == 1'b1) begin
                tx_data <= '0;
            end
            if (rd_wr_i == 1'b1) begin
                unique case (address_i)
                    Write_Byte : begin
                        if (BytesPerTransaction > 1) begin
                            tx_data <= {tx_data[($size(tx_data)-1)-8:0], data_i[7:0]};
                        end else begin
                            tx_data <= data_i[7:0];
                        end
                    end
                    Start_Transaction : begin
                        start_transaction <= data_i[0];
                    end
                    Num_Transactions : begin
                        transaction_count_wr <= {transaction_count_wr[($size(transaction_count_wr)-1)-8:0], data_i[7:0]};
                    end
                    default : begin
                        transaction_count_wr <= transaction_count_wr;
                        tx_data <= tx_data;
                    end
                endcase
            end
        end else begin
            tx_data <= '0;
            transaction_count_wr <= 'd1;
        end
    end

        always_ff @(posedge clk_i) begin //SPI State Machine
        if (reset_i == 1'b0) begin
            unique case (state)
                idle_e : begin
                    winc <= 1'b0;
                    spi_clk_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    busy <= 1'b0;
                    rx_done <= 1'b0;
                    rx_data <= '0;
                    spi_sync_no <= 1'b1;
                    bit_counter <= '0;
                    slow_counter <= '0;
                    tx_data_copy <= tx_data;
                    if (start_transaction == 1'b1 || start_transaction_int == 1'b1) begin
                        if (start_transaction == 1'b1) begin
                            transaction_count <= (transaction_count_wr - 1'b1); 
                        end
                        start_transaction_int <= 1'b0;
                        spi_sync_no <= 1'b0;
                        busy <= 1'b1;
                        spi_mosi_o <= tx_data_copy[$size(tx_data_copy)-1];
                        state <= initial_delay_e;
                    end
                end
                initial_delay_e : begin
                    if (slow_counter >= SPIClkDivider) begin
                        slow_counter <= '0;
                        state <= shift_e;
                    end else begin
                        slow_counter <= slow_counter + 1'b1;
                    end
                end
                shift_e : begin
                    spi_clk_o <= 1'b1;
                    if (slow_counter >= SPIClkDivider) begin
                        slow_counter <= '0;
                        spi_clk_o <= 1'b0;
                        bit_counter <= bit_counter + 1'b1;
                        state <= sample_e;
                    end else begin
                        slow_counter <= slow_counter + 1'b1;
                    end
                end
                sample_e : begin
                    if (bit_counter >= BytesPerTransaction*8) begin
                        rx_done <= 1'b1;
                        fifo_count <= BytesPerTransaction;
                        state <= fifo_e;
                    end else begin
                        if (slow_counter >= SPIClkDivider) begin
                            slow_counter <= '0;
                            spi_mosi_o <= tx_data_copy[$size(tx_data_copy)-1];
                            rx_data <= rx_data << 1;
                            rx_data[0] <= spi_miso_i;
                            state <= shift_e;
                        end else if (slow_counter == 0) begin
                            tx_data_copy <= tx_data_copy << 1;
                            slow_counter <= slow_counter + 1'b1;
                        end else begin
                            slow_counter <= slow_counter + 1'b1;
                        end
                    end
                end
                fifo_e : begin
                    winc <= 1'b0;
                    if (fifo_count > 0) begin
                        winc <= 1'b1;
                        data_to_fifo <= rx_data[$size(rx_data)-1 -: 8];
                        rx_data <= rx_data << 8;
                        fifo_count <= fifo_count - 1'b1;
                    end else begin
                        if (transaction_count > 0) begin
                            transaction_count <= transaction_count - 1'b1;
                            start_transaction_int <= 1'b1;
                        end
                        spi_sync_no <= 1'b1;
                        state <= idle_e;
                    end
                end
            endcase
        end else begin
            state <= idle_e;
        end
    end

    async_fifo #(
        .DSIZE       (8),
        .ASIZE       (MaxADCBurstReadings),
        .AWFULLSIZE  (1),
        .AREMPTYSIZE (1),
        .FALLTHROUGH ("TRUE")
    ) async_fifo_spi_6502_1 (
        .wclk    (clk_i),
        .wrst_n  ('1),
        .winc    (winc),
        .wfull   (),
        .awfull  (),
        .wdata   (data_to_fifo),
        .rclk    (clk_i),
        .rrst_n  ('1),
        .rinc    (fifo_read),
        .rdata   (fifo_data_out),
        .rempty  (),
        .arempty ()
    );

endmodule