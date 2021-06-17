

module uart_test (input CLK, output TX, input BTN_N );

wire empty; 
wire cts;
wire rst;
wire[7:0] data_out;
wire[7:0] data_in;
wire wren;
wire full;

reg[3:0] rd_p;
reg[7:0] mem[13:0];



always @(posedge CLK or negedge BTN_N ) begin
	if (~BTN_N) begin
		rd_p <= 0;
		mem[0] <= 'h48; //H
		mem[1] <= 'h65; //e
		mem[2] <= 'h6C; //l
		mem[3] <= 'h6C; //l
		mem[4] <= 'h6F; //o
		mem[5] <= 'h20; //<space>
		mem[6] <= 'h57; //W
		mem[7] <= 'h6F; //o
		mem[8] <= 'h72; //r
		mem[9] <= 'h6C; //l
		mem[10] <= 'h64; //d
		mem[11] <= 'h21; //!
		mem[12] <= 'h0D; //\r
		mem[13] <= 'h0A; //\n
	end else	
	if (~full) begin
		if (rd_p == 13) begin
			rd_p <= 0;
		end else begin
			rd_p <= rd_p + 1;
		end
	end 
end


/* verilator lint_off PINCONNECTEMPTY */
uart_tx d0(.CLK(CLK), .TX(TX), .rts(~empty), .cts(cts), .data(data_out), .rst(rst), .tx_active());
uart_fifo d6(.datain(data_in), .rd(cts), .wr(wren), .clk(CLK), .dataout(data_out), .rst(BTN_N),  .full(full), .empty(empty));
//uart_fifo d1(.CLK(CLK), .empty(empty), .rden(cts), .wren(wren), .data_in(data_in), .data_out(data_out), .rst(rst), .full(full));
/*lint_on*/
assign wren = 1;
assign data_in = mem[rd_p];
assign rst = ~BTN_N;
endmodule
