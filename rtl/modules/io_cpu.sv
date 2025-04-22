module io_cpu #(
    parameter BaseAddress     = 0,
    parameter address_width   = 16,
    parameter data_width      = 8,
    parameter Address_Wording = 1
)(
    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    input  logic [data_width-1:0]    data_i,
    output logic [data_width-1:0]    data_o,
    input  logic [data_width-1:0]    ex_data_i,
    output logic [data_width-1:0]    ex_data_o,
    input  logic                     rd_wr_i,
    output logic                     irq_o,
    output logic                     take_controlr_o,
    output logic                     take_controlw_o
);
    localparam External_Inputs_Address  = BaseAddress + (0*Address_Wording);
    localparam External_Outputs_Address = BaseAddress + (1*Address_Wording);
    localparam IRQ_Mask                 = BaseAddress + (2*Address_Wording);
    localparam IRQ_Clear                = BaseAddress + (3*Address_Wording);

    logic [data_width-1:0] external_inputs_reg;
    logic [data_width-1:0] external_outputs_reg;
    logic [data_width-1:0] input_irq_mask_reg = '0;
    logic [data_width-1:0] irq_reg = '0;

    always_ff @(posedge clk_i) begin //Data Reads
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b0) begin
                unique case (address_i)
                    External_Inputs_Address : begin
                        data_o <= external_inputs_reg;
                        take_controlr_o <= 1'b1;
                    end
                    External_Outputs_Address : begin
                        data_o <= external_outputs_reg;
                        take_controlr_o <= 1'b1;
                    end
                    IRQ_Mask : begin
                        data_o <= input_irq_mask_reg;
                        take_controlr_o <= 1'b1;
                    end
                    IRQ_Clear : begin
                        data_o <= irq_reg;
                        take_controlr_o <= 1'b1;
                    end
                    default : begin
                        data_o <= '0;
                        take_controlr_o <= 1'b0;
                    end
                endcase
            end
        end else begin
            data_o <= '0;
            take_controlr_o <= 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin //Data Writes
        take_controlw_o <= 1'b0;
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b1) begin
                unique case (address_i)
                    External_Outputs_Address : begin
                        take_controlw_o <= 1'b1;
                        ex_data_o <= data_i;
                        external_outputs_reg <= data_i;
                    end
                    IRQ_Mask : begin
                        take_controlw_o <= 1'b1;
                        input_irq_mask_reg <= data_i;
                    end
                    default : begin
                    take_controlw_o <= 1'b0;
                    external_outputs_reg <= external_outputs_reg;
                    input_irq_mask_reg <= input_irq_mask_reg;
                    end
                endcase
            end
        end else begin
            take_controlw_o <= 1'b0;
            ex_data_o <= '0;
        end
    end

    always_ff @(posedge clk_i) begin //IRQ
        if (reset_i == 1'b0) begin
            if ((external_inputs_reg & input_irq_mask_reg) != 0) begin
                irq_reg <= external_inputs_reg & input_irq_mask_reg;
                irq_o <= 1'b1;
            end else if (address_i == IRQ_Clear && rd_wr_i == 1'b0) begin
                irq_o <= 1'b0;
                irq_reg <= '0;
            end
        end else begin
            irq_reg <= '0;
            irq_o <= 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin
        external_inputs_reg <= ex_data_i;
    end

endmodule