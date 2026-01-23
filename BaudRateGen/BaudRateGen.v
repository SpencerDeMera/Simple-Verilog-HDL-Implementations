module BaudRateGen #(
    parameter CLOCK_FREQ = 100_000_000, // 100 Mhz system clock
    parameter OVERSAMPLE = 16
)(
    input wire clk,
    input wire reset_n,
    input wire [1:0] baud_select,

    output reg baud_tick
);
    // Pre-calculate the divisors at compile-time
    localparam DIV_9600   = CLOCK_FREQ / (9600 * OVERSAMPLE);
    localparam DIV_19200  = CLOCK_FREQ / (19200 * OVERSAMPLE);
    localparam DIV_38400  = CLOCK_FREQ / (38400 * OVERSAMPLE);
    localparam DIV_115200 = CLOCK_FREQ / (115200 * OVERSAMPLE);

    reg [15:0] current_divisor;
    reg [15:0] counter;

    // Select the pre-calculated divisor
    always @(*) begin
        case (baud_select)
            2'b00:   current_divisor = DIV_9600;
            2'b01:   current_divisor = DIV_19200;
            2'b10:   current_divisor = DIV_38400;
            2'b11:   current_divisor = DIV_115200;
            default: current_divisor = DIV_9600;
        endcase
    end

    // Counter Logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 16'd0;
            baud_tick <= 1'b0;
        end else begin
            // We check for (current_divisor - 1) to account for the 0-index
            if (counter >= (current_divisor - 1)) begin
                counter <= 16'd0; // reset counter
                baud_tick <= 1'b1; // Generate baud tick pulse
            end else begin
                counter <= counter + 16'd1; // increment counter
                baud_tick <= 1'b0; // No tick
            end
        end
    end
endmodule
