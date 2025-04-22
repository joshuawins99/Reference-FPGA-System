module main_rv32 #(
    parameter FPGAClkSpeed        = 50000000, //In Hz
    parameter ETHSPIClkSpeed      = 1000000,
    parameter DACSPIClkSpeed      = 1000000,
    parameter ADCSPIClkSpeed      = 1000000,
    parameter MaxADCBurstReadings = 13,
    parameter BaudRateCPU         = 230400,
    parameter address_width       = 16,
    parameter data_width          = 8
)(

    input  logic       clk_i,
    input  logic       clk_48_i,
    input  logic       reset_i,
    output logic       uart_tx_o,
    input  logic       uart_rx_i,
    output logic [7:0] ex_data_o,
    input  logic [7:0] ex_data_i,
    output logic       usb_dp_pull,
    inout              usb_dp,
    inout              usb_dn,
    output logic       eth_sclk_o,
    output logic       eth_mosi_o,
    input  logic       eth_miso_i,
    output logic       eth_reset_o,
    output logic       dac_sclk_o,
    output logic       dac_mosi_o,
    output logic       dac_sync_no,
    output logic       adc_sclk_o,
    input  logic       adc_miso_i,
    output logic       adc_sync_no
);

    localparam              RAM_Size                   = 12288;
    localparam logic [31:0] Program_RV32_Start_Address = 32'h0;
    
    localparam VersionStringSize = 64;
    
    logic [data_width-1:0]    cpu_data_o;
    logic                     cpu_we_o;
    logic [3:0]               we_ram_o;
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
        reset_e,
        uart_e,
        ethernet_e,
        dac_e,
        adc_e,
        timer_e,
    `ifdef ECP5
        ecp5_dtr_e,
    `endif
        dummy_e,
        num_entries
    } module_bus;

    //Each enumeration gets a start and end address with the start address on the left and the end address on the right
    localparam [2*(address_width*num_entries)-1:0] module_addresses = {
        add_address('h0000, RAM_Size),                        //ram_e
        add_address('h8000, 'h8000+(VersionStringSize-1)*4),  //version_string_e
        add_address('h9000, 'h900C),                          //io_e
        add_address('h9010, 'h901C),                          //reset_e
        add_address('h9100, 'h9110),                          //uart_e
        add_address('h9200, 'h920C),                          //ethernet_e
        add_address('h9210, 'h921C),                          //dac_e
        add_address('h9220, 'h9230),                          //adc_e
        add_address('h9300, 'h9308),                          //timer_e
    `ifdef ECP5
        add_address('h9400, 'h9400),                          //ecp5_dtr_e
    `endif
        add_address('hA000, 'hA000)                           //dummy_e for when dtr doesnt exist
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
    logic [63:0]                reset_counter = '0;
    logic [7:0]                 reset_int;

    always_ff @(posedge clk_i) begin
        if (reset_i == 1'b1) begin
            usb_dp_pull <= 1'b0;
            eth_reset_o <= 1'b0;
            reset <= 1'b1;
            reset_counter <= '0;
        end else if (reset_counter >= FPGAClkSpeed) begin
            reset <= 1'b0;
            eth_reset_o <= 1'b1;
            usb_dp_pull <= 1'b1;
        end else begin
            reset <= 1'b1;
            eth_reset_o <= 1'b0;
            usb_dp_pull <= 1'b0;
            reset_counter <= reset_counter + 1'b1;
        end
    end

    cpu_rv32 #(
        .ProgramStartAddress (Program_RV32_Start_Address),
        .StackAddress        (),
        .address_width       (address_width)
    ) cpu1 (
        .clk_i     (clk_i),
        .reset_i   (reset),
        .address_o (address),
        .data_i    (data_reg),
        .data_o    (cpu_data_o),
        .we_o      (cpu_we_o),
        .we_ram_o  (we_ram_o)
    );

    bram_contained_rv32 #(
        .BaseAddress    (get_address_start(ram_e)),
        .EndAddress     (get_address_end(ram_e)),
        .address_width  (16),
        .data_width     (32),
        .ram_size       (RAM_Size),
        .pre_fill       (1),
        .pre_fill_start (Program_RV32_Start_Address),
        .pre_fill_file  ("../rv32_gcc/mem_init.mem")
    ) ram1 (
        .clk            (clk_i),
        .addr           (address),
        .wr             (we_ram_o),
        .din            (cpu_data_o),
        .dout           (data_reg_inputs[ram_e])
    );

    version_string #(
        .BaseAddress         (get_address_start(version_string_e)),
        .NumCharacters       (VersionStringSize),
        .CharsPerTransaction (1),
        .address_width       (address_width),
        .data_width          (8),
        .Address_Wording     (4)
    ) version_string_1 (
        .clk_i               (clk_i),
        .address_i           (address_reg),
        .data_i              (cpu_data_o[7:0]),
        .rd_wr_i             (cpu_we_o),
        .data_o              (data_reg_inputs[version_string_e][7:0])
    );

    io_cpu #(
        .BaseAddress     (get_address_start(io_e)),
        .address_width   (16),
        .data_width      (8),
        .Address_Wording (4)
    ) io_rv32_1 (
        .clk_i           (clk_i),
        .reset_i         (reset),
        .address_i       (address),
        .data_i          (cpu_data_o[7:0]),
        .data_o          (data_reg_inputs[io_e][7:0]),
        .ex_data_i       (ex_data_i),
        .ex_data_o       (ex_data_o),
        .rd_wr_i         (cpu_we_o),
        .irq_o           (irq),
        .take_controlr_o (),
        .take_controlw_o ()
    );

    io_cpu #(
        .BaseAddress     (get_address_start(reset_e)),
        .address_width   (16),
        .data_width      (8),
        .Address_Wording (4)
    ) io_rv32_reset_1 (
        .clk_i           (clk_i),
        .reset_i         (reset),
        .address_i       (address),
        .data_i          (cpu_data_o[7:0]),
        .data_o          (data_reg_inputs[reset_e][7:0]),
        .ex_data_i       ('0),
        .ex_data_o       (reset_int),
        .rd_wr_i         (cpu_we_o),
        .irq_o           (),
        .take_controlr_o (),
        .take_controlw_o ()
    );

    spi_master #(
        .BaseAddress         (get_address_start(ethernet_e)),
        .BytesPerTransaction (4),
        .FPGAClkSpeed        (FPGAClkSpeed),
        .SPIClkSpeed         (ETHSPIClkSpeed),
        .address_width       (16),
        .data_width          (8),
        .Address_Wording     (4)
    ) ethernet_spi_1 (
        .clk_i               (clk_i),
        .reset_i             (reset),
        .address_i           (address),
        .data_i              (cpu_data_o[7:0]),
        .data_o              (data_reg_inputs[ethernet_e][7:0]),
        .rd_wr_i             (cpu_we_o),
        .spi_clk_o           (eth_sclk_o),
        .spi_miso_i          (eth_miso_i),
        .spi_mosi_o          (eth_mosi_o),
        .spi_sync_no         ()
    );

    spi_master #(
        .BaseAddress         (get_address_start(dac_e)),
        .BytesPerTransaction (3),
        .FPGAClkSpeed        (FPGAClkSpeed),
        .SPIClkSpeed         (DACSPIClkSpeed),
        .address_width       (16),
        .data_width          (8),
        .Address_Wording     (4)
    ) dac_spi_1 (
        .clk_i               (clk_i),
        .reset_i             (reset),
        .address_i           (address),
        .data_i              (cpu_data_o[7:0]),
        .data_o              (data_reg_inputs[dac_e][7:0]),
        .rd_wr_i             (cpu_we_o),
        .spi_clk_o           (dac_sclk_o),
        .spi_miso_i          ('0),
        .spi_mosi_o          (dac_mosi_o),
        .spi_sync_no         (dac_sync_no)
    );

    spi_master_burst #(
        .BaseAddress         (get_address_start(adc_e)),
        .BytesPerTransaction (2),
        .MaxADCBurstReadings (MaxADCBurstReadings),
        .FPGAClkSpeed        (FPGAClkSpeed),
        .SPIClkSpeed         (ADCSPIClkSpeed),
        .address_width       (16),
        .data_width          (8),
        .Address_Wording     (4)
    ) adc_spi_1 (
        .clk_i               (clk_i),
        .reset_i             (reset),
        .address_i           (address),
        .data_i              (cpu_data_o[7:0]),
        .data_o              (data_reg_inputs[adc_e][7:0]),
        .rd_wr_i             (cpu_we_o),
        .spi_clk_o           (adc_sclk_o),
        .spi_miso_i          (adc_miso_i),
        .spi_mosi_o          (),
        .spi_sync_no         (adc_sync_no)
    );

    timer_cpu #(
        .BaseAddress     (get_address_start(timer_e)),
        .FPGAClkSpeed    (FPGAClkSpeed),
        .TimerClkSpeed   (10000),
        .address_width   (16),
        .data_width      (8),
        .Address_Wording (4)
    ) timer_rv32_1 (
        .clk_i         (clk_i),
        .reset_i       (reset),
        .address_i     (address),
        .data_i        (cpu_data_o[7:0]),
        .data_o        (data_reg_inputs[timer_e][7:0]),
        .rd_wr_i       (cpu_we_o)
    );

