`include "../version_string.svh"
module version_string #(
    parameter BaseAddress = 0,
    parameter NumCharacters = 44,
    parameter CharsPerTransaction = 1,
    parameter address_width = 15,
    parameter data_width = 16
)(

    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    output logic [data_width-1:0]    data_o,
    input  logic [data_width-1:0]    data_i,
    input  logic                     rd_wr_i
);

    localparam Version_String = BaseAddress + 0;

    logic [NumCharacters*8-1:0] date = `version_string;

    function [data_width-1:0] get_characters (
        input logic [$clog2(NumCharacters/CharsPerTransaction):0] val
    );
        begin
            get_characters = date[data_width*val +: data_width];
        end
    endfunction

    logic [data_width-1:0] data;

    always_comb begin
        data = '0;
        if (rd_wr_i == 1'b0) begin
            if (address_i >= Version_String && address_i <= Version_String+(NumCharacters/CharsPerTransaction)) begin
                data = get_characters(address_i-Version_String);
            end
        end
    end


    assign data_o = data;

endmodule
