module mazesolver (
    input clk,
    input l_echo,
    input r_echo,
    input f_echo,
    input l_ir,
    input m_ir,
    input r_ir,
    output l_ir_obs,
    output m_ir_obs,
    output r_ir_obs,
    output l_trig,
    output r_trig,
    output f_trig,
    output pwma,
    output pwmb,
    output in1,
    output in2,
    output in3,
    output in4,
    output l_op,
    output r_op,
    output f_op,
   output [20:0] l_dist,  
   output [20:0] r_dist,
   output [20:0] f_dist,
	output [2:0] move,
	output [3:0] delta_speed,
	output clk_3125,
	input rx,
	output tx,
    input mtr_quad_A,         
    input mtr_quad_B,
    input mtl_quad_A,         
    input mtl_quad_B
    // output [31:0] distanceA, 
    // output [31:0] distanceB 
);

// Internal signals
wire rst_n = 1;
wire rst_n_m  = 1;
//wire [2:0] move;
//wire [3:0] delta_speed;
wire [31:0] distanceA;
wire [31:0] distanceB;

//wire [20:0] l_dist,f_dist,r_dist;

ble hc05(
    .clk_50M(clk),     
    .rx(rx),           
    .l_op(l_ir_obs),         
    .r_op(r_ir_obs),         
    .f_op(m_ir_obs),         
    .tx(tx)        
);

encoder mtrR (
    .clk(clk),
    .quadA(mtr_quad_A),         
    .quadB(mtr_quad_B),         
    .rst_n(rst_n_m),         
    .count(distanceA)   
);
encoder mtrL (
    .clk(clk),
    .quadA(mtl_quad_A),         
    .quadB(mtl_quad_B),         
    .rst_n(rst_n_m),         
    .count(distanceB)   
);

ir ir_left (
		.clk(clk),
		.rst_n(rst_n),
    .signal(l_ir),
    .obstacle(l_ir_obs)
);

ir ir_mid (
	.clk(clk),
	.rst_n(rst_n),
    .signal(m_ir),
    .obstacle(m_ir_obs)
);

ir ir_right (
	.clk(clk),
	.rst_n(rst_n),
    .signal(r_ir),
    .obstacle(r_ir_obs)
);

// Left ultrasonic sensor
ultrasonic u_left (
    .clk_50M(clk),
    .reset(rst_n),
    .echo_rx(l_echo),
    .trig(l_trig),
    .op(l_op),
    .distance_out(l_dist),
);

// Right ultrasonic sensor
ultrasonic u_right (
    .clk_50M(clk),
    .reset(rst_n),
    .echo_rx(r_echo),
    .trig(r_trig),
    .op(r_op),
    .distance_out(r_dist),
);

// Front ultrasonic sensor
ultrasonic u_front (
    .clk_50M(clk),
    .reset(rst_n),
    .echo_rx(f_echo),
    .trig(f_trig),
    .op(f_op),
    .distance_out(f_dist),
);

// Maze solver logic
solver s (
    .clk(clk),
    .rst_n(rst_n),
    .left(l_op),
    .mid(f_op),
    .right(r_op),
	 .ira(l_ir_obs),
	 .irb(m_ir_obs),
	 .irc(r_ir_obs),
    .distanceA(distanceA),
    .distanceB(distanceB),
    .move(move)
);

// PID centering controller
pid_centering pc (
    .clk(clk),
    .l_dist(l_dist),
    .r_dist(r_dist),
    .delta_speed(delta_speed)
);

// Motor actuation logic
actuation_logic al (
    .clk(clk),
    .move(move),
    .delta_speed(delta_speed),
    .pwma(pwma),
    .pwmb(pwmb),
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .in4(in4),
	 .clk_3125KHz(clk_3125)
);

endmodule