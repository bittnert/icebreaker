

module timer(input CLK,
            input rst,
            output [31:0] counter_out);

reg [31:0] counter;

always @ (posedge CLK) begin
    if (rst == 1'b0) begin
        counter <= 0;
    end else begin
        counter <= counter + 1;
    end
end

assign counter_out = counter;

endmodule
