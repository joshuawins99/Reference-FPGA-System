module system_6502_top #(
    parameter FPGAClkSpeed = 50000000,
    parameter BaudRate6502 = 9600,
    parameter BaseAddress = 0,
    parameter EndAddress = 0,
    parameter address_width = 15,
    parameter data_width = 16
)(

    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    output logic [data_width-1:0]    data_o,
    input  logic [data_width-1:0]    data_i,
    input  logic                     rd_wr_i,
    input  logic [7:0]               ex_data_i,
    output logic [7:0]               ex_data_o,
    output logic                     uart_tx_o,
    input  logic                     uart_rx_i
);

    localparam CPU_Reset  = BaseAddress;
    localparam CPU_Pause  = BaseAddress + 1;
    localparam RAM_Start  = BaseAddress + 2;

    localparam RAM_Size   = 4096 + 6;

    logic [15:0]           cpu_addr;
    logic [7:0]            cpu_data_o;
    logic [7:0]            cpu_ram_data;
    logic                  cpu_we_o;
    logic [7:0]            sys_data;
    logic                  cpu_reset_reg = 0;
    logic [15:0]           address_ram_sys;
    logic [15:0]           cpu_addr_trans;
    logic                  cpu_we_ram;
    logic                  enable_cpu_we;
    logic                  pause_cpu_reg = 0;
    logic                  sys_we_ram;
    logic [7:0]            cpu_io_data;
    logic [7:0]            cpu_data_i;
    logic                  disable_ramr;
    logic                  disable_ramw;
    logic                  uart_disable_ramw;
    logic                  uart_disable_ramr;
    logic [7:0]            uart_data;
    logic                  bram_we;
    logic                  irq;

    logic                       reset = 1'b1;
    logic [7:0]                 reset_counter = '0;

    always_ff @(posedge clk_i) begin
        if (reset_counter >= 100) begin
            reset <= 1'b0;
        end else begin
            reset <= 1'b1;
            reset_counter <= reset_counter + 1'b1;
        end
    end

    always_comb begin
        if (disable_ramr == 1'b1) begin
            cpu_data_i = cpu_io_data;
        end else if (uart_disable_ramr == 1'b1) begin
            cpu_data_i = uart_data;
        end else begin
            cpu_data_i = cpu_ram_data;
        end
    end

    always_ff @(posedge clk_i) begin
        if (address_i >= CPU_Reset && address_i < CPU_Pause) begin
            if (rd_wr_i == 1'b1) begin
                cpu_reset_reg <= data_i[0];
            end else begin
                cpu_reset_reg <= cpu_reset_reg;
            end
        end else if (address_i >= CPU_Pause && address_i < RAM_Start) begin
            if (rd_wr_i == 1'b1) begin
                pause_cpu_reg <= data_i[0];
            end else begin
                pause_cpu_reg <= pause_cpu_reg;
            end
        end
        else begin
            cpu_reset_reg <= cpu_reset_reg;
            pause_cpu_reg <= pause_cpu_reg;
        end
    end

    always_comb begin
        if (address_i >= RAM_Start && address_i <= EndAddress) begin
            if (rd_wr_i == 1'b1) begin
                sys_we_ram = 1'b1;
                address_ram_sys = (address_i-RAM_Start);
            end else begin
                sys_we_ram = 1'b0;
                address_ram_sys = (address_i-RAM_Start);
            end
        end else begin
                sys_we_ram = 1'b0;
                address_ram_sys = '0;
        end
    end

    typedef enum logic [3:0] {reset_e, wait_cycle1_e, wait_cycle2_e, wait_cycle3_e, enable_we_e} state_t;

    state_t state = reset_e;

    always_ff @(posedge clk_i) begin
        unique case (state)
            reset_e : begin
                if (cpu_reset_reg == 1'b1 || reset == 1'b1) begin
                    enable_cpu_we <= 1'b0;
                    state <= wait_cycle1_e;
                end
            end
            wait_cycle1_e : begin
                if (cpu_reset_reg == 1'b0 && reset == 1'b0) begin
                    state <= wait_cycle2_e;
                end else begin
                    state <= wait_cycle1_e;
                end
            end
            wait_cycle2_e : begin
                state <= wait_cycle3_e;
            end
            wait_cycle3_e : begin
                state <= enable_we_e;
            end
            enable_we_e : begin
                enable_cpu_we <= 1'b1;
                if (cpu_reset_reg == 1'b1 || reset == 1'b1) begin
                    enable_cpu_we <= 1'b0;
                    state <= reset_e;
                end else begin 
                    state <= enable_we_e;
                end
            end
        endcase
    end

    always_comb begin //Handle Address Translation since not enough RAM to have it be default
        unique case (cpu_addr)
            'hFFFA : begin
                cpu_addr_trans = RAM_Size - 6;
            end
            'hFFFB : begin
                cpu_addr_trans = RAM_Size - 5;
            end
            'hFFFC : begin
                cpu_addr_trans = RAM_Size - 4;
            end
            'hFFFD : begin
                cpu_addr_trans = RAM_Size - 3;
            end
            'hFFFE : begin
                cpu_addr_trans = RAM_Size - 2;
            end
            'hFFFF : begin
                cpu_addr_trans = RAM_Size - 1;
            end
            default : begin
                cpu_addr_trans = cpu_addr;
            end
        endcase
    end

    always_comb begin
        if (enable_cpu_we == 1'b0 || pause_cpu_reg == 1'b1 || sys_we_ram == 1'b1 || reset == 1'b1) begin //Add reset_i
            cpu_we_ram = 1'b0;
        end else begin
            cpu_we_ram = cpu_we_o;
        end
    end

    always_comb begin
        if (disable_ramw == 1'b1 || uart_disable_ramw == 1'b1) begin
            bram_we = 1'b0;
        end else begin
            bram_we = cpu_we_ram;
        end
    end

    cpu cpu1 (
        .clk   (clk_i),
        .reset (cpu_reset_reg || reset), //Add reset_i
        .AB    (cpu_addr),
        .DI    (cpu_data_i),
        .DO    (cpu_data_o),
        .WE    (cpu_we_o),
        .IRQ   (irq),
        .NMI   ('0),
        .RDY   (~pause_cpu_reg)
    );

    bram_tdp #(
        .address_width  (16),
        .data_width     (8),
        .ram_size       (RAM_Size),
        .pre_fill       (1),
        .pre_fill_start ('h0200),
        .pre_fill_file  ("../cc65/mem_init.mem")
    ) ram1 (
        .a_clk          (clk_i),
        .b_clk          (clk_i),
        .a_addr         (address_ram_sys),
        .b_addr         (cpu_addr_trans),
        .a_wr           (sys_we_ram),
        .b_wr           (bram_we),
        .a_din          (data_i[7:0]),
        .b_din          (cpu_data_o),
        .a_dout         (sys_data),
        .b_dout         (cpu_ram_data)
    );

    io_6502 #(
        .BaseAddress     ('h9000),
        .address_width   (16),
        .data_width      (8)
    ) io_6502_1 (
        .clk_i           (clk_i),
        .reset_i         (cpu_reset_reg || reset), //Add reset_i
        .address_i       (cpu_addr_trans),
        .data_i          (cpu_data_o),
        .data_o          (cpu_io_data),
        .ex_data_i       (ex_data_i),
        .ex_data_o       (ex_data_o),
        .rd_wr_i         (cpu_we_ram),
        .irq_o           (irq),
        .take_controlr_o (disable_ramr),
        .take_controlw_o (disable_ramw)
    );

    uart_6502 #(
        .BaseAddress     ('h9100),
        .FPGAClkSpeed    (FPGAClkSpeed),
        .UARTBaudRate    (BaudRate6502)
    ) uart_6502_1 (
        .clk_i           (clk_i),
        .reset_i         (cpu_reset_reg || reset),
        .address_i       (cpu_addr_trans),
        .data_i          (cpu_data_o),
        .data_o          (uart_data),
        .rd_wr_i         (cpu_we_ram),
        .take_controlw_o (uart_disable_ramw),
        .take_controlr_o (uart_disable_ramr),
        .uart_tx_o       (uart_tx_o),
        .uart_rx_i       (uart_rx_i)
    );

    assign data_o = {{$bits(data_o/2){1'b0}}, sys_data};


endmodule