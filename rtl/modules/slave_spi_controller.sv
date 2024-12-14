module slave_spi_controller #(
    parameter address_width = 15,
    parameter data_width = 16
    )(

    input  logic clk_i,
    input  logic reset_i,
    input  logic spi_clk_i,
    output logic spi_miso_o,
    input  logic spi_mosi_i,

    output logic [address_width-1:0] address_o,
    output logic [data_width-1:0] data_o,
    input  logic [data_width-1:0] data_i,
    output logic                 rd_wr_o

);
    localparam crc8 = 8;


    logic [address_width-1:0]   address;
    logic [data_width-1:0]      data;
    logic [address_width-1:0]   address_spi;
    logic [data_width-1+crc8:0] data_spi;
    logic                       rd_wr;
    logic                       rd_wr_spi;
    logic                       tx_start;
    logic                       reset;
    logic                       reset_int;
    logic [7:0]                 reset_counter = '0;
    logic                       pulse_tx;
    logic                       data_valid;
    logic                       address_valid;

    logic [data_width+crc8-1:0] tx_packet;

    typedef enum logic [3:0] {idle_e, wait_cycle_e, populate_e} state_t;

    state_t state = idle_e;

    function [crc8-1:0] crc (
        input [7:0] crcIn,
        input [15:0] data
    );  
        begin
            crc[0] = crcIn[0] ^ crcIn[4] ^ crcIn[6] ^ data[0] ^ data[6] ^ data[7] ^ data[8] ^ data[12] ^ data[14];
            crc[1] = crcIn[1] ^ crcIn[4] ^ crcIn[5] ^ crcIn[6] ^ crcIn[7] ^ data[0] ^ data[1] ^ data[6] ^ data[9] ^ data[12] ^ data[13] ^ data[14] ^ data[15];
            crc[2] = crcIn[0] ^ crcIn[2] ^ crcIn[4] ^ crcIn[5] ^ crcIn[7] ^ data[0] ^ data[1] ^ data[2] ^ data[6] ^ data[8] ^ data[10] ^ data[12] ^ data[13] ^ data[15];
            crc[3] = crcIn[1] ^ crcIn[3] ^ crcIn[5] ^ crcIn[6] ^ data[1] ^ data[2] ^ data[3] ^ data[7] ^ data[9] ^ data[11] ^ data[13] ^ data[14];
            crc[4] = crcIn[0] ^ crcIn[2] ^ crcIn[4] ^ crcIn[6] ^ crcIn[7] ^ data[2] ^ data[3] ^ data[4] ^ data[8] ^ data[10] ^ data[12] ^ data[14] ^ data[15];
            crc[5] = crcIn[1] ^ crcIn[3] ^ crcIn[5] ^ crcIn[7] ^ data[3] ^ data[4] ^ data[5] ^ data[9] ^ data[11] ^ data[13] ^ data[15];
            crc[6] = crcIn[2] ^ crcIn[4] ^ crcIn[6] ^ data[4] ^ data[5] ^ data[6] ^ data[10] ^ data[12] ^ data[14];
            crc[7] = crcIn[3] ^ crcIn[5] ^ crcIn[7] ^ data[5] ^ data[6] ^ data[7] ^ data[11] ^ data[13] ^ data[15];
        end
    endfunction

    //always_ff @(posedge clk_i) begin
    assign    tx_packet = {data_i,crc('h9c,data_i)};
    //end

    always_ff @(posedge clk_i) begin
        if (reset_counter >= 10) begin
            reset <= 1'b1;
        end else begin
            reset <= 1'b0;
            reset_counter <= reset_counter + 1'b1;
        end
    end

    always_ff @(posedge clk_i) begin //Pulse outputs and reset
        unique case (state)
            idle_e : begin
                reset_int  <= '1;
                address    <= '0;
                data       <= '0;
                rd_wr      <= '0;
                if (data_valid == 1'b1) begin
                    state <= populate_e;
                end else if (address_valid == 1'b1 && rd_wr_spi == 1'b0) begin
                    address <= address_spi;
                    state <= wait_cycle_e;
                end else begin
                    state <= idle_e;
                end
            end
            wait_cycle_e : begin //Special Case for transmission. Need to refactor spi module
                state <= idle_e;
            end
            populate_e : begin
                address   <= address_spi;
                data      <= data_spi[data_width-1:0];
                rd_wr     <= rd_wr_spi;
                state     <= idle_e;
                reset_int <= '0;
            end
        endcase
    end

    always_ff @(posedge clk_i) begin //Create a start_tx pulse for transmitting info back to master
        if (address_valid == 1'b1 && rd_wr_spi == 1'b0 && pulse_tx == 1'b0) begin
            pulse_tx <= 1'b1;
            tx_start <= 1'b1;
        end else begin
            tx_start <= 1'b0;
            pulse_tx <= 1'b0;
        end
    end

    spi_slave #(
        .pktsz   (data_width+address_width+crc8+1),
        .payload (data_width+crc8),
        .addrsz  (address_width),
        .header  (address_width+1) //??? On its actual function. Investigate in the future. Will refactor module in the future.
    ) spi1 (
        //Control Signals
        .reset_i (reset & reset_int),
        .clk       (clk_i),
        .rxdv      (data_valid),
        .rx_d      (data_spi),
        .tx_d      (tx_packet),
        .tx_en     (tx_start),
        .rw_out    (rd_wr_spi),
        .addr_dv   (address_valid),
        .reg_addr  (address_spi),
        
        //SPI Interface
        .SCLK     (spi_clk_i),
        .MISO     (spi_miso_o),
        .MOSI     (spi_mosi_i),
        .SSB      ('0)
    );

    assign rd_wr_o   = rd_wr;
    assign address_o = address;
    assign data_o    = data;

endmodule