

module decode 
    import cpu_pkg::*;
    (
    input logic clk,
    input logic rst_n,
    input logic [31:0] instruction_in,
    input logic [31:0] pc_in,
    input logic invalid_instruction,
    input logic wr_en,
    input logic [31:0] rd_data,
    input logic [4:0] rd_addr,
    output logic [31:0] instruction_out,
    output logic [31:0] immediate_out,
    output logic [31:0] rs1_out,
    output logic [31:0] rs2_out,
    output logic [31:0] pc_out,
    output logic invalid_instruction_out,
    output logic instr_misaligned_out,
    output logic fetch_request,
    output execute_control_vector_t exec_control_vector_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instruction_out <= 32'b0;
            invalid_instruction_out <= 1'b0;
            instr_misaligned_out <= 1'b0;
        end else begin
            instruction_out <= instruction_in;
            invalid_instruction_out <= invalid_instruction;
            instr_misaligned_out <= instr_misaligned;
        end
    end