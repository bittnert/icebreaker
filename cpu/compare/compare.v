
module compare(input [31:0] a,
               input [31:0] b,
               input [2:0] operation,
               output reg result);

    wire signed [31:0] signed_a, signed_b;

    assign signed_a = a;
    assign signed_b = b;

    always @(*) begin
        case (operation) 
            `COMPARE_EQ: begin
                result = (a == b)? 1'b1 : 1'b0;
            end
            `COMPARE_NE: begin
                result = (a!= b)? 1'b1 : 1'b0;
            end
            `COMPARE_LT: begin
                result = (signed_a < signed_b)? 1'b1 : 1'b0;
            end
            `COMPARE_GE: begin
                result = (signed_a >= signed_b)? 1'b1 : 1'b0;
            end
            `COMPARE_LTU: begin
                result = (a < b)? 1'b1 : 1'b0;
            end
            `COMPARE_GEU: begin
                result = (a >= b)? 1'b1 : 1'b0;
            end
            default: begin
                result = 1'b0;
            end
        endcase
    end

endmodule
