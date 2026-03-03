
module mtime(input CLK,
            input rst_n,
            input wr_en,
            input [1:0] addr,
            output irq,
            output reg[31:0] data_out,
            input [31:0] data_in);

reg[63:0] counter;
reg[63:0] compare;

always @(posedge CLK) begin
    if (!rst_n) begin
        counter <= 0;
        compare <= 64'hFFFFFFFFFFFFFFFF; // set really high so no interrupt is triggered after reset
    end else begin
        counter <= counter + 1;
        if (wr_en) begin
            case (addr)
                2'b00: counter[31:0] <= data_in;
                2'b01: counter[63:32] <= data_in;
                2'b10: compare[31:0] <= data_in;
                2'b11: compare[63:32] <= data_in;
            endcase
        end
    end
end

always @(posedge CLK) begin
    case (addr)
        2'b00: data_out <= counter[31:0];
        2'b01: data_out <= counter[63:32];
        2'b10: data_out <= compare[31:0];
        2'b11: data_out <= compare[63:32];
    endcase
end

assign irq = (counter >= compare) ? 1'b1 : 1'b0;

endmodule
