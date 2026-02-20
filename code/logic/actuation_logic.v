module actuation_logic (
    input clk,
    input [2:0] move,
    input [3:0] delta_speed,
    output pwma,
    output pwmb,
    output in1,
    output in2,
    output in3,
    output in4,
	 output clk_3125KHz
);

// 3125Khz clk 
wire clk_195KHz;
reg [3:0] dutya;
reg [3:0] dutyb;
reg in1_reg;
reg in2_reg;
reg in3_reg;
reg in4_reg;

assign in1 = in1_reg;
assign in2 = in2_reg;
assign in3 = in3_reg;
assign in4 = in4_reg;

initial begin
   dutya = 0;
   dutyb = 0;
   in1_reg = 0;
   in2_reg = 0;
   in3_reg = 0;
   in4_reg = 0;
end

frequency_scaling fs (
    .clk_50M(clk),
    .clk_3125KHz(clk_3125KHz)
);

pwm_generator pwa (
    .clk_3125KHz(clk_3125KHz),
    .duty_cycle(dutya),
    .clk_195KHz(clk_195KHz),
    .pwm_signal(pwma)
);

pwm_generator pwb (
    .clk_3125KHz(clk_3125KHz),
    .duty_cycle(dutyb),
    .clk_195KHz(),
    .pwm_signal(pwmb)
);

// TODO :
// blind turn le using encoder motors 90 deg ka and follow the wall which is present till another wall appear then go to normal logic 
// aur agar turn trigger hua hai toh around 10 value ko debouce kr due to mayble faulty reading agar fir bhi turn hai then initate turn
always @(posedge clk_195KHz) begin
    case (move)
        3'b000: begin
            dutya = 0;
            dutyb = 0;
            in1_reg = 0;
            in2_reg = 0;
            in3_reg = 0;
            in4_reg = 0;
        end
        3'b001: begin
            in1_reg = 1;
            in2_reg = 0;
            in3_reg = 1;
            in4_reg = 0;
            dutya = 8 + 2 * delta_speed[3:0] ;
            dutyb = 8 - 2 * delta_speed[3:0] ;
        end
        3'b010: begin
            in1_reg = 1;
            in2_reg = 0;
            in3_reg = 0;
            in4_reg = 1;
            dutya = 8;
            dutyb = 8;
        end
        3'b011: begin
            in1_reg = 0;
            in2_reg = 1;
            in3_reg = 1;
            in4_reg = 0;
            dutya = 8;
            dutyb = 8 ;
        end
        3'b100: begin
            in1_reg = 1;
            in2_reg = 0;
            in3_reg = 0;
            in4_reg = 1;
            dutya = 8 ;
            dutyb = 8 ;
        end
		  3'b101: begin
				in1_reg = 1;
				in2_reg = 0;
				in3_reg = 1;
				in4_reg = 0;
				dutya = 8 ;
				dutyb = 8 ;
		  end
        default: begin
            in1_reg = 0;
            in2_reg = 0;
            in3_reg = 0;
            in4_reg = 0;
            dutya = 0;
            dutyb = 0;
        end
    endcase
end

endmodule