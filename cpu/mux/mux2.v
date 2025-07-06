
module mux2#(SIZE=32)(input[SIZE - 1:0] a
                    , input[SIZE-1:0] b
                    , output reg[SIZE-1:0] result
                    , input sel
                    );


    always @(*) begin
        if (sel == 1) begin
            result = a;
        end else begin
            result = b;
        end
    end
endmodule
