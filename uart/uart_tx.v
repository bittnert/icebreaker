module uart_tx(input CLK, input rst_n, output TX, input [7:0] data, input tx_start, output tx_ready, output tx_active, input[20:0] prescaler_in);

	localparam
		ST_IDLE = 2'b00,
		ST_START = 2'b01,
		ST_TX = 2'b10,
		ST_STOP = 2'b11;

	reg [1:0] tx_state = ST_IDLE;
	reg [7:0] tx_data;
	reg [4:0] tx_count;
	reg [20:0] prescaler;
	reg rst_out;
	reg baud_tick;
	reg int_tx_ready;

uart_baud_gen baud_gen(.CLK(CLK), .rst_n(rst_out), .prescaler(prescaler), .baud_tick(baud_tick));

	always @(posedge CLK) begin
		if (rst_n == 1'b0) begin
			tx_state <= ST_IDLE;
			rst_out <= 0;
		end else begin
			case (tx_state)
				ST_IDLE: begin
/*
					if (tx_start == 1 && baud_tick == 1'b1) begin
						tx_state <= ST_START;
						tx_data <= data;
						tx_count <= 0;
					end
*/
					if (tx_start == 1) begin
						tx_state <= ST_START;
						tx_data <= data;
						tx_count <= 0;
						rst_out <= 1;
						int_tx_ready <= 0;
					end else begin
						rst_out <= 0;
						int_tx_ready <= 1;
					end
					prescaler <= prescaler_in;
				end
				ST_START: begin
					int_tx_ready <= 0;
					if (baud_tick == 1'b1) begin
						tx_state <= ST_TX;
					end
				end
				ST_TX: begin
					if (baud_tick == 1'b1) begin
						tx_data <= tx_data >> 1;
						tx_count <= tx_count + 1;
					end

					if (tx_count == 7 && baud_tick == 1'b1) begin
						tx_state <= ST_STOP;
					end
				end
				ST_STOP: begin
					if (baud_tick == 1'b1) begin
						tx_state <= ST_IDLE;
						int_tx_ready <= 1;
					end
				end
			endcase
		end

		
	end
	

	assign tx_ready = int_tx_ready;
	//assign tx_ready = (tx_state == ST_IDLE);
	assign TX = ((tx_state == ST_IDLE) | (tx_state == ST_STOP) | (tx_data[0])) & (tx_state != ST_START);
	assign tx_active = (tx_state != ST_IDLE);

endmodule
