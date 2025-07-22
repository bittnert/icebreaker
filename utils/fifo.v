

module fifo #(parameter WIDTH = 8, parameter DEPTH = 16)
    (input[WIDTH - 1:0] datain,
    input wr_in,
    output [WIDTH - 1:0] dataout,
    input rd_in,
    input CLK,
    input rst_in,
    output full_out,
    output empty_out,
    output [$clog2(DEPTH) - 1:0] fill_lvl_out);

    //reg empty;
    (* ram_style = "block" *) reg [WIDTH - 1:0] data [DEPTH - 1:0];
    reg [$clog2(DEPTH) - 1:0] rp, wp;
    reg [WIDTH - 1:0] dataout_reg;
    
    //assign full_out = full;
    assign empty_out = wp == rp;
    assign fill_lvl_out = wp - rp;
    assign full_out = (wp + 1 == rp) || (wp == 4'hF && rp == 0);

    // write data
    always @(posedge CLK) begin
        if (wr_in && ~full_out) begin 
            data[wp] <= datain;
        end
    end

    assign dataout = dataout_reg;

    // read data
    always @(posedge CLK) begin
        //if (rd_in && ~empty_out) begin
        if (~empty_out)
            dataout_reg <= data[rp];
        else
            dataout_reg <= datain;
        //end
    end
    

    // This reduces the read latency by 1 clock cycle, but might make usage of Block RAMS impossible.
    // Handle read pointer
    always @(posedge CLK) begin
        if (~rst_in) begin
            rp <= 0;
        end
        else begin
            if (rd_in && ~empty_out) rp <= rp + 1;
        end
    end

    //Handle write pointer
    always @(posedge CLK) begin
        if (~rst_in)
            wp <= 0;
        else if (wr_in && full_out == 0) wp <= wp + 1;
    end

endmodule
