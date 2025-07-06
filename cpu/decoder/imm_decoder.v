
`include "cpu.vh"
/* verilator lint_off UNUSEDSIGNAL */
/* The lower 7 bits of instr are not used which is fine*/
module imm_decoder(
    input[31:0] instr,
    output reg [31:0] imm_value,
    input [2:0] instr_type
);

/*lint_on UNUSEDSIGNAL*/

always @(*) begin
    case (instr_type)
    `I_TYPE: begin
        imm_value = {{20{instr[31]}}, instr[31:20]};
    end
    `S_TYPE: begin
        imm_value = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    end
    `B_TYPE: begin
        imm_value = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    end
    `U_TYPE: begin
        imm_value = {instr[31:12], 12'b0};
    end
    `J_TYPE: begin
        imm_value = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0};
    end
    default: begin
        imm_value = 32'b0;
    end
    endcase
end

endmodule
