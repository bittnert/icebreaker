module uart_rx (input CLK, input rst_n, output reg rx_ready, output reg[7:0] rx_data, input[20:0] prescaler_in, input RX, output reg framing_error);

	localparam
		ST_IDLE = 2'b00,
		ST_START = 2'b01,
		ST_RX = 2'b10,
		ST_STOP = 2'b11;

	reg[20:0] prescaler_out;
	reg[20:0] prescaler;
	reg[7:0] data;
	reg[3:0] data_count;
	reg rx_sync[2:0];
	reg last_rx;
	reg rst_out;
	reg[1:0] state;
	wire baud_tick;

uart_baud_gen baud_gen(.CLK(CLK), .rst_n(rst_out), .prescaler(prescaler_out), .baud_tick(baud_tick));

	always @(posedge CLK) begin
		if (rst_n == 1'b0) begin
			state <= ST_IDLE;
			rst_out <= 0;
		end else begin
			case (state)
				ST_IDLE: begin
					/*Detect falling edge of RX signal*/
					if (last_rx == 1'b1 && rx_sync[0] == 1'b0) begin
						rst_out <= 1'b1;	
						state <= ST_START;
						data <= 8'b0;
						data_count <= 0;
					end else begin
						rst_out <= 1'b0;
					end

					rx_ready <= 1'b0;
					/*First prescaler setting set to half to get start state into the middle
					of the start bit*/
					framing_error <= 0;
					prescaler_out <= {1'b0, prescaler_in[20:1]};
					prescaler <= prescaler_in;
					last_rx <= rx_sync[0];
				end 
				ST_START: begin
					prescaler_out <= prescaler;
					if (baud_tick == 1'b1) begin
						if (rx_sync[0] == 1'b0) begin
							state <= ST_RX;
						end else begin
							/*Framing error as Start bit is not 0*/
							framing_error <= 1;
							state <= ST_IDLE;
						end
					end

				end
				ST_RX: begin
					if (baud_tick == 1'b1) begin
						//data <= {data[6:0],rx_sync[0]};
						data <= {rx_sync[0],data[7:1]};
						data_count <= data_count + 1;
					end

					if(data_count == 8) begin
						state <= ST_STOP;
					end;
				end
				ST_STOP: begin
					if (baud_tick == 1'b1) begin
						if (rx_sync[0] == 1'b0) begin
							/*Framing error as stop bit was not detected*/
							framing_error <= 1;
						end else begin
							rx_data <= data;
							rx_ready <= 1'b1;
						end
						state <= ST_IDLE;
					end
				end
			endcase
		end
	end

	/*Synchronize the asynchronize RX signal using 3 registers.*/
	always @(posedge CLK) begin
		rx_sync[0] <= rx_sync[1];
		rx_sync[1] <= rx_sync[2];
		rx_sync[2] <= RX;
	end

endmodule

