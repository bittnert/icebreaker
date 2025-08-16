
module alu(input[31:0] a,
           input[31:0] b,
           output reg[31:0] result,
           input [2:0] op,
           input aux,
           input clk);

    wire signed [31:0] signed_a = a;
    wire signed [31:0] signed_b = b;

    reg [31:0] add_result, sub_result, shl_result, shr_result;
    reg [31:0] or_result, xor_result, and_result, slt_result, sltu_result;
    reg [31:0] srl_result, sra_result;
    reg [2:0] last_op;
    reg last_aux;

    //dsp32_addsub #(.REGISTER_OUTPUT(1)) dsp(.clk(clk), .add_sub(aux), .a(a), .b(b), .y(add_result));

    always @(posedge clk) begin
        shl_result <= a << b[4:0];
        or_result <= a | b;
        xor_result <= a ^ b;
        and_result <= a & b;
        slt_result <= (signed_a < signed_b) ? 32'b1 : 32'b0;
        sltu_result <= (a < b) ? 32'b1: 32'b0;
        srl_result <= a >> b[4:0];
        sra_result <= signed_a >>> b[4:0];
        last_op <= op;
        last_aux <= aux;
        add_result <= a + b;
        sub_result <= a - b;
    end

    always @(*) begin

        //add_result = a + b;

        case (last_op[2:0])
            `ALU_ADD: begin
                if (last_aux == 1'b1) begin 
                    result = sub_result;
                end else
                    result = add_result;
            end
            `ALU_SLL: begin
                result = shl_result;
            end
            `ALU_SLT: begin
                result = slt_result;
            end
            `ALU_SLTU: begin
                result = sltu_result;
            end
            `ALU_XOR: begin
                result = xor_result;
            end
            `ALU_SRL: begin
                if (last_aux == 1'b1) begin 
                    result = sra_result;
                end else 
                    result = srl_result;
            end
            `ALU_OR: begin
                result = or_result;
            end
            `ALU_AND: begin
                result = and_result;
            end
        endcase
    end
endmodule
