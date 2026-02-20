module ble(
    input clk_50M,
    input rx,
    input l_op, r_op, f_op,
    output tx
);

    wire clk_3125KHz;
    frequency_scaling fs (.clk_50M(clk_50M), .clk_3125KHz(clk_3125KHz));

    // Synchronize inputs
    reg l_s1, r_s1, f_s1, l_s0, r_s0, f_s0;
    always @(posedge clk_3125KHz) begin
        l_s0 <= l_op; l_s1 <= l_s0;
        r_s0 <= r_op; r_s1 <= r_s0;
        f_s0 <= f_op; f_s1 <= f_s0;
    end

    wire dead_now = l_s1 & r_s1 & f_s1;
    reg dead_prev;
    
    // --- 5 SECOND LOCKOUT TIMER ---
    // At 3.125MHz, 5 seconds is 15,625,000 cycles.
    // 24 bits can hold up to 16,777,215.
    reg [23:0] lockout_timer = 0;
    localparam FIVE_SECONDS = 24'd15_625_000;

    reg [3:0] dead_end_count = 4'd1; 
    localparam IDLE = 0, SEND_CHAR = 1, WAIT_DONE = 2;
    reg [1:0] state = IDLE;
    reg [2:0] char_index = 0;
    
    reg tx_start_reg;
    reg [7:0] tx_data_reg;
    wire tx_done;

    tx u_tx (
        .clk_3125(clk_3125KHz),
        .parity_type(1'b0),
        .tx_start(tx_start_reg),
        .data(tx_data_reg),
        .tx(tx),
        .tx_done(tx_done)
    );

    always @(posedge clk_3125KHz) begin
        dead_prev <= dead_now;

        // Timer countdown logic
        if (lockout_timer > 0) 
            lockout_timer <= lockout_timer - 1;

        case (state)
            IDLE: begin
                tx_start_reg <= 1'b0;
                char_index <= 0;
                // Detect NEW dead end ONLY if lockout timer has expired
                if (dead_now && !dead_prev && (lockout_timer == 0)) begin
                    state <= SEND_CHAR;
                    lockout_timer <= FIVE_SECONDS; // Start the 5s cooldown
                end
            end

            SEND_CHAR: begin
                tx_start_reg <= 1'b1;
                case (char_index)
                    3'd0: tx_data_reg <= 8'h4D; // 'M'
                    3'd1: tx_data_reg <= 8'h50; // 'P'
                    3'd2: tx_data_reg <= 8'h49; // 'I'
                    3'd3: tx_data_reg <= 8'h4D; // 'M'
                    3'd4: tx_data_reg <= 8'h2D; // '-'
                    3'd5: tx_data_reg <= 8'h30 + dead_end_count; 
                    3'd6: tx_data_reg <= 8'h23; // '#'
                    default: tx_data_reg <= 8'h20;
                endcase
                state <= WAIT_DONE;
            end

            WAIT_DONE: begin
                tx_start_reg <= 1'b0;
                if (tx_done) begin
                    if (char_index == 3'd6) begin
                        state <= IDLE;
                        if (dead_end_count >= 9) dead_end_count <= 4'd1;
                        else dead_end_count <= dead_end_count + 1;
                    end else begin
                        char_index <= char_index + 1;
                        state <= SEND_CHAR;
                    end
                end
            end
        endcase
    end
endmodule