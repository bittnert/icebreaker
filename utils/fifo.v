

module fifo #(parameter WIDTH = 8, parameter DEPTH = 16)
    (input[WIDTH - 1:0] datain,
    input wr_in,
    output reg[WIDTH - 1:0] dataout,
    input rd_in,
    input CLK,
    input rst_in,
    output full_out,
    output empty_out,
    output [$clog2(DEPTH) - 1:0] fill_lvl_out);

    //reg empty;
    reg [WIDTH - 1:0] data [DEPTH - 1:0];
    reg [$clog2(DEPTH) - 1:0] rp, wp;

    
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

    assign dataout = data[rp];

    // read data
    //always @(posedge CLK) begin
    //    if (rd_in && ~empty_out) begin
    //        dataout <= data[rp];
    //    end
    //end


    // This reduces the read latency by 1 clock cycle, but might make usage of Block RAMS impossible.
//    assign dataout = data[rp];
    // Handle read pointer
    always @(posedge CLK) begin
        if (~rst_in) begin
            rp <= 0;
        end
        else begin
            if (rd_in && ~empty_out) rp <= rp + 1;
        end
    end
/*
    always @(posedge CLK) begin
        if (rp == wp) empty <= 1'b1;
        else empty <= 1'b0;
    end 
*/

    //Handle write pointer
    always @(posedge CLK) begin
        if (~rst_in)
            wp <= 0;
        else if (wr_in && full_out == 0) wp <= wp + 1;
    end
/*
    always @(posedge CLK) begin
        // if wp pointer is right behind read pointer, we are full
        //if (wp + 1 == rp || (wp == $clog2(DEPTH)'(DEPTH - 1) && rp == 0))  // wrap around) 
        if (wp + 1 == rp || (wp == 4'hF && rp == 0))  // wrap around) 
            full <= 1'b1;
        // If we are full and we are reading, we are no longer full => check if this is correct/needed, especially with 
        // the case if we write at the same time.
        else if (full && rd_in) full <= 1'b0;
    end
    */





endmodule
