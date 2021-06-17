

module uart (input CLK, output TX, input[7:0] data_in, input wren, input rst, output full, output[5:0] fill_lvl );

wire empty; 
wire cts;
wire[7:0] data_out;
wire[4:0] fifo_fill_lvl;
wire tx_active;

uart_tx d0(.CLK(CLK), .TX(TX), .rts(~empty), .cts(cts), .data(data_out), .rst(rst), .tx_active(tx_active));
/* verilator lint_off PINCONNECTEMPTY */
uart_fifo d1(.CLK(CLK), .empty(empty), .rden(cts), .wren(wren), .data_in(data_in), .data_out(data_out), .rst(rst), .full(full), .fill_lvl(fifo_fill_lvl));
/*lint_on*/

assign fill_lvl = {1'b0, fifo_fill_lvl} + {4'b0, tx_active};

endmodule
