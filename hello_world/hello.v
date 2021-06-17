/* Simple hello world project which blinks an LED */


module hello ( input CLK, output LEDR_N);
	
	reg [32:0] counter = 0;
	
	localparam half_period = 12000000;

	always @(posedge CLK) begin
		if (counter == half_period)
			counter <= 0;
		else
			counter <= counter + 1;
	end
	
	assign LEDR_N = (counter > half_period/2) ? 0 : 1;
	
endmodule 

