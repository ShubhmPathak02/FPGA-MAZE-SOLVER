// module top(clk_50M, trig, echo_rx, op, distance_out, reset,is_front);

// 	input 		 clk_50M;
// 	output 		 trig;
// 	input			 echo_rx; 
// 	input reset;
// 	input is_front;
// 	output op;
// 	output [20:0] distance_out;
	
// 	wire start, new_measure, timeout;
// 	wire [20:0] distance_raw;

// 	reg [24:0] counter_ping;
// 	reg op_reg = 0;
	
// 	localparam WALL_THRESHOLD = 140;
// 	localparam FRONT_THRESHOLD = 140;
	
// 	assign op = (is_front) ? (((distance_raw + (370/2)) / 370) < FRONT_THRESHOLD) : (((distance_raw + (370/2)) / 370) < WALL_THRESHOLD);
	
// 	localparam CLK_MHZ = 50;			
// 	localparam PERIOD_PING_MS = 60; 
	
	
// 	localparam COUNTER_MAX_PING = CLK_MHZ * PERIOD_PING_MS * 1000;


// 	localparam D = 2900;


// 	ultrasonic #(	.CLK_MHZ(50), 
// 						.TRIGGER_PULSE_US(12), 
// 						.TIMEOUT_MS(3)
// 					) U1
// 						(	.clk(clk_50M),
// 							.trigger(trig),
// 							.echo(echo_rx),
// 							.start(start),
// 							.new_measure(new_measure),
// 							.timeout(timeout),
// 							.distance_raw(distance_raw)
// 						);
						
		
// 	assign distance_out = (distance_raw + (370/2)) / 370;
// 	assign start = (counter_ping == COUNTER_MAX_PING - 1);

// 	always @(posedge clk_50M) begin
// 		if (counter_ping == COUNTER_MAX_PING - 1)
// 			counter_ping <= 25'd0;
// 		else begin	
// 			counter_ping <= counter_ping + 25'd1;
// 		end
// 	end


// endmodule
