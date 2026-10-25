

module fetch_stage (
    input logic clk,
    input logic rst_n,
    input logic [31:0] branch_target,
    input logic [31:0] instruction_in,
    input logic instr_addr_misaligned,
    input logic fetch_req,
    input logic fetch_ack,
    input logic branch_taken,
    output logic [31:0] pc,
    output logic [31:0] npc,
    output logic [31:0] instruction_out,
    output logic invalid_instruction,
    output logic instr_misaligned
);

    logic instr_valid;
    logic fetch_signal;
    logic npc_select;
    logic [31:0] next_pc;

    instr_valid = fetch_req && fetch_ack;

    instruction_out = instruction_in;

    invalid_instruction = !instr_valid || instr_addr_misaligned;

    npc_select = (instr_valid || branch_taken) && fetch_signal;

    always_ff @(posedge clk or negedge rst_n) begin
        fetch_signal <= fetch_ack & fetch_req;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 1'b0; // Reset takes precedence
        else if (instr_valid || branch_taken)
            pc <= next_pc;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            instr_misaligned <= 1'b0;
        else
            instr_misaligned <= instr_addr_misaligned;
    end

    always_comb begin
        if (branch_taken)
            next_pc = branch_target;
        else
            next_pc = pc + 4; 
    end

    always_comb begin
        if (npc_select)
            npc = next_pc;
        else
            npc = pc; 
    end

endmodule