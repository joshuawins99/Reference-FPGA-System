module uart_clk_div #(
    parameter DivMaxVal  = 16,
    parameter DivMarkPos = 1
)(
    input  logic clk_i,
    input  logic clear_i,
    input  logic enable_i,
    output logic div_mark_o
);

    localparam clk_div_width = integer'(($clog2(DivMaxVal)+1));

    logic [clk_div_width-1:0] clk_div_cnt = '0;
    logic clk_div_cnt_mark;

    always_ff @(posedge clk_i) begin
        if (clear_i == 1'b1) begin
            clk_div_cnt <= '0;
        end else if (enable_i == 1'b1) begin
            if (clk_div_cnt == DivMaxVal-1) begin
                clk_div_cnt <= '0;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end
        end
    end

    always_comb begin
        if (clk_div_cnt == DivMarkPos) begin
            clk_div_cnt_mark = 1'b1;
        end else begin
            clk_div_cnt_mark = 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin
        div_mark_o <= enable_i & clk_div_cnt_mark;
    end

endmodule