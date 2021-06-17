
module uart_tx(input CLK, input rst, output TX, input [7:0] data, input rts, output cts, output tx_active);

	localparam
		ST_IDLE = 2'b00,
		ST_START = 2'b01,
		ST_TX = 2'b10,
		ST_STOP = 2'b11;

	reg [1:0] tx_state = ST_IDLE;
	reg [7:0] tx_data;
	reg [7:0] tx_count;
	reg [31:0] counter;
	reg baud_tick;
	reg int_cts;

	always @(posedge CLK)
	begin
		if (counter == 104 ) begin
			baud_tick <= 1;
			counter <= 0;
		end else begin	
			baud_tick <= 0;
			counter <= counter + 1;
		end
	end
	always @(posedge CLK, posedge rst) begin
		if (rst == 1'b1) begin
			tx_state <= ST_IDLE;
		end else begin
			case (tx_state)
				ST_IDLE: begin
					if (rts == 1 && baud_tick == 1'b1) begin
						tx_state <= ST_START;
						tx_data <= data;
						tx_count <= 0;
					end
				end
				ST_START: begin
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
					end
				end
			endcase
		end

		
	end
	
	always @(posedge CLK) begin
		if ((rts == 1) && (baud_tick == 1'b1) && tx_state == ST_IDLE) begin
			int_cts <= 1;
		end else begin
			int_cts <= 0;
		end
	end

	assign cts = int_cts;
	//assign cts = (tx_state == ST_IDLE);
	assign TX = ((tx_state == ST_IDLE) | (tx_state == ST_STOP) | (tx_data[0])) & (tx_state != ST_START);
	assign tx_active = (tx_state != ST_IDLE);

endmodule
