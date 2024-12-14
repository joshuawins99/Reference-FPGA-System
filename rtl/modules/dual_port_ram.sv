module bram_tdp #(
    parameter data_width = 72,
    parameter address_width = 10,
    parameter ram_size = 512,
    parameter pre_fill = 0,
    parameter pre_fill_start = 0,
    parameter pre_fill_file
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [address_width-1:0]  a_addr,
    input   wire    [data_width-1:0]  a_din,
    output  reg     [data_width-1:0]  a_dout,
     
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [address_width-1:0]  b_addr,
    input   wire    [data_width-1:0]  b_din,
    output  reg     [data_width-1:0]  b_dout
);
 
// Shared memory
reg [data_width-1:0] mem [ram_size-1:0];

initial begin
    if (pre_fill == 1) begin
        $readmemh(pre_fill_file, mem, pre_fill_start, ram_size-1);
    end
end
 
// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        a_dout      <= a_din;
        mem[a_addr] <= a_din;
    end
end
 
// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end
 
endmodule