`ifdef ECP5
    ecp5_dtr #(
        .BaseAddress   (get_address_start(ecp5_dtr_e)),
        .address_width (16),
        .data_width    (8)
    ) ecp5_dtr_inst (
        .clk_i         (clk_i),
        .reset_i       (reset),
        .address_i     (address),
        .data_i        (cpu_data_o[7:0]),
        .data_o        (data_reg_inputs[ecp5_dtr_e][7:0]),
        .rd_wr_i       (cpu_we_o)
    );
`endif

`ifndef USB_UART
    uart_cpu #(
        .BaseAddress     (get_address_start(uart_e)),
        .FPGAClkSpeed    (FPGAClkSpeed),
        .UARTBaudRate    (BaudRateCPU),
        .Address_Wording (4)
    ) uart_rv32_1 (
        .clk_i           (clk_i),
        .reset_i         (reset),
        .address_i       (address),
        .data_i          (cpu_data_o[7:0]),
        .data_o          (data_reg_inputs[uart_e][7:0]),
        .rd_wr_i         (cpu_we_o),
        .take_controlw_o (),
        .take_controlr_o (),
        .uart_tx_o       (uart_tx_o),
        .uart_rx_i       (uart_rx_i)
    );    
`else
    uart_usb #(
        .BaseAddress     (get_address_start(uart_e)),
        .Address_Wording (4)
    ) uart_rv32_1 (
        .clk_i           (clk_i),
        .clk_48_i        (clk_48_i),
        .reset_i         (reset),
        .address_i       (address),
        .data_i          (cpu_data_o[7:0]),
        .data_o          (data_reg_inputs[uart_e][7:0]),
        .rd_wr_i         (cpu_we_o),
        .pin_usb_p       (usb_dp),
        .pin_usb_n       (usb_dn)
    );
`endif

endmodule
