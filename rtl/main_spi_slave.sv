module main_spi #(
    parameter FPGAClkSpeed = 50000000, //In Hz
    parameter BaudRate6502 = 9600,
    parameter address_width = 15,
    parameter data_width    = 16 //Actual data_width is 8 more than data width due to 8 bit crc. Use data_width not including crc for this number
)(

    input  logic clk_i,
    input  logic spi_clk_i,
    output logic k_line_tx_o,
    input  logic k_line_rx_i,
    output logic spi_miso_o,
    input  logic spi_mosi_i,
    input  logic reset_i,
    output logic led_o,
    output logic can_s_o,
    output logic uart_tx_o,
    input  logic uart_rx_i
);
    
    logic [data_width-1:0]    data_o_s_spi;
    logic                     rd_wr;

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
        version_string_e = 0,
        led_control_e,
        cpu_space_e,
        num_entries
    } module_bus;

    //Each enumeration gets a start and end address with the start address on the left and the end address on the right
    localparam [2*(address_width*num_entries)-1:0] module_addresses = {
        add_address('h1000, 'h1013), //version_string_e
        add_address('h1200, 'h1200), //led_control_e
        add_address('h2000, 'h5000)  //cpu_space_e
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

    always_comb begin
        data_reg = '0;
        for (int unsigned i = 0; i < num_entries; i++) begin
            if (address >= get_address_mux(2*i+1) && address <= get_address_mux(2*i)) begin
                data_reg = data_reg_inputs[(num_entries-1)-i];
            end
        end
    end
//************************************************************************************************************

    slave_spi_controller #(
        .address_width (address_width),
        .data_width    (data_width)
    ) s_spi1 (
        .clk_i         (clk_i),
        .reset_i       (reset_i),
        .spi_clk_i     (spi_clk_i),
        .spi_miso_o    (spi_miso_o),
        .spi_mosi_i    (spi_mosi_i),
        .address_o     (address),
        .data_o        (data_o_s_spi),
        .data_i        (data_reg),
        .rd_wr_o       (rd_wr)
    );

    version_string #(
        .BaseAddress         (get_address_start(version_string_e)),
        .NumCharacters       (44),
        .CharsPerTransaction (2),
        .address_width       (address_width),
        .data_width          (data_width)
    ) vs1 (
        .clk_i               (clk_i),
        .address_i           (address),
        .data_i              (data_o_s_spi),
        .rd_wr_i             (rd_wr),
        .data_o              (data_reg_inputs[version_string_e])
    );

    led_control #(
        .BaseAddress   (get_address_start(led_control_e)),
        .address_width (address_width),
        .data_width    (data_width)
    ) led1 (
        .clk_i         (clk_i),
        .address_i     (address),
        .data_i        (data_o_s_spi),
        .led_o         (led_o),
        .rd_wr_i       (rd_wr),
        .data_o        (data_reg_inputs[led_control_e])
    );

    system_6502_top #(
        .FPGAClkSpeed   (FPGAClkSpeed),
        .BaudRate6502   (BaudRate6502),
        .BaseAddress    (get_address_start(cpu_space_e)),
        .EndAddress     (get_address_end(cpu_space_e)),
        .address_width  (address_width),
        .data_width     (data_width)
    ) s6502_1 (
        .clk_i          (clk_i),
        .reset_i        (reset_i),
        .address_i      (address),
        .data_o         (data_reg_inputs[cpu_space_e]),
        .data_i         (data_o_s_spi),
        .rd_wr_i        (rd_wr),
        .ex_data_i      ('0),
        .ex_data_o      (),
        .uart_tx_o      (uart_tx_o),
        .uart_rx_i      (uart_rx_i)
    );


endmodule
