module main_6502 #(
    parameter FPGAClkSpeed = 50000000, //In Hz
    parameter BaudRate6502 = 230400,
    parameter address_width = 16,
    parameter data_width    = 8
)(

    input  logic       clk_i,
    input  logic       clk_48_i,
    input  logic       reset_i,
    output logic       uart_tx_o,
    input  logic       uart_rx_i,
    output logic [7:0] ex_data_o,
    output logic       usb_dp_pull,
    inout              usb_dp,
    inout              usb_dn
);

    localparam RAM_Size = 8192;
    
    logic [data_width-1:0]    cpu_data_o;
    logic                     cpu_we_o;
    logic                     irq;

//******************************************* Data Registers and Mux *******************************************
    logic [data_width-1:0]    data_reg;
    logic [address_width-1:0] address;
    
    function [(2*address_width)-1:0] add_address (
        input logic [address_width-1:0] start_address,
        input logic [address_width-1:0] end_address
    );
        begin
            add_address[address_width-1:0] = end_address;
            add_address[2*address_width-1:address_width] = start_address;
        end
    endfunction

    //Enter a new enumeration for every new module added to the bus
    enum {
        ram_e = 0,
        version_string_e,
        io_e,
        uart_e,
        special_e,
        num_entries
    } module_bus;

    //Each enumeration gets a start and end address with the start address on the left and the end address on the right
    localparam [2*(address_width*num_entries)-1:0] module_addresses = {
        add_address('h0000, RAM_Size-1), //ram_e
        add_address('h8000, 'h802A),     //version_string_e
        add_address('h9000, 'h9010),     //io_e
        add_address('h9100, 'h9110),     //uart_e
        add_address('hFFFA, 'hFFFF)      //special_e
    };

    typedef logic [data_width-1:0] data_reg_inputs_t [0:num_entries-1];
    data_reg_inputs_t data_reg_inputs;

    function [address_width-1:0] get_address_start (
            input [$clog2(num_entries):0] val
        );
            begin
                get_address_start = module_addresses[(2*((num_entries-1)-val)+1)*address_width +: address_width];
            end
    endfunction

    function [address_width-1:0] get_address_end (
            input [$clog2(num_entries):0] val
        );
            begin
                get_address_end = module_addresses[(2*((num_entries-1)-val))*address_width +: address_width];
            end
    endfunction

    function [address_width-1:0] get_address_mux (
            input [$clog2(num_entries):0] val
        );
            begin
                get_address_mux = module_addresses[val*address_width +: address_width];
            end
    endfunction

    logic [15:0] address_reg;

    always_ff @(posedge clk_i) begin
        address_reg <= address;
    end 

    always_comb begin
        data_reg = '0;
        for (int unsigned i = 0; i < num_entries; i++) begin
            if (address_reg >= get_address_mux(2*i+1) && address_reg <= get_address_mux(2*i)) begin
                data_reg = data_reg_inputs[(num_entries-1)-i];
            end
        end
    end
//************************************************************************************************************

    logic                       reset = 1'b1;
    logic [7:0]                 reset_counter = '0;

    logic [7:0]                 spec_mem [5:0];

    initial begin
        spec_mem[2] = 'h02;
        spec_mem[3] = 'h00;
    end

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            usb_dp_pull <= 1'b0;
        end else if (reset_counter >= 100) begin
            reset <= 1'b0;
            usb_dp_pull <= 1'b1;
        end else begin
            reset <= 1'b1;
            usb_dp_pull <= 1'b0;
            reset_counter <= reset_counter + 1'b1;
        end
    end

    cpu cpu1 (
        .clk   (clk_i),
        .reset (reset),
        .AB    (address),
        .DI    (data_reg),
        .DO    (cpu_data_o),
        .WE    (cpu_we_o),
        .IRQ   (irq),
        .NMI   ('0),
        .RDY   ('1)
    );

    always_ff @(posedge clk_i) begin
        if (address >= 'hFFFA && address <= 'hFFFF) begin
            if (cpu_we_o == 1'b0) begin
                data_reg_inputs[special_e] <= spec_mem['hFFFF-address];
            end else begin
                spec_mem['hFFFF-address] <= cpu_data_o;
            end
        end else begin
            data_reg_inputs[special_e] <= data_reg_inputs[special_e];
        end
    end

    bram_contained #(
        .BaseAddress    (get_address_start(ram_e)),
        .EndAddress     (get_address_end(ram_e)),
        .address_width  (16),
        .data_width     (8),
        .ram_size       (RAM_Size),
        .pre_fill       (1),
        .pre_fill_start ('h0200),
        .pre_fill_file  ("../cc65/mem_init.mem")
    ) ram1 (
        .clk            (clk_i),
        .addr           (address),
        .wr             (cpu_we_o),
        .din            (cpu_data_o),
        .dout           (data_reg_inputs[ram_e])
    );

    version_string #(
        .BaseAddress         (get_address_start(version_string_e)),
        .NumCharacters       (44),
        .CharsPerTransaction (1),
        .address_width       (address_width),
        .data_width          (data_width)
    ) version_string_1 (
        .clk_i               (clk_i),
        .address_i           (address_reg),
        .data_i              (cpu_data_o),
        .rd_wr_i             (cpu_we_o),
        .data_o              (data_reg_inputs[version_string_e])
    );

    io_6502 #(
        .BaseAddress     (get_address_start(io_e)),
        .address_width   (16),
        .data_width      (8)
    ) io_6502_1 (
        .clk_i           (clk_i),
        .reset_i         (reset || reset_i),
        .address_i       (address),
        .data_i          (cpu_data_o),
        .data_o          (data_reg_inputs[io_e]),
        .ex_data_i       ('0),
        .ex_data_o       (ex_data_o),
        .rd_wr_i         (cpu_we_o),
        .irq_o           (irq),
        .take_controlr_o (),
        .take_controlw_o ()
    );

`ifndef USB_UART
    uart_6502 #(
        .BaseAddress     (get_address_start(uart_e)),
        .FPGAClkSpeed    (FPGAClkSpeed),
        .UARTBaudRate    (BaudRate6502)
    ) uart_6502_1 (
        .clk_i           (clk_i),
        .reset_i         (reset),
        .address_i       (address),
        .data_i          (cpu_data_o),
        .data_o          (data_reg_inputs[uart_e]),
        .rd_wr_i         (cpu_we_o),
        .take_controlw_o (),
        .take_controlr_o (),
        .uart_tx_o       (uart_tx_o),
        .uart_rx_i       (uart_rx_i)
    );    
`else
    uart_usb #(
        .BaseAddress     (get_address_start(uart_e))
    ) uart_6502_1 (
        .clk_i           (clk_i),
        .clk_48_i        (clk_48_i),
        .reset_i         (reset_i || reset),
        .address_i       (address),
        .data_i          (cpu_data_o),
        .data_o          (data_reg_inputs[uart_e]),
        .rd_wr_i         (cpu_we_o),
        .pin_usb_p       (usb_dp),
        .pin_usb_n       (usb_dn)
    );
`endif

endmodule
