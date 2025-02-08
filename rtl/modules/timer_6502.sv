module timer_6502 #(
    parameter BaseAddress = 0,
    parameter FPGAClkSpeed = 0,
    parameter TimerClkSpeed = 0,
    parameter address_width = 16,
    parameter data_width = 8
)(
    input  logic                     clk_i,
    input  logic                     reset_i,
    input  logic [address_width-1:0] address_i,
    input  logic [data_width-1:0]    data_i,
    output logic [data_width-1:0]    data_o,
    input  logic                     rd_wr_i
);

    localparam Set_Timer_Value_Address = BaseAddress + 0;
    localparam Start_Timer_Address     = BaseAddress + 1;
    localparam Read_Timer_Status       = BaseAddress + 2;

    localparam SlowClkDivider = FPGAClkSpeed/(TimerClkSpeed);
    localparam CalibrationFactor = 0;

    logic                           start_timer           = 1'b0;
    logic [31:0]                    tick_counter          = '0;
    logic [31:0]                    tick_count_value      = '0;
    logic                           slow_clk_pulse        = 1'b0;
    logic                           timer_done_pulse      = 1'b0;
    logic                           timer_done_pulse_read = 1'b0;
    logic [$clog2(TimerClkSpeed):0] slow_clk_counter      = '0;

    typedef enum logic [3:0] {idle_e, count_e, done_e} state_t;

    state_t state = idle_e;

    always_ff @(posedge clk_i) begin //Data Reads
        if (reset_i == 1'b0) begin
            if (timer_done_pulse == 1'b1) begin
                timer_done_pulse_read <= 1'b1;
            end
            if (rd_wr_i == 1'b0) begin
                unique case (address_i)
                    Read_Timer_Status : begin
                        if (timer_done_pulse_read == 1'b1) begin
                            data_o <= timer_done_pulse_read;
                            timer_done_pulse_read <= 1'b0;
                        end else begin
                            data_o <= '0;
                        end
                    end
                    default : begin
                        data_o <= '0;
                    end
                endcase
            end
        end else begin
            data_o <= '0;
            timer_done_pulse_read <= '0;
        end
    end

    always_ff @(posedge clk_i) begin //Data Writes
        start_timer <= 1'b0;
        if (reset_i == 1'b0) begin
            if (rd_wr_i == 1'b1) begin
                unique case (address_i)
                    Set_Timer_Value_Address : begin
                        tick_count_value <= {tick_count_value[($size(tick_count_value)-1)-8:0], data_i[7:0]};
                    end
                    Start_Timer_Address : begin
                        start_timer <= 1'b1;
                    end
                    default : begin
                        tick_count_value <= tick_count_value;
                    end
                endcase
            end
        end else begin
            start_timer <= '0;
            tick_count_value <= '0;
        end
    end

    always_ff @(posedge clk_i) begin //Timer Counter
        if (reset_i == 1'b0) begin
            unique case (state)
                idle_e : begin
                    tick_counter <= '0;
                    timer_done_pulse <= 1'b0;
                    if (start_timer == 1'b1) begin
                        state <= count_e;
                    end
                end
                count_e : begin
                    if (slow_clk_pulse == 1'b1) begin
                        if (tick_counter < (tick_count_value - CalibrationFactor)) begin
                            tick_counter <= tick_counter + 1'b1;
                        end else begin
                            timer_done_pulse <= 1'b1;
                            state <= idle_e;
                        end
                    end
                end
            endcase
        end else begin
            state <= idle_e;
        end
    end

    always_ff @(posedge clk_i) begin //Slower Counter Clock
        slow_clk_pulse <= 1'b0;
        if (reset_i == 1'b0) begin
            slow_clk_counter <= slow_clk_counter + 1'b1;
            if (slow_clk_counter >= SlowClkDivider) begin
                slow_clk_pulse <= 1'b1;
                slow_clk_counter <= '0;
            end
        end else begin
            slow_clk_counter <= '0;
        end
    end

endmodule