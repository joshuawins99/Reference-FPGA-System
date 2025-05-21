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
    logic [7:0] xadc_temp_reg = '0;
    logic [11:0] xadc_temp_int;
    logic convert_temp = 1'b0;

    logic [6:0] daddr = '0;
    logic busy;
    logic [15:0] xadc_data_out;
    logic xadc_data_ready;
    logic eos;

    /* Python Function for Table
    def CreateTempTable():
    intval = 0
    iterator = 0
    for i in range(2226,3030,8):
        intval = ((i*503.975)/4096)-273.15
        #print(str(iterator) + " " + str(round(intval,0)))
        print("junction_temp_map[" + str(iterator) + "] = " + str(int(round(intval,0))) + ";")
        iterator = iterator + 1 
    */

    localparam table_offset = ~2226 + 1;

    typedef enum logic [2:0] {idle_e, start_e, wait_e, update_e} state_t;

    state_t state = idle_e;

    always_ff @(posedge clk_i) begin //Data Reads
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b0) begin
                unique case (address_i)
                    Read_Temperature : begin
                        data_o[7:0] <= xadc_temp_reg;
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
                    convert_temp <= 1'b0;
                    start_read <= 1'b0;
                    if (busy == 1'b0) begin
                        state <= start_e;
                    end
                end
                start_e : begin
                    convert_temp <= 1'b0;
                    start_read <= 1'b1;
                    state <= wait_e;
                end
                wait_e : begin
                    start_read <= 1'b0;
                    if (xadc_data_ready == 1'b1) begin
                        state <= update_e;
                    end else begin
                        state <= wait_e;
                    end
                end
                update_e : begin
                    xadc_temp_int <= xadc_data_out[15:4];
                    convert_temp <= 1'b1;
                    state <= start_e;
                end
            endcase
        end else begin
            state <= idle_e;
            start_read <= 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin //Convert xadc temp output to temp in degrees C
        if (convert_temp == 1'b1) begin
            xadc_temp_reg <= (xadc_temp_int+table_offset) >> 3;
        end else begin
            xadc_temp_reg <= xadc_temp_reg;
        end
    end

    xadc_wiz_0 xadc_1 (
        .daddr_in            (daddr),
        .dclk_in             (clk_i),
        .den_in              (start_read),
        .di_in               ('0),
        .dwe_in              ('0),
        .reset_in            (reset_i),
        .busy_out            (busy),
        .channel_out         (),
        .do_out              (xadc_data_out),
        .drdy_out            (xadc_data_ready),
        .eoc_out             (),
        .eos_out             (eos),
        .alarm_out           (),
        .vp_in               (),
        .vn_in               ()
    );

endmodule