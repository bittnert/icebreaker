
module memory_wrapper #(parameter SIZE=3) (
    input CLK,
    input [31:0] data_in,
    output [31:0] data_out,
    input wr_rd,
    input en,
    input [SIZE + 2: 0] addr,
    input [1:0] size,
    output exception_out
);

wire [31:0] data;

//assign data_out = data;
assign data = (en && wr_rd) ? data_in : 32'bz;
assign data_out = data;
//assign data = (!wr_rd && en)? 32'bz : data_in;

memory #(.SIZE(SIZE)) d0(
    .CLK(CLK), 
    .data(data), 
    .wr_rd(wr_rd), 
    .en(en), 
    .addr(addr), 
    .size(size), 
    .exception_out(exception_out)
    );
/*
always @ (posedge CLK) begin
    if (!wr_rd && en) begin
        data_out <= data;
    end
end
*/

endmodule
