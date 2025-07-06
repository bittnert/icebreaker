
module alu(input[31:0] a,
           input[31:0] b,
           output reg[31:0] result,
           input [2:0] op,
           input aux);

    wire signed [31:0] signed_a = a;
    wire signed [31:0] signed_b = b;

    always @(*) begin
        case (op[2:0])
            `ALU_ADD: begin
                if (aux == 1'b1) begin 
                    result = a - b;
                end else
                    result = a + b;
            end
            `ALU_SLL: begin
                result = a << b[4:0];
            end
            `ALU_SLT: begin
                result = (signed_a < signed_b) ? 32'b1: 32'b0;
            end
            `ALU_SLTU: begin
                result = (a < b) ? 32'b1: 32'b0;
            end
            `ALU_XOR: begin
                result = a ^ b;
            end
            `ALU_SRL: begin
                if (aux == 1'b1) begin 
                    result = signed_a >>> b[4:0];
                end else 
                    result = a >> b[4:0];
            end
            `ALU_OR: begin
                result = a | b;
            end
            `ALU_AND: begin
                result = a & b;
            end
        endcase
    end
endmodule
