module artix7_xadc #( //Artix 7 XADC Temp Monitor
    parameter BaseAddress = 0,
    parameter address_width = 16,
    parameter data_width = 8
)(
    input logic clk_i,
    input logic reset_i,
    input logic [address_width-1:0] address_i,
    input logic [data_width-1:0] data_i,
    output logic [data_width-1:0] data_o,
    input logic rd_wr_i
);

    localparam Read_Temperature = BaseAddress + 0;

    logic start_read = 1'b0;
    logic [7:0] dtr_temp_reg = '0;
    logic [7:0] dtr_temp_out;
    logic [7:0] dtr_temp_int;
    logic convert_temp = 1'b0;

    logic signed [7:0] junction_temp_map [64];

    initial begin
        junction_temp_map[0]  = -58;
        junction_temp_map[1]  = -56;
        junction_temp_map[2]  = -54;
        junction_temp_map[3]  = -52;
        junction_temp_map[4]  = -45;
        junction_temp_map[5]  = -44;
        junction_temp_map[6]  = -43;
        junction_temp_map[7]  = -42;
        junction_temp_map[8]  = -41;
        junction_temp_map[9]  = -40;
        junction_temp_map[10] = -39;
        junction_temp_map[11] = -38;
        junction_temp_map[12] = -37;
        junction_temp_map[13] = -36;
        junction_temp_map[14] = -30;
        junction_temp_map[15] = -20;
        junction_temp_map[16] = -10;
        junction_temp_map[17] = -4;
        junction_temp_map[18] = 0;
        junction_temp_map[19] = 4;
        junction_temp_map[20] = 10;
        junction_temp_map[21] = 21;
        junction_temp_map[22] = 22;
        junction_temp_map[23] = 23;
        junction_temp_map[24] = 24;
        junction_temp_map[25] = 25;
        junction_temp_map[26] = 26;
        junction_temp_map[27] = 27;
        junction_temp_map[28] = 28;
        junction_temp_map[29] = 29;
        junction_temp_map[30] = 40;
        junction_temp_map[31] = 50;
        junction_temp_map[32] = 60;
        junction_temp_map[33] = 70;
        junction_temp_map[34] = 76;
        junction_temp_map[35] = 80;
        junction_temp_map[36] = 81;
        junction_temp_map[37] = 82;
        junction_temp_map[38] = 83;
        junction_temp_map[39] = 84;
        junction_temp_map[40] = 85;
        junction_temp_map[41] = 86;
        junction_temp_map[42] = 87;
        junction_temp_map[43] = 88;
        junction_temp_map[44] = 89;
        junction_temp_map[45] = 95;
        junction_temp_map[46] = 96;
        junction_temp_map[47] = 97;
        junction_temp_map[48] = 98;
        junction_temp_map[49] = 99;
        junction_temp_map[50] = 100;
        junction_temp_map[51] = 101;
        junction_temp_map[52] = 102;
        junction_temp_map[53] = 103;
        junction_temp_map[54] = 104;
        junction_temp_map[55] = 105;
        junction_temp_map[56] = 106;
        junction_temp_map[57] = 107;
        junction_temp_map[58] = 108;
        junction_temp_map[59] = 116;
        junction_temp_map[60] = 120;
        junction_temp_map[61] = 124;
        junction_temp_map[62] = 128;
        junction_temp_map[63] = 132;
    end

    typedef enum logic [2:0] {idle_e, start_e, wait_e} state_t;

    state_t state = idle_e;

    always_ff @(posedge clk_i) begin //Data Reads
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b0) begin
                unique case (address_i)
                    Read_Temperature : begin
                        data_o <= dtr_temp_reg;
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

    always_ff @(posedge clk_i) begin //Continuously get updated temp
        if (reset_i == 1'b0) begin
            unique case (state)
                idle_e : begin
                    convert_temp = 1'b0;
                    start_read <= 1'b0;
                    state <= start_e;
                end
                start_e : begin
                    start_read <= 1'b1;
                    state <= wait_e;
                end
                wait_e : begin
                    start_read <= 1'b0;
                    if (dtr_temp_out[7] == 1'b1) begin
                        dtr_temp_int <= dtr_temp_out[5:0];
                        convert_temp = 1'b1;
                        state <= idle_e;
                    end else begin
                        state <= wait_e;
                    end
                end
            endcase
        end else begin
            state <= idle_e;
        end
    end

    always_ff @(posedge clk_i) begin //Convert dtr output to temp in degrees C
        if (convert_temp == 1'b1) begin
            dtr_temp_reg <= junction_temp_map[dtr_temp_int];
        end else begin
            dtr_temp_reg <= dtr_temp_reg;
        end
    end

    xadc_wiz_0 xadc_1 (
        .daddr_in            (daddr),
        .dclk_in             (clk_i),
        .den_in              (den),
        .di_in               ('0),
        .dwe_in              ('0),
        .reset_in            (reset_i),
        .busy_out            (busy),
        .channel_out         (),
        .do_out              (xadc_data_out),
        .drdy_out            (xadc_data_ready),
        .eoc_out             (),
        .eos_out             (eos),
        .vccaux_alarm_out    (),
        .vccint_alarm_out    (),
        .user_temp_alarm_out (),
        .alarm_out           (),
        .vp_in               (),
        .vn_in               ()
    );

endmodule