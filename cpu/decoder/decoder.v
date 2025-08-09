

module decoder (
        input clk,
        input rst,
        input [31:0] instr,
        input [31:0] branch_pc,
        input branch_taken,
        output [4:0] rd_addr,
        output [4:0] rs1_addr,
        output [4:0] rs2_addr,
        output reg [31:0] imm_val,
        output reg [31:0] pc /*verilator public_flat_rd*/,
        output reg imm_mux_sel,
        output reg [2:0] alu_sel,
        output reg [2:0] branch_sel,
        output reg alu_aux,
        //output [6:0] func7,
        output reg mem_en,
        output reg mem_wr,
        output reg reg_en,
        output alu_a_sel,
        output reg mem_addr_sel,
        output reg[2:0] mem_size,
        output reg[1:0] rd_in_sel,
        output reg fetch_stage
    );



	localparam
		ST_FETCH = 3'b00,
		ST_DECODE = 3'b01,
		ST_OP = 3'b10,
		ST_LD_ST = 3'b11,
        ST_WRITE = 3'b100;

    reg [2:0] state;
    reg [31:0] local_instr;
    reg reg_write;
    reg [2:0] imm_type;
    reg branch;
    reg store;
    reg load;
    reg jump;
    reg[2:0] loc_mem_size;
    // Add this internal register to capture a possible combinational loop
    reg internal_alu_a_sel;

    //assign alu_sel = local_instr[14:12];
    //assign func7 = local_instr[31:25];
    assign rd_addr = local_instr[11:7];
    assign rs1_addr = local_instr[19:15];
    assign rs2_addr = local_instr[24:20];
    //assign mem_addr_sel = load | store;
    // Ensure to not have a cominational loop which happens in case alu_a_sel is 0 and mem_addr_sel is 1
    //assign alu_a_sel = (!internal_alu_a_sel && mem_addr_sel) ? 1 : internal_alu_a_sel;
    assign alu_a_sel = mem_addr_sel ? 1'b1 : internal_alu_a_sel;

    imm_decoder d0(.instr(local_instr),.instr_type(imm_type), .imm_value(imm_val));

    always @ (posedge clk) begin

        if (rst == 1'b0) begin
            state     <= ST_FETCH;
            mem_en <= 1;
            mem_wr <= 0;
            reg_en <= 0;
`ifdef RISCOF
            pc <= 32'h01000000;
`else
            pc <= 0;
`endif
            mem_size <= 3'b010;
            fetch_stage <= 0;
        end else begin
            case (state)
                ST_FETCH: begin
                    mem_en <= 1;
                    mem_wr <= 0;
                    state <= ST_DECODE;
                    reg_en <= 0;
                    fetch_stage <= 0;
                end
                ST_DECODE: begin
                    mem_en <= 0;
                    mem_wr <= 0;
                    local_instr <= instr;
                    state <= ST_OP;
                    reg_en <= 0;
                    //mem_addr_sel <= store | load;
                    mem_addr_sel <= 0;
                end
                ST_OP: begin
                    state <= ST_LD_ST;
                    reg_en <= 0;
                    mem_addr_sel <= store | load;
                    //We have to set the mem_size one clock cycle earlier so memory has time to load the data
                    mem_size <= loc_mem_size;
                    //mem_en <= store | load;
                    //mem_wr <= store;
                end
                ST_LD_ST: begin
                    mem_addr_sel <= store | load;
                    mem_en <= store | load;
                    mem_wr <= store;
                    //mem_en <= 0;
                    //mem_wr <= 0;
                    state <= ST_WRITE;
                    reg_en <= reg_write;
                end
                ST_WRITE: begin
                    mem_addr_sel <= 0;
                    state <= ST_FETCH;
                    reg_en <= 0;
                    mem_en <= 0;
                    mem_wr <= 0;
                    mem_size <= 3'b010;
                    if (branch && (branch_taken | jump))
                        pc <= {branch_pc[31:2], 2'b00};
                    else
                        pc <= pc + 4;
                    fetch_stage <= 1;
                end
                default: begin
                    state <= ST_FETCH;
                end
            endcase
        end
    end

    always @(*) begin
        case (local_instr[6:0])
            `LUI_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 1; 
                internal_alu_a_sel = 1;
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `U_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 0;
                rd_in_sel = 1;
                store = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 0;
            end
            `OP_IMM_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 1;
                internal_alu_a_sel = 1;
                alu_sel = local_instr[14:12];
                //alu_aux = local_instr[30];
                alu_aux = (local_instr[14:12] == 3'b101) ?local_instr[30] : 0;
                imm_type = `I_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 0;
                rd_in_sel = 2;
                store = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 0;
            end
            `OP_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 0;
                internal_alu_a_sel = 1;
                alu_sel = local_instr[14:12];
                alu_aux = local_instr[30];
                imm_type = `I_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 0;
                rd_in_sel = 2;
                store = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 0;
            end
            `AUIPC_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 1;
                internal_alu_a_sel = 0;
                /* Emulate Add instruction*/
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `U_TYPE;
                branch_sel = `COMPARE_INV;

                branch = 0;
                rd_in_sel = 2;
                store = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 0;
            end
            `BRANCH_OPCODE: begin
                reg_write = 0;
                imm_mux_sel = 1;
                internal_alu_a_sel = 0;
                /* Emulate Add instruction*/
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `B_TYPE;
                branch_sel = local_instr[14:12];
                branch = 1;
                store = 0;
                rd_in_sel = 2;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 0;
            end
            `JAL_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 1;
                internal_alu_a_sel = 0;
                /* Emulate Add instruction*/
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `J_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 1;
                rd_in_sel = 0;
                store = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 1;
            end
            `JALR_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 1;
                internal_alu_a_sel = 1;
                /* Emulate Add instruction*/
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `I_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 1;
                rd_in_sel = 0;
                store = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 1;
            end
            `STORE_OPCODE: begin
                reg_write = 0;
                imm_mux_sel = 1;
                internal_alu_a_sel = 1;
                /* Emulate Add instruction*/
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `S_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 0;
                rd_in_sel = 2;
                store = 1;
                load = 0;
                loc_mem_size = local_instr[14:12];
                jump = 0;
            end
            `LOAD_OPCODE: begin
                reg_write = 1;
                imm_mux_sel = 1;
                internal_alu_a_sel = 1;
                /* Emulate Add instruction*/
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type = `I_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 0;
                rd_in_sel = 3;
                store = 0;
                load = 1;
                loc_mem_size = local_instr[14:12];
                jump = 0;
            end
            default: begin
                reg_write = 0;
                imm_mux_sel = 0; 
                internal_alu_a_sel = 1;
                alu_sel = 3'b000;
                alu_aux = 0;
                imm_type    = `B_TYPE;
                branch_sel = `COMPARE_INV;
                branch = 0;
                store = 0;
                rd_in_sel = 0;
                load = 0;
                loc_mem_size = 3'b010;
                jump = 0;
            end
        endcase
    end

endmodule
