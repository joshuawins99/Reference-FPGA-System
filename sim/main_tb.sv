`timescale 1ns / 1ns
module main_tb;

    localparam clk_per       = 19;
    localparam spi_clk_per   = 100;
    localparam address_width = 15;
    localparam data_width    = 16;
    localparam crc8          = 8;

    logic clk = 1'b0;
    logic spi_clk = 1'b0;
    logic spi_clk_gen = 1'b0;

    logic reset = 1'b0;
    logic spi_miso;
    logic spi_mosi;
    logic led;

    always begin
        #(clk_per/2);
        clk = ~clk;
    end
    
    always begin
        #(spi_clk_per/2);
        spi_clk = ~spi_clk;
    end

    main #(
        .address_width (address_width),
        .data_width    (data_width)
    ) m1 (
        .clk_i         (clk),
        .spi_clk_i     (spi_clk_gen),
        .led_o         (led),
        .k_line_tx_o   (),
        .k_line_rx_i   (),
        .spi_miso_o    (spi_miso),
        .spi_mosi_i    (spi_mosi),
        .reset_i       (reset)
    );

    integer total_bit_count = 0;
    integer bit_count = 0;
    integer error_count = 0;
    integer random_data = 0;

    logic [address_width+data_width+crc8:0] total_packet;
    logic [address_width+data_width+crc8:0] data_received;
    logic send_done = 1'b0;
    logic read_write = 1'b0;
    logic [7:0] random_data_crc = '0;
    logic testing_cpu = 1'b0;

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

    task track_errors;
        input string disp;
        begin
            error_count = error_count + 1;
            $display("Error: ", disp);
        end
    endtask

    task Send_SPI;
        input logic rw;
        input logic [address_width-1:0] address;
        input logic [data_width-1:0]    data;
        begin
            total_bit_count = 0;
            total_packet = {rw, address, 8'd0, data};
            read_write   = rw;
            while (total_bit_count < data_width+address_width+1+crc8) begin
                @(posedge spi_clk);
                spi_clk_gen = 1'b1;
                spi_mosi = total_packet[$left(total_packet)];
                total_packet = total_packet << 1;
                total_bit_count = total_bit_count + 1;
                bit_count = bit_count + 1;
                @(negedge spi_clk);
                spi_clk_gen = 1'b0;
                spi_mosi = '0;
                if (total_bit_count % 8 == 1'b0 && total_bit_count > 1) begin
                    @(posedge spi_clk);
                    @(posedge spi_clk);
                    @(posedge spi_clk);    
                end
            end
            send_done = 1'b1;
            spi_mosi = 0;
            @(posedge spi_clk);
            @(posedge spi_clk);
            send_done = 1'b0;
            if (random_data != m1.led1.led_reg && rw == 1'b1 && testing_cpu == 1'b0) begin
                track_errors("Send SPI Failed!");
            end
        end
    endtask

    task Test_CPU;
    input logic [7:0] data_in;
        begin
            Send_SPI(1,m1.s6502_1.BaseAddress, 1);
            Send_SPI(1,m1.s6502_1.BaseAddress+'d2+'d2047, '0); //Initialize Low Byte Address to 0
            Send_SPI(1,m1.s6502_1.BaseAddress+'d2+'d2046, '0); //Initialize High Byte Address to 0

            Send_SPI(1,m1.s6502_1.BaseAddress+21, data_in);
            Send_SPI(1,m1.s6502_1.BaseAddress+2, 'hea);
            Send_SPI(1,m1.s6502_1.BaseAddress+3, 'hea);
            Send_SPI(1,m1.s6502_1.BaseAddress+4, 'hAD);
            Send_SPI(1,m1.s6502_1.BaseAddress+5, 'h13);
            Send_SPI(1,m1.s6502_1.BaseAddress+6, 'h00);
            Send_SPI(1,m1.s6502_1.BaseAddress+7, 'h8D);
            Send_SPI(1,m1.s6502_1.BaseAddress+8, 'h2A);
            Send_SPI(1,m1.s6502_1.BaseAddress+9, 'h00);
            Send_SPI(1,m1.s6502_1.BaseAddress+10, 'h4c);
            Send_SPI(1,m1.s6502_1.BaseAddress+11, '0);
            Send_SPI(1,m1.s6502_1.BaseAddress+12, '0);

            Send_SPI(1,m1.s6502_1.BaseAddress, 0);

            #100;
            Send_SPI(1, m1.s6502_1.BaseAddress+1, 1);
            Send_SPI(0, m1.s6502_1.BaseAddress+2+'h2a, 0);
            Send_SPI(1, m1.s6502_1.BaseAddress+1, 0);
            #2000;

            reset = 1'b1;
            repeat(10) begin
                @(posedge clk);
            end
            reset = 1'b0;
        end
    endtask

    task Test_CPU_C_Compile;
        begin
            Send_SPI(1,m1.s6502_1.BaseAddress, 1);
            //`include "test_cpu_prog.txt";
            Send_SPI(1,m1.s6502_1.BaseAddress, 0);

            //#800000;
            //Send_SPI(1, m1.s6502_1.BaseAddress+1, 1);
            //Send_SPI(0, m1.s6502_1.BaseAddress+2+'h2a, 0);
            //Send_SPI(1, m1.s6502_1.BaseAddress+1, 0);
            //#2000;

            // reset = 1'b1;
            // repeat(10) begin
            //     @(posedge clk);
            // end
            // reset = 1'b0;
        end
    endtask


    always @(posedge spi_clk_gen or posedge reset) begin
        if (reset == 1'b0) begin
            if (read_write == 1'b0) begin
                if (send_done == 1'b0) begin
                    data_received = {data_received,spi_miso};
                end
            end
        end else begin
            data_received = '0;
        end
    end

    always @(posedge send_done or posedge reset) begin
        if (reset == 1'b0 && testing_cpu == 1'b0) begin
            if (read_write == 1'b0) begin
                random_data_crc = crc('h9c,random_data);
                if (data_received != {random_data,random_data_crc}) begin
                    track_errors("Receive SPI Failed!");
                    $display("LED Data:      %b", m1.led1.led_reg);
                    $display("Random Data:   %b", {random_data,random_data_crc});
                    $display("Received Data: %b", data_received);
                end
            end
        end else begin
            random_data_crc = 0;
        end

    end

    initial begin
        reset = 1'b1;
        repeat(10) begin
            @(posedge clk);
        end
        reset = 1'b0;
        repeat(10) begin
            random_data = $urandom_range(1,(2**data_width)-1);
            #10;
            Send_SPI(1,m1.led1.BaseAddress, random_data);
            repeat(50) begin
                @(posedge clk);
            end
            Send_SPI(0,m1.led1.BaseAddress, 0);
        end
        #50;
        testing_cpu = 1'b1;
        // repeat(10) begin
        //     random_data = $urandom_range(1,127);
        //     Test_CPU(random_data);
        // end
 //       #30000;
 //       Test_CPU_C_Compile();

        if (error_count >= 1) begin
            $display("There were %0d errors!", error_count);
        end else begin
            $display("Testbench Passed!");
        end
        $finish();
    end

endmodule
