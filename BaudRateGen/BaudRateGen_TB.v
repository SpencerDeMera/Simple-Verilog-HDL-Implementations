`timescale 1ns/1ps

module BaudRateGen_TB();
    // Parameters match the DUT
    parameter CLOCK_FREQ = 100_000_000;
    parameter OVERSAMPLE = 16;

    // Inputs
    reg clk;
    reg reset_n;
    reg [1:0] baud_select; 

    // Outputs
    wire baud_tick;

    // Instantiate UUT
    BaudRateGen #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .OVERSAMPLE(OVERSAMPLE)
    ) uut (
        .clk(clk),
        .reset_n(reset_n),
        .baud_select(baud_select),
        .baud_tick(baud_tick)
    );

    // Reference and Verification Variables
    integer ref_divisor;
    integer errors;
    integer file_h;
    time last_tick_time;
    time period_measured;

    // Clock Generation (100MHz = 10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Reference Task ---
    // Sets the expected cycle count based on the select signal
    task ref_baud;
        begin
            case (baud_select)
                2'b00:   ref_divisor = CLOCK_FREQ / (9600 * OVERSAMPLE);
                2'b01:   ref_divisor = CLOCK_FREQ / (19200 * OVERSAMPLE);
                2'b10:   ref_divisor = CLOCK_FREQ / (38400 * OVERSAMPLE);
                2'b11:   ref_divisor = CLOCK_FREQ / (115200 * OVERSAMPLE);
                default: ref_divisor = CLOCK_FREQ / (9600 * OVERSAMPLE);
            endcase
        end
    endtask

    // --- Comparison Task ---
    // Measures time between ticks and compares to reference cycles
    task check_timing;
        real expected_ns;
        begin
            expected_ns = ref_divisor * 10; // 10ns per clock cycle
            period_measured = $time - last_tick_time;
            
            // Check if measured period matches expected period within tolerance
            if (period_measured != expected_ns) begin
                errors = errors + 1;
                $fdisplay(file_h, "[MISMATCH] Time:%0t | Sel:%b", $time, baud_select);
                $fdisplay(file_h, "  Expected Period: %0d ns", expected_ns);
                $fdisplay(file_h, "  Measured Period: %0d ns", period_measured);
            end
            last_tick_time = $time;
        end
    endtask

    initial begin
        // Update this path to your specific directory
        file_h = $fopen("C:/Users/spenc/Documents/Vivado_Sim_Output/baud_gen_test_log.txt", "w");
        
        if (file_h == 0) begin
            $display("ERROR: Could not open file.");
            $finish;
        end

        // Initialize
        errors = 0;
        last_tick_time = 0;
        reset_n = 0;
        baud_select = 2'b00;

        $fdisplay(file_h, "--- Starting BaudRateGen Comprehensive Test ---");
        
        // Reset sequence
        #20 reset_n = 1;
        
        // Loop through all 4 baud rate settings
        for (integer i = 0; i < 4; i = i + 1) begin
            baud_select = i[1:0];
            ref_baud();
            
            $fdisplay(file_h, "Testing Baud Setting: %b (Expected Divisor: %0d)", baud_select, ref_divisor);

            // Wait for a few pulses to stabilize and measure
            @(posedge baud_tick); // Sync to first pulse
            last_tick_time = $time;

            repeat (5) begin
                @(posedge baud_tick);
                check_timing();
            end
            
            #100; // Small gap between setting changes
        end

        // Final Report
        $fdisplay(file_h, "------------------------------------------------------");
        if (errors == 0)
            $fdisplay(file_h, "FINAL STATUS: PASS (0 Errors)");
        else
            $fdisplay(file_h, "FINAL STATUS: FAIL (%0d Errors Found)", errors);
            
        $fclose(file_h);
        $display("Testbench complete. Log saved to disk.");
        $finish;
    end

endmodule
