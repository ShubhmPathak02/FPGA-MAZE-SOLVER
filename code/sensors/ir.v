module ir (
    input wire clk,              // System clock
    input wire rst_n,            // Active low reset
    input wire signal,         // Right IR sensor input (1 = wall detected)
    output reg obstacle        // Right wall detection signal
);

// Debounce counter width
parameter DEBOUNCE_COUNT = 16;
parameter DEBOUNCE_THRESHOLD = 10;

// Debounce counter
reg [DEBOUNCE_COUNT-1:0] right_counter;

// Synchronized inputs to avoid metastability
reg signal_sync1, signal_sync2;

// Synchronize input (2-stage synchronizer)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        signal_sync1 <= 1'b0;
        signal_sync2 <= 1'b0;
    end else begin
        signal_sync1 <= signal;
        signal_sync2 <= signal_sync1;
    end
end

// Right sensor debouncing and detection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        right_counter <= 0;
        obstacle <= 1'b1;
    end else begin
        if (signal_sync2) begin
            if (right_counter < DEBOUNCE_THRESHOLD)
                right_counter <= right_counter + 1'b1;
            else
                obstacle <= 1'b0;
        end else begin
            right_counter <= 0;
            obstacle <= 1'b1;
        end
    end
end

endmodule