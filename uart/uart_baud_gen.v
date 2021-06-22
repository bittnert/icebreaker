/*Verilator lint_off UNUSED*/
/*Verilator lint_off UNDRIVEN*/
module uart_baud_gen#(parameter WIDTH=21)(input CLK, input rst_n, output baud_tick, input[WIDTH-1:0] prescaler);

	reg[WIDTH-1:0] counter;
	reg[WIDTH-1:0] limit;

	always @(posedge CLK) begin
		if (rst_n == 0) begin
			counter <= 0;
			limit <= prescaler;
		end else begin
			if (counter == limit) begin
				counter <= 0;
				limit <= prescaler;
			end else begin
				counter <= counter + 1;
			end
		end

	end

	assign baud_tick = (counter == limit);

endmodule
