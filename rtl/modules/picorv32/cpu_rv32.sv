module cpu_rv32 #(
    parameter ProgramStartAddress = 0,
    parameter StackAddress        = 0,
    parameter address_width       = 32
)(
    input logic                      clk_i,
    input logic                      reset_i,
    output logic [address_width-1:0] address_o,
    input  logic [31:0]              data_i,
    output logic [31:0]              data_o,
    output logic                     we_o,
    output logic [3:0]               we_ram_o

);

    logic mem_valid;
    logic mem_ready;
    logic [3:0] mem_wstrb;
    logic [31:0] address;
    logic resetn;
    logic we_pulse;
    logic we_int;
    logic new_addr_strb;
    logic mem_valid_delayed;

    assign resetn = !reset_i;

    always_ff @(posedge clk_i) begin
        if (mem_valid == 1'b1) begin
            mem_ready <= 1'b1;
        end else begin
            mem_ready <= 1'b0;
        end
    end 

    picorv32 #(
        .PROGADDR_RESET       (ProgramStartAddress),
        .PROGADDR_IRQ         (32'h0000_0000),
        .STACKADDR            (StackAddress),
        .COMPRESSED_ISA       (0),
        .ENABLE_IRQ_QREGS     (0),
        .ENABLE_IRQ           (0),
        .REGS_INIT_ZERO       (1),
        .TWO_STAGE_SHIFT      (1), //Set to 0 for space savings
        .ENABLE_REGS_DUALPORT (1) //Set to 0 for space savings
    ) rv32_1 (
        .clk       (clk_i),
        .resetn    (resetn),
        .mem_addr  (address),
        .mem_wdata (data_o),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (data_i), 
        .mem_valid (mem_valid),
        .mem_instr (),
        .mem_ready (mem_ready),
        .irq       ('0)
    );

    always_comb begin
        if (mem_wstrb != 0) begin
            we_int = 1'b1;
        end else begin
            we_int = 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (we_int == 1'b1) begin
            we_pulse <= 1'b0;
        end else we_pulse <= 1'b1;
    end

    always_ff @(posedge clk_i) begin
        mem_valid_delayed <= mem_valid;
    end

    always_comb begin
        new_addr_strb = mem_valid & !mem_valid_delayed;
    end

    always_comb begin
        if (new_addr_strb == 1) begin
            address_o = address;
        end else begin
            address_o = '0;
        end
    end

    assign we_o = (we_int & we_pulse);   
    assign we_ram_o = mem_wstrb;

endmodule

