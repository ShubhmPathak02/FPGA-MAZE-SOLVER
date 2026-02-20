module pid_centering (
    input clk,
    input [20:0] l_dist, // Distance in mm/cm
    input [20:0] r_dist,
    output signed [3:0] delta_speed // Changed to SIGNED for negative values
);

    // --- Tuning Parameters (Q8.8 Fixed Point) ---
    // KP = 1.0 (256), KI = 0.1 (25), KD = 0.5 (128)
    localparam signed [15:0] KP = 256; 
    localparam signed [15:0] KI = 26;  
    localparam signed [15:0] KD = 128; 

    // --- Sampling Timer (50MHz Clock -> 50Hz PID Loop) ---
    // 50,000,000 / 50Hz = 1,000,000 ticks
    localparam integer TIMER_MAX = 1000000;
    reg [19:0] timer;
    wire enable_pid;
    
    assign enable_pid = (timer == TIMER_MAX - 1);

    always @(posedge clk) begin
        if (timer < TIMER_MAX) timer <= timer + 1'b1;
        else timer <= 0;
    end

    // --- PID Logic ---
    reg signed [15:0] error;
    reg signed [15:0] last_error;
    reg signed [19:0] sum; // Increased width for integral accumulation
    
    reg signed [31:0] p_term;
    reg signed [31:0] i_term;
    reg signed [31:0] d_term;
    reg signed [31:0] pid_total;
    
    reg signed [3:0]  delta_out;

    assign delta_speed = delta_out;

    initial begin
        timer = 0;
        sum = 0;
        last_error = 0;
        delta_out = 0;
    end

    always @(posedge clk) begin
        if (enable_pid) begin
            // 1. Calculate Error (Target is centered, so Left - Right should be 0)
            // Use $signed() to ensure Verilog treats these as signed math
            error <= $signed(l_dist) - $signed(r_dist);

            // 2. Calculate Terms
            p_term <= KP * error;
//            i_term <= KI * sum; 
            d_term <= KD * (error - last_error);

            // 3. Integral Windup Guard (Clamping)
            // Prevent sum from growing to infinity if stuck
//            if (sum < 2000 && sum > -2000) begin
//                sum <= sum + error;
//            end else if (sum >= 2000 && error < 0) begin
//                sum <= sum + error; // Allow unwinding
//            end else if (sum <= -2000 && error > 0) begin
//                sum <= sum + error; // Allow unwinding
//            end

            // 4. Compute Total PID (Result is effectively Q8.8)
            pid_total <= p_term + d_term;
            
            // 5. Update History
            last_error <= error;
        end
    end

    // --- Output Scaling & Clamping (Separate Block for Clarity) ---
    always @(posedge clk) begin
        if (enable_pid) begin
            // Shift right by 8 to remove Fixed Point scale
            // Then shift right by 3 more (total 11) to reduce sensitivity
            // Using a temporary variable for readable slicing
            integer scaled_pid;
            scaled_pid = pid_total >>> 14; 

            // Hard clamp to 4-bit signed range (-8 to +7)
            if (scaled_pid > 7)
                delta_out <= 7;
            else if (scaled_pid < -8)
                delta_out <= -8;
            else
                delta_out <= scaled_pid[3:0];
        end
    end

endmodule