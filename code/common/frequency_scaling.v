module frequency_scaling (
    input clk_50M,
    output reg clk_3125KHz
);

initial begin
    clk_3125KHz = 0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////
reg [2:0] counter = 0; // counter for keeping count of 50MHz cycle 

always @(posedge clk_50M) begin
	/*
	Purpose:
	---
	to convert 50MHz to 3125KHz by fllipping clk on 8th rising edge of 50MHz
	*/

	if (!counter) begin
		clk_3125KHz = ~clk_3125KHz;
	end
	counter = counter + 1'b1;
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
