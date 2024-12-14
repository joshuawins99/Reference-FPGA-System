module led_control #(
    parameter BaseAddress = 0,
    parameter address_width = 15,
    parameter data_width = 16
)(

    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    output logic [data_width-1:0]    data_o,
    input  logic [data_width-1:0]    data_i,
    input  logic                     rd_wr_i,
    output logic                     led_o
);

    localparam LED_Control = BaseAddress + 0;

    logic [data_width-1:0] led_reg = '0;

    logic [data_width-1:0] data;

    always_ff @(posedge clk_i) begin
        if (rd_wr_i == 1'b1) begin
            unique case (address_i)
                LED_Control : begin
                    led_reg <= data_i;
                end
                default : begin
                    led_reg <= led_reg;
                end
            endcase 
        end
    end
    
    always_comb begin
        if (rd_wr_i == 1'b0) begin
            unique case (address_i)
                LED_Control : begin
                    data = led_reg;
                end
                default : begin
                    data = '0;
                end
            endcase 
        end else begin
            data = '0;
        end
    end


    assign led_o = led_reg[0];
    assign data_o = data;


endmodule