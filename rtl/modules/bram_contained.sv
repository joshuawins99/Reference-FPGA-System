module bram_contained #(
    parameter BaseAddress = 0,
    parameter EndAddress = 0,
    parameter data_width = 8,
    parameter address_width = 8,
    parameter ram_size = 64,
    parameter pre_fill = 0,
    parameter pre_fill_start = 0,
    parameter pre_fill_file = ""
) (
    input logic clk,
    input logic [address_width-1:0] addr,
    input logic wr,
    input logic [data_width-1:0] din,
    output logic [data_width-1:0] dout
);

    logic [address_width-1:0] ram_addr;
    logic ram_we;

    always_comb begin
        if (addr >= BaseAddress && addr <= EndAddress) begin
            ram_addr = addr - BaseAddress;
            ram_we = wr;
        end else begin
            ram_addr = '0;
            ram_we = '0;
        end
    end

    bram_sp #(
        .address_width  (address_width),
        .data_width     (data_width),
        .ram_size       (ram_size),
        .pre_fill       (pre_fill),
        .pre_fill_start (pre_fill_start),
        .pre_fill_file  (pre_fill_file)
    ) ram1 (
        .clk          (clk),
        .addr         (ram_addr),
        .wr           (ram_we),
        .din          (din),
        .dout         (dout)
    );

endmodule