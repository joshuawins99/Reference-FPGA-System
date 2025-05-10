module uart_debouncer #(
    parameter Latency = 4
)(
    input  logic clk_i,
    input  logic deb_i,
    output logic deb_o
);

    localparam shreg_depth = Latency-1;

    logic [shreg_depth-1:0] input_shreg;
    logic                   output_reg_rst;
    logic                   output_reg_set;

    logic or_var;
    logic and_var;

    always_ff @(posedge clk_i) begin
        input_shreg <= {input_shreg[shreg_depth-2:0], deb_i};
    end

    always_comb begin
        or_var = deb_i;
        for (int i = 0; i < shreg_depth; i++) begin
            or_var |= input_shreg[i];
        end
        output_reg_rst = ~or_var;
    end

    always_comb begin
        and_var = deb_i;
        for (int i = 0; i < shreg_depth; i++) begin
            and_var &= input_shreg[i];
        end
        output_reg_set = and_var;
    end

    always_ff @(posedge clk_i) begin
        if (output_reg_rst == 1'b1) begin
            deb_o <= 1'b0;
        end else if (output_reg_set == 1'b1) begin
            deb_o <= 1'b1;
        end
    end

endmodule