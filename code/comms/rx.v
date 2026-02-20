
module rx(
    input clk_3125,
    input rx,
    output reg [7:0] rx_msg,
    output reg rx_parity,
    output reg rx_complete
    );

initial begin
    rx_msg = 8'b0;
    rx_parity = 1'b0;
    rx_complete = 1'b0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

localparam START_BIT=2'b00, DATA_BIT= 2'b01, PARITY_BIT=2'b10, STOP_BIT= 2'b11 ;

reg [1:0] state;
reg [4:0] counter;
reg [2:0] pointer;
reg [7:0] data;
reg data_parity;
reg first;

initial begin
	counter <= 0;
	pointer = 0;
	state <= START_BIT;
	first = 1;
end

always @ (posedge clk_3125) begin
	case (state)
		START_BIT: begin
			if (counter >= 26) begin
				counter <= 0;
				state <= DATA_BIT;
			end else if (rx == 0) begin
				counter <= counter + 1;
			end
		end
		
		DATA_BIT: begin
			if (counter >= 26) begin
				counter <= 0;
				pointer <= pointer + 1;
				if (pointer == 7) state <= PARITY_BIT;
			end else begin
				counter <= counter + 1;
			end
		end
		
		PARITY_BIT: begin
			if (counter >= 26) begin
				counter <= 0;
				state <= STOP_BIT;
			end else begin
				counter <= counter + 1;
			end
		end
		
		STOP_BIT: begin
			if (counter >= 26) begin
				counter <= 0;
				state <= START_BIT;
			end else begin
				counter <= counter + 1;
			end
		end
	endcase
end


always @(*) begin
   if (state == START_BIT)begin
		if (counter == 0 && ~first) begin
			rx_parity = data_parity;
			rx_complete = 1;
			rx_msg = (^data == data_parity) ? data : 63;
		end else begin
			rx_complete = 0;
			first = 0;
		end
	end
	if (state == DATA_BIT) begin
		if (counter == 15) data[7-pointer] = rx; // reading bit in mid of pulse to avoid reading at last 
	end
	if (state == PARITY_BIT && counter == 15) data_parity = rx;
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule
