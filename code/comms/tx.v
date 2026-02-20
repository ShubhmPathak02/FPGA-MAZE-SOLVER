module tx(
    input clk_3125,
    input parity_type, tx_start,
    input [7:0] data,
    output reg tx, tx_done
);

    initial begin
        tx = 1'b1;
        tx_done = 1'b0;
    end

    localparam INIT=3'b000, START_BIT=3'b001, DATA_BIT= 3'b010, PARITY_BIT=3'b011, STOP_BIT= 3'b100;

    reg [2:0] state = INIT;
    reg [4:0] counter = 0;
    reg [2:0] pointer = 0;

    always @ (posedge clk_3125) begin
        case (state)
            INIT:       if (tx_start) state <= START_BIT;
            START_BIT:  if (counter >= 26) state <= DATA_BIT;
            DATA_BIT:   if (pointer == 7 && counter >= 26) state <= PARITY_BIT;
            PARITY_BIT: if (counter >= 26) state <= STOP_BIT;
            STOP_BIT:   if (counter >= 26) state <= INIT;
            default:    state <= INIT;
        endcase
    end

    always @ (posedge clk_3125) begin
        if (state == INIT) begin
            counter <= 0;
            pointer <= 0;
            tx <= 1'b1;
            tx_done <= 1'b0;
        end else begin
            if (counter >= 26) begin
                counter <= 0;
                if (state == DATA_BIT) pointer <= pointer + 1;
                if (state == STOP_BIT) tx_done <= 1'b1;
            end else begin
                counter <= counter + 1;
            end

            // Control TX line
            case (state)
                START_BIT:  tx <= 1'b0;
                DATA_BIT:   tx <= data[pointer]; // LSB First
                PARITY_BIT: tx <= (parity_type == 0) ? (^data) : ~(^data);
                STOP_BIT:   tx <= 1'b1;
            endcase
        end
    end
endmodule