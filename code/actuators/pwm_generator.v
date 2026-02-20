module pwm_generator(
    input clk_3125KHz,
    input [3:0] duty_cycle,
    output reg clk_195KHz, pwm_signal
);

initial begin
    clk_195KHz = 0; pwm_signal = 1;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////
reg [2:0] clk_counter = 0; // clock counter tracking 
reg [3:0] pwm_counter = 0; // pwm counter tracking

always @ (posedge clk_3125KHz) begin
	if (!clk_counter) begin
		clk_195KHz = ~clk_195KHz;
	end
	 clk_counter = clk_counter + 1'b1;
end

always @ (posedge clk_3125KHz) begin
	if (pwm_counter >= duty_cycle) pwm_signal = 0;
	else pwm_signal = 1;
	pwm_counter = pwm_counter + 1'b1; 
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule

