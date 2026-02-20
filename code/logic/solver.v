// Task 2C - MazeSolver Bot

module solver (
    input clk,
    input rst_n,
    input left, mid, right, // 0 - no wall, 1 - wall
	 input ira,
	 input irb,
	 input irc,
	input [31:0] distanceA, // Right Encoder
    input [31:0] distanceB, // Left Encoder
    output reg [2:0] move
);

/*

| cmd | move  | meaning   |
|-----|-------|-----------|
| 000 | 0     | STOP      |
| 001 | 1     | FORWARD   |
| 010 | 2     | LEFT      |
| 011 | 3     | RIGHT     | 
| 100 | 4     | U_TURN    |
| 101 | 5	  | FRONT NOPID|

START POS   : 4,0
EXIT POS    : 4,8
DEADENDS    : 9

*/
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

localparam DEBOUNCE=3'd2, TURN=3'd3, LOCK=3'd4, MOVE_FORWARD=3'd5, DECIDE=3'b1;
localparam STOP = 3'b000, FORWARD = 3'b001, LEFT = 3'b010, RIGHT = 3'b011, U_TURN = 3'b100, FRONT_NOPID = 3'b101;


reg [2:0] state = DECIDE;
reg [2:0] decision = 0;
reg [2:0] latest_decision = 0;
reg [2:0] last_lock_reading = 3'b000;
// reg [3:0] x,y;
// reg [1:0] direction;
// reg [7:0] steps;
// reg clk_divider;
// reg strategy; // 0 LWF 1 RWF

initial begin
	move = STOP;
	state = DECIDE;
	// x = 4;
	// y = 8;
	// direction = 0;
	// steps = 0;
	// clk_divider = 0;
	// strategy = 0;
end

reg [31:0] target_count_a = 0;
reg [31:0] target_count_b = 0;
// reg lock = 0;
reg [25:0] db_cnt = 0;

// Tuning
localparam TICK_90 = 16'd3000; // Lower this if it spins too much!
localparam DB_MAX  = 27'd50000000;
localparam MAX_DB_LOCK = 27'd5000000;

wire [31:0] abs_diff_A = (distanceA > target_count_a) ? (distanceA - target_count_a) : (target_count_a - distanceA);
wire [31:0] abs_diff_B = (distanceB > target_count_b) ? (distanceB - target_count_b) : (target_count_b - distanceB);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= DECIDE;
		move <= STOP;
	end else begin
		case (state) 
			//  decision wall moving priority
			DECIDE: begin
				if (!left && !right && !mid) begin 
						move <= STOP;
				end else if (!left)begin
					decision <= LEFT;
					state <= DEBOUNCE;
					latest_decision <= LEFT;
				end else if (!mid && left && right) begin
					state <= MOVE_FORWARD;
				end else if (!right) begin
					decision <= RIGHT;
					state <= DEBOUNCE;
					latest_decision <= RIGHT;
				end else if (left && right && mid && ira && irb && irc) begin
					decision <= U_TURN;
					state <= DEBOUNCE;
					latest_decision <= U_TURN;
				end
			end
			DEBOUNCE: begin
				if (decision != latest_decision) state <= DECIDE;
				else begin
					if ((db_cnt < DB_MAX)) begin
						db_cnt <= db_cnt + 1;
					end else begin
						db_cnt <= 0;
						state <= TURN;
						target_count_a <= distanceA;
						target_count_b <= distanceB;
					end
				end
				//  updating latest_decision
				if (!left) latest_decision <= LEFT;
				else if (!mid && left && right) latest_decision <= FORWARD;
				else if (!right) latest_decision <= RIGHT;
				else if (!left && !right && !mid) latest_decision <= U_TURN;
			end
			TURN: begin
				if (decision == LEFT) begin
					move <= LEFT;
					if (abs_diff_A >= TICK_90) state <= LOCK;
				end else if (decision == RIGHT) begin
					move <= RIGHT;
					if (abs_diff_B >= TICK_90) state <= LOCK;
				end else if (decision == U_TURN) begin
					move <= U_TURN;
					if (abs_diff_A >= TICK_90 * 2) state <= LOCK;
				end
			end
			LOCK: begin
				if ((left && mid) || (mid && right) || (right && left)) begin
					if (last_lock_reading == 3'b000) begin
						last_lock_reading <= {right,mid,left};
					end else if (last_lock_reading != {right,mid,left})begin
						db_cnt <= 0;
						state <= DECIDE;
						last_lock_reading <= 3'b000;
					end else if (db_cnt < MAX_DB_LOCK) begin
						db_cnt <= db_cnt + 1;
					end else begin
						state <= DECIDE;
						last_lock_reading <= 3'b000;
						db_cnt <= 0;
					end
				end else move <= FRONT_NOPID;
			end

			MOVE_FORWARD:begin
				if (left && right) begin
				 	move <= FORWARD;
				end else state <= DECIDE;
			end
		endcase
	end
	
end	


//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
