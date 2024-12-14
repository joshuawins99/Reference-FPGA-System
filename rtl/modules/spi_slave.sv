module spi_slave #(
    parameter int pktsz = 16,  //  size of SPI packet
    parameter int header = 8,  // size of header
    parameter int payload = 8, // size of payload
    parameter int addrsz = 7   // size of SPI Address Space
)(
    input  logic               clk,
    input  logic               reset_i,
    input  logic               SCLK,
    input  logic               SSB,
    input  logic               MOSI,
    output logic               MISO,
    input  logic [payload-1:0] tx_d,
    input  logic               tx_en,
    output logic [addrsz-1:0]  reg_addr,
    output logic               addr_dv,
    output logic [payload-1:0] rx_d,
    output logic               rxdv,
    output logic               rw_out
);            

    logic [2:0] sync_sclk;
    logic [2:0] sync_ss;
    logic [1:0] sync_mosi;
    logic [1:0] sync_tx_en;
    logic [$clog2(pktsz):0] bitcnt;
    logic rw;
    logic sync_sclk_re; 
    logic sync_sclk_fe;
    logic tx_en_re;
    logic spi_start; 
    logic spi_end; 
    logic spi_active;
    logic address_dv_pulse;
    logic d_i;
    logic [payload-1:0] d_o;
    
    logic mosi;
    logic sclk;
    logic ssb;
    
    wire reset;
    assign reset = reset_i;
    
    assign mosi = MOSI;
    assign sclk = SCLK;
        assign ssb = SSB;
    
    always_ff @ (posedge clk or negedge reset) begin
        if (~reset) begin
            sync_sclk <= 3'b000;
            sync_ss   <= 3'b111;
            sync_mosi <= 2'b00;
            sync_tx_en<= 2'b00;
        end else begin
            sync_sclk <= {sync_sclk[1:0], sclk};
            sync_ss   <= {sync_ss[1:0], ssb};
            sync_mosi <= {sync_mosi[0], mosi};
            sync_tx_en<= {sync_tx_en[0], tx_en};
        end
    end
    
    assign sync_sclk_fe = (sync_sclk[2:1]==2'b10) ? 1'b1 : 1'b0;
    assign sync_sclk_re = (sync_sclk[2:1]==2'b01) ? 1'b1 : 1'b0;
    
    assign spi_start = (sync_ss[2:1]==2'b10) ? 1'b1 : 1'b0;
    assign spi_end   =   (sync_ss[2:1]==2'b01) ? 1'b1 : 1'b0;
    assign spi_active = ~sync_ss[1];
    
    assign tx_en_re = (sync_tx_en==2'b01) ? 1'b1 : 1'b0;
    
    assign d_i = sync_mosi[1];
    
    always_ff @(posedge clk, negedge reset) begin
        if (~reset) begin
            bitcnt <= 0;
        end else if (spi_start) begin
            bitcnt <= 0;
        end else if (spi_active && sync_sclk_re) begin
            bitcnt <= bitcnt + 1;
        end
    end
    
    // Capture 1st bit from host.  If rw==0, a write from host to target.  1== read of FPGA to host
    always_ff @(posedge clk, negedge reset) begin
        if (~reset) begin
            rw <= 1'b0;
        end else if (spi_start || spi_end) begin
            rw <= 1'b0;
        end else if (spi_active && sync_sclk_re && bitcnt == 1'b0) begin
            rw <= d_i;
        end
    end
    
    // capture next 7 bits for register address
    always_ff @(posedge clk, negedge reset) begin
        if (~reset ) begin
            reg_addr <= 0;
        end else if (spi_start) begin
            reg_addr <= 0;
        end else if (spi_active && sync_sclk_re && bitcnt > 0 && bitcnt <= addrsz) begin
            reg_addr <= {reg_addr[addrsz-2:0], d_i };
        end
    end
    
    always_ff @(posedge clk, negedge reset) begin
        if (~reset) begin
            d_o <= 0;
        end else if (tx_en_re) begin 
            d_o <= tx_d;
        end else if (spi_active && sync_sclk_re) begin
            d_o <= {d_o[payload-2:0], 1'b0};
        end
    end
    
    always_ff @(posedge clk, negedge reset) begin
        if (~reset) begin
            rx_d <= 0;
        end else if (spi_start) begin
            rx_d <= 0;
        end else if (spi_active && sync_sclk_re && bitcnt > header - 1 && rw) begin
            rx_d <= {rx_d[payload-2:0], d_i};
        end
    end
    
    assign MISO = d_o[$left(d_o)];

    // address data valid
    always_ff @(posedge clk, negedge reset) begin
        if (~reset ) begin
            addr_dv <= 1'b0;
            address_dv_pulse <= 1'b0;
        end else if (spi_start || spi_end) begin
            addr_dv <= 1'b0;
            address_dv_pulse <= 1'b0;
        end else if (bitcnt > header - 1 && address_dv_pulse == 1'b0) begin
            addr_dv <= 1'b1;
            address_dv_pulse <= 1'b1;
        end else begin
            addr_dv <= 1'b0;
        end
    end
    
    always_ff @(posedge clk, negedge reset) begin
        if (~reset ) begin
            rxdv <= 1'b0;
        end else if (spi_start || spi_end) begin
            rxdv <= 1'b0;
        end else if (bitcnt == pktsz -1 && sync_sclk_re) begin
            rxdv <= 1'b1;
        end
    end
    
    assign rw_out = rw;
    
endmodule