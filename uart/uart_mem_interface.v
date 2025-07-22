
module uart_mem_interface (
    input CLK,
    input [1:0]       addr,
    input [31:0]      data_in,
    output reg [31:0] data_out,
    input             reset,
    input en,
    input wr,
    output TX,
    input RX
);

    wire loc_wren, loc_rden;
    wire tx_full, rx_empty; 
    wire [5:0] tx_fill_lvl, rx_fill_lvl;
    wire [7:0] uart_data_out;
    reg [7:0] uart_data_in;
    reg [31:0] data_out_reg;
    reg [7:0]  uart_data_in_reg;

    assign loc_rden = (en && !wr && addr == 2'b01);
    assign loc_wren = (en && wr  && addr == 2'b01);


    uart uart ( .CLK(CLK), 
                .TX(TX),
                .RX(RX), 
                .data_in(data_in[7:0]), 
                .data_out(uart_data_out), 
                .rden(loc_rden), 
                .wren(loc_wren), 
                .rst(reset), 
                .tx_full(tx_full), 
                .rx_empty(rx_empty), 
                .tx_fill_lvl(tx_fill_lvl), 
                .rx_fill_lvl(rx_fill_lvl));

    always @(posedge CLK ) begin
        if (reset == 1'h0) begin
            data_out_reg <= 32'b0;
        end else begin
            case (addr)
                2'b00: data_out_reg <= {tx_full, rx_empty, 18'b0, tx_fill_lvl, rx_fill_lvl};
                2'b01: data_out_reg <= {24'b0, uart_data_out};
                default: data_out_reg <= 32'b0;
            endcase
        end
    end

    always @(*) begin
        data_out = data_out_reg;
    end
endmodule
