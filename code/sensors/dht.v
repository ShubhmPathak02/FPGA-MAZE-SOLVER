
module dht(
    input clk_50M,
    input reset,
    inout sensor,
    output reg [7:0] T_integral,
    output reg [7:0] RH_integral,
    output reg [7:0] T_decimal,
    output reg [7:0] RH_decimal,
    output reg [7:0] Checksum,
    output reg data_valid
);

    initial begin
        T_integral = 0;
        RH_integral = 0;
        T_decimal = 0;
        RH_decimal = 0;
        Checksum = 0;
        data_valid = 0;
    end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

localparam SEND_LOW =3'b000 , SEND_HIGH =3'b001 ,REC_LOW = 3'b010, REC_HIGH =3'b011 , PWM_LOW =3'b100 , PWM_HIGH =3'b101 , CHECKSUM_UPDATE =3'b110;

reg [2:0] state;
reg [19:0] counter;  // max 9,00,000
reg [0:39] data;      // 40 bits data
reg [5:0] pointer;    // max 39

reg sensor_rg;

assign sensor = sensor_rg;
reg clk_stablized = 0;

initial begin
	pointer = 0;
end

always @(posedge clk_50M or negedge reset)begin
	if (!reset) state <= SEND_LOW;
	else begin
		case (state) 
			SEND_LOW: state <= (counter >= 900004) ? SEND_HIGH : state;
			SEND_HIGH: state <= (counter >= 1999) ? REC_LOW : state;
			REC_LOW: state <= (counter >= 3999) ? REC_HIGH : state;
			REC_HIGH: state <= (counter >= 3999) ? PWM_HIGH : state;
			PWM_HIGH: state <= (sensor !== 1 && pointer == 40) ? CHECKSUM_UPDATE : state; 
			CHECKSUM_UPDATE:  state <= (counter == 1) ? SEND_LOW : state;
		endcase
	end
end

always @(posedge clk_50M or negedge reset)begin
	if (!reset) begin
		pointer <= 0;
		counter <= 0;
		clk_stablized <= 1;
	end else if (!clk_stablized) begin
		clk_stablized <= 1;
	end else begin
		if (state == SEND_LOW) begin
			data_valid <= 0;
			if (counter >= 900004) counter <= 0;
			else begin
				sensor_rg <= 0;
				counter <= counter + 1;
			end
		end
		if (state == SEND_HIGH) begin
			if (counter >= 1999)begin
				counter <= 0;
				sensor_rg <= 1'bz;
			end
			else begin
				sensor_rg <= 1;
				counter <= counter + 1;
			end
		end
		if (state == REC_LOW) begin
			if (counter >= 3999) counter <= 0;
			else counter <= counter + 1;
		end
		if (state == REC_HIGH) begin
			if (counter >= 3999) counter <= 0;
			else counter <= counter + 1;
		end
		if (state == PWM_HIGH) begin
			if (sensor == 1) counter <= counter + 1;
			else if (sensor !== 1  && counter > 1200) begin
				if (counter >= 3400) begin
					data[pointer] <= 1;
					pointer <= pointer + 1;
					counter <= 0;
				end
				else begin
					data[pointer] <= 0;
					pointer <= pointer + 1;
					counter <= 0;
				end
			end
		end
		if (state == CHECKSUM_UPDATE) begin
			// counter logic to add custom delay of 1 cycle in testbench
			pointer <= 0;
			if ((data[0:7] + data[8:15] + data[16:23] + data[24:31]) == data[32:39]  && counter == 1)begin
				data_valid <= 1;
				RH_integral <= data[0:7];
				RH_decimal <= data[8:15];
				T_integral <= data[16:23];
				T_decimal <= data[24:31];
				Checksum <= data[32:39];
				counter <= 0;
			end
			else counter <= counter + 1;
		end
	end
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////
  
endmodule
