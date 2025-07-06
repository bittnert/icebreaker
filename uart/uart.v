

module uart (input CLK, 
             output TX, 
             input RX,
             input[7:0] data_in, 
             output[7:0] data_out, 
             input rden,
             input wren, 
             input rst, 
             output tx_full, 
             output rx_empty,
             output[5:0] tx_fill_lvl,
             output[5:0] rx_fill_lvl );

wire empty; 
wire rx_ready;
wire[7:0] tx_data;
wire [7:0] rx_data;
wire[3:0] tx_fifo_fill_lvl;
wire[3:0] rx_fifo_fill_lvl;
wire tx_active;
wire tx_ready;
wire framing_error;
uart_tx d0(.CLK(CLK), .TX(TX) , .data(tx_data), .rst_n(rst), .tx_active(tx_active), .tx_start(~empty), .prescaler_in(1301), .tx_ready(tx_ready));
/* verilator lint_off PINCONNECTEMPTY */
fifo tx_fifo(.CLK(CLK), .datain(data_in), .wr_in(wren), .rd_in(tx_ready), .empty_out(empty), .dataout(tx_data), .rst_in(rst), .fill_lvl_out(tx_fifo_fill_lvl), .full_out(tx_full) );
/*lint_on*/

assign tx_fill_lvl = {1'b0, tx_fifo_fill_lvl} + {4'b0, tx_active};
assign rx_fill_lvl = {1'b0, rx_fifo_fill_lvl} + {4'b0, framing_error};

uart_rx d1(.CLK(CLK), .rst_n(rst), .rx_ready(rx_ready), .rx_data(rx_data), .prescaler_in(1301), .RX(RX), .framing_error(framing_error));

fifo rx_fifo(.CLK(CLK), .datain(rx_data), .wr_in(rx_ready), .rd_in(rden), .empty_out(rx_empty), .dataout(data_out), .rst_in(rst), .fill_lvl_out(rx_fifo_fill_lvl), .full_out());

endmodule
