module bram_contained_rv32 #(
    parameter BaseAddress = 0,
    parameter EndAddress = 0,
    parameter data_width = 8,
    parameter address_width = 8,
    parameter ram_size = 64,
    parameter pre_fill = 0,
    parameter pre_fill_start = 0,
    parameter pre_fill_file
) (
    input logic clk,
    input logic [address_width-1:0] addr,
    input logic [3:0] wr,
    input logic [data_width-1:0] din,
    output logic [data_width-1:0] dout
);

    logic [address_width-1:0] ram_addr;
    logic [3:0] ram_we;

    always_comb begin
        if (addr >= BaseAddress && addr <= EndAddress) begin
            ram_addr = addr - BaseAddress;
            ram_we = wr;
        end else begin
            ram_addr = '0;
            ram_we = '0;
        end
    end

    picosoc_mem #(
        .WORDS (ram_size/4),
        .pre_fill (pre_fill),
        .pre_fill_start (pre_fill_start),
        .pre_fill_file (pre_fill_file)
    ) psram1 (
        .clk (clk),
        .addr (ram_addr >> 2),
        .wen (ram_we),
        .wdata (din),
        .rdata (dout)
    );
    

endmodule

module picosoc_mem #(
	parameter integer WORDS = 256,
    parameter pre_fill = 0,
    parameter pre_fill_start = 0,
    parameter pre_fill_file
) (
	input clk,
	input [3:0] wen,
	input [15:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];

    initial begin
    if (pre_fill == 1) begin
        $readmemh(pre_fill_file, mem, pre_fill_start, WORDS-1);
    end
    end

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end
endmodule