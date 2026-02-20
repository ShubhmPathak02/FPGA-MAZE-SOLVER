module pcb (
    input clk,
    input [15:0] l_dist,
    input [15:0] r_dist,
    output [7:0] delta_speed
);

localparam Kp = 1, Ki= 0.1, Kd=0.6;

reg [15:0] sum;
reg [7:0] delta_speed_ref;
assign delta_speed = delta_speed_ref;

reg [15:0] error;
reg [15:0] last_error;
reg [2:0] pid;

initial begin
    error = l_dist - r_dist;
    last_error = 0;
    sum = 0;
end

// pid = kp* error + kd* de/dt + ki* E edt
// TODO : 
// issue is pd cant be a fucking decimal fix it
always @(posedge clk) begin
    error = l_dist - r_dist;
    pid = 255*((Kp*error) + (Kd * (error - last_error)/0.000000020) + Ki * sum) / (error + ((error - last_error)/0.000000020) + sum);
    delta_speed_ref = pid;
    // keep check for overflow of sum 
    sum = sum >= 65000 ? sum : sum + error;
end

endmodule

