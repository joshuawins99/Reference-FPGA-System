module uart_parity #(
    parameter DataWidth  = 8,
    parameter ParityType = "none"
)(
    input  logic [DataWidth-1:0] data_i,
    output logic                 parity_o
);

    generate
        if (ParityType == "even") begin
            logic parity_temp;
            always_comb begin
                parity_temp = 0;
                for (int i = 0; i < DataWidth; i++) begin
                    parity_temp = parity_temp ^ data_i[i];
                end
                parity_o = parity_temp;
            end
        end
        if (ParityType == "odd") begin
            logic parity_temp;
            always_comb begin
                parity_temp = 1;
                for (int i = 0; i < DataWidth; i++) begin
                    parity_temp = parity_temp ^ data_i[i];
                end
                parity_o = parity_temp;
            end
        end
        if (ParityType == "mark") begin
            assign parity_o = 1;
        end
        if (ParityType == "space") begin
            assign parity_o = 0;
        end
    endgenerate

endmodule