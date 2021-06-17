/******************************************************
A fifo controller verilog description.
******************************************************/
module uart_fifo #(parameter WIDTH = 8, parameter DEPTH = 16)
			(input[WIDTH - 1:0] datain, 
			input rd, 
			input wr, 
			input rst, 
			input clk, 
			output[WIDTH - 1:0] dataout, 
			output full, 
			output empty);
reg[WIDTH - 1:0] temp;
reg full_in, empty_in;
reg [WIDTH - 1:0] mem [DEPTH - 1:0];
reg [$clog2(DEPTH) - 1:0] rp, wp;
assign full = full_in;
assign empty = empty_in;
// memory read out
//assign dataout = mem[rp];
assign dataout = temp;
always@(posedge clk)
begin
	temp <= mem[rp];
end
// memory write in
always@(posedge clk) begin
    if(wr && ~full_in) mem[wp]<=datain;
end
// memory write pointer increment
always@(posedge clk or negedge rst) begin
    if(!rst) wp<=0;
    else begin
      if(wr && ~full_in) wp<= wp+1'b1;
    end
end
// memory read pointer increment
always@(posedge clk or negedge rst)begin
    if(!rst) rp <= 0;
    else begin
      if(rd && ~empty_in) rp <= rp + 1'b1;
    end
end
// Full signal generate
always@(posedge clk or negedge rst) begin
    if(!rst) full_in <= 1'b0;
    else begin
      if( (~rd && wr)&&((wp==rp-1)||(rp==4'h0&&wp==4'hf)))
          full_in <= 1'b1;
      else if(full_in && rd) full_in <= 1'b0;
    end
end
// Empty signal generate
always@(posedge clk or negedge rst) begin
    if(!rst) empty_in <= 1'b1;
    else begin
      if((rd&&~wr)&&(rp==wp-1 || (rp==4'hf&&wp==4'h0)))
        empty_in<=1'b1;
      else if(empty_in && wr) empty_in<=1'b0;
    end
end
endmodule
