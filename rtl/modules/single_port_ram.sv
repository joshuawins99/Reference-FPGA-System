module bram_sp #(
    parameter data_width = 72,
    parameter address_width = 10,
    parameter ram_size = 512,
    parameter pre_fill = 0,
    parameter pre_fill_start = 0,
    parameter pre_fill_file
) (
    input   wire                clk,
    input   wire                wr,
    input   wire    [address_width-1:0]  addr,
    input   wire    [data_width-1:0]  din,
    output  reg     [data_width-1:0]  dout
);
 
// Shared memory
reg [data_width-1:0] mem [ram_size-1:0];

initial begin
    if (pre_fill == 1) begin
        $readmemh(pre_fill_file, mem, pre_fill_start, ram_size-1);
    end
end
 
always @(posedge clk) begin
    dout      <= mem[addr];
    if(wr) begin
        dout      <= din;
        mem[addr] <= din;
    end
end

endmodule