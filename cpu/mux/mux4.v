
module mux4#(parameter SIZE=32)(input[SIZE - 1:0] a
                    , input[SIZE-1:0] b
                    , input[SIZE-1:0] c
                    , input[SIZE-1:0] d
                    , output reg[SIZE-1:0] result
                    , input[1:0] sel
                    );


    always @(*) begin
        case (sel)
            0: result = a;
            1: result = b;
            2: result = c;
            3: result = d;
        endcase 
    end
endmodule
