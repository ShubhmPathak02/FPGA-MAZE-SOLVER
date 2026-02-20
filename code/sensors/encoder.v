module encoder (
    input wire clk,
    input wire quadA,         
    input wire quadB,         
    input wire rst_n,         
    output reg [31:0] count   
);

    reg [2:0] syncA, syncB;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syncA <= 3'b000;
            syncB <= 3'b000;
        end else begin
            syncA <= {syncA[1:0], quadA};
            syncB <= {syncB[1:0], quadB};
        end
    end

    // Current state syncX[1], previous syncX[2]
    wire count_enable = syncA[1] ^ syncA[2] ^ syncB[1] ^ syncB[2];
    wire count_direction = syncA[1] ^ syncB[2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
        end else if (count_enable) begin
            if (count_direction)
                count <= count + 1;
            else
                count <= count - 1;
        end
    end

endmodule