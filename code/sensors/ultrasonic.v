module ultrasonic #(
    parameter CLK_FREQ      = 50000000,
    parameter TRIG_PULSE_US = 10,
    parameter MAX_DIST_CM   = 14
) (
    input               clk_50M,
	 input					reset,
    input               echo_rx,
    output reg          trig,
    output reg          op,
    output reg [20:0]   distance_out
);

// --- Fixed-Point Integer Math ---
// 1. Get MHz: 50,000,000 / 1,000,000 = 50
localparam CLK_MHZ = CLK_FREQ / 1000000;

// 2. Max Count calculation:
// Standard conversion is 58us per cm. 
// Max ticks = MAX_DIST_CM * 58us * ticks_per_us
localparam MAX_COUNT = MAX_DIST_CM * 58 * CLK_MHZ;

localparam DEBOUNCE_CNT_LIMIT = 500000; // 10 ms at 50 MHz

// Internal registers
reg [31:0]  echo_count = 0;
reg         echo_prev = 0;
reg [31:0]  trig_counter = 0;
reg         detect = 0;
reg [31:0]  debounce_clk_cnt = 0;

// Trigger pulse generator (10us pulse every 60ms)
always @(posedge clk_50M) begin
    if (trig_counter < (CLK_FREQ * 60 / 1000)) begin 
        trig_counter <= trig_counter + 1;
    end else begin
        trig_counter <= 0;
    end

    trig <= (trig_counter < (TRIG_PULSE_US * CLK_MHZ));
end

// Echo pulse measurement and Distance Calculation
always @(posedge clk_50M) begin
    echo_prev <= echo_rx;

    if (~echo_prev && echo_rx) begin
        echo_count <= 0;
    end
    else if (echo_rx) begin
        echo_count <= echo_count + 1;
    end

    // Falling edge of echo: Calculate distance
    if (echo_prev && ~echo_rx) begin
        // Distance (mm) = (echo_count * Speed_of_sound_mm_per_us) / (2 * CLK_MHZ)
        // To avoid decimals, we use: (echo_count * 343) / (CLK_MHZ * 2000)
        // For 50MHz: (echo_count * 343) / 100,000
        distance_out <= (echo_count * 343) / (CLK_MHZ * 2000);

        if (echo_count <= MAX_COUNT)
            detect <= 1;
        else
            detect <= 0;
    end
end

// Debounce logic
always @(posedge clk_50M) begin
    if((op != detect) && (debounce_clk_cnt < DEBOUNCE_CNT_LIMIT)) begin
        debounce_clk_cnt <= debounce_clk_cnt + 1;
    end
    else if(debounce_clk_cnt == DEBOUNCE_CNT_LIMIT) begin
        op <= detect;
        debounce_clk_cnt <= 0;
    end 
    else begin
        debounce_clk_cnt <= 0;
    end
end

endmodule