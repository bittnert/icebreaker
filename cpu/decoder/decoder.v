`include "cpu.vh"

module decoder (
        input clk,
        input rst,
        input [31:0] instr,
        input [31:0] branch_pc,
        input branch_taken,
        output reg [`OP_SIZE:0] ctrl_vec,
        output [4:0] rs1_addr,
        output [4:0] rs2_addr,
        output reg [31:0] imm_val,
        output reg [31:0] pc /*verilator public_flat_rd*/,
        /*
        output [4:0] rd_addr,
        output reg imm_mux_sel,
        output reg [2:0] alu_sel,
        output reg [2:0] branch_sel,
        output reg alu_aux,
        //output [6:0] func7,
        output reg mem_en,
        output reg mem_wr,
        output reg reg_en,
        output alu_a_sel,
        output reg mem`addr_sel,
        output reg[2:0] mem_size,
        output reg[1:0] rd_in_sel,
        */
    );



	localparam
		ST_FETCH = 3'b00,
		ST_DECODE = 3'b01,
		ST_OP = 3'b10,
		ST_LD_ST = 3'b11,
        ST_WRITE = 3'b100;

    reg [2:0] state;
    reg reg_write;
    reg [2:0] imm_type;
    reg branch;
    reg store;
    reg load;
    reg jump;
    reg[2:0] loc_mem_size;
    // Add this internal register to capture a possible combinational loop
    reg internal_alu_a_sel;
    reg [2:0] alu_sel, branch_sel;
    reg [1:0] rd_in_sel;
    reg imm_mux_sel;
    reg alu_aux;

    //assign alu_sel = local_instr[14:12];
    //assign func7 = local_instr[31:25];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    //assign mem_addr_sel = load | store;
    // Ensure to not have a cominational loop which happens in case alu_a_sel is 0 and mem_addr_sel is 1
    //assign alu_a_sel = (!internal_alu_a_sel && mem_addr_sel) ? 1 : internal_alu_a_sel;
    //assign alu_a_sel = mem_addr_sel ? 1'b1 : internal_alu_a_sel;

    imm_decoder d0(.instr(instr),.instr_type(imm_type), .imm_value(imm_val));

    always @ (posedge clk) begin

        if (rst == 1'b0) begin
            state     <= ST_FETCH;
            ctrl_vec <= `OP_SIZE'h0;
`ifdef RISCOF
            pc <= 32'h01000000;
`else
            pc <= 0;
`endif
        end else begin
            case (state)
                ST_FETCH: begin
                    ctrl_vec <= `OP_SIZE'h0;
                    state <= ST_DECODE;
                end
                ST_DECODE: begin
                    state <= ST_OP;
                    // Write back control register setting
                    ctrl_vec[`RD_ADDR_BASE +`RD_ADDR_WIDTH:`RD_ADDR_BASE] <= instr[11:17];
                    ctrl_vec[`REG_EN_BASE + `REG_EN_WIDTH:`REG_EN_BASE] <= reg_write;
                    ctrl_vec[`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH:`REG_IN_SEL_BASE] <= rd_in_sel;
                    // LOAD/STORE control vector settings
                    ctrl_vec[`MEM_EN_BASE + `MEM_EN_WIDTH:`MEM_EN_BASE] <= store | load;
                    ctrl_vec[`MEM_WR_BASE + `MEM_WR_WIDTH:`MEM_WR_BASE] <= store;
                    ctrl_vec[`MEM_ADDR_SEL_BASE + `MEM_ADDR_SEL_WIDTH:`MEM_ADDR_SEL_BASE] <= store | load;
                    ctrl_vec[`MEM_SIZE_BASE + `MEM_SIZE_WIDTH:`MEM_SIZE_BASE] <= loc_mem_size;
                    // OP control vector settings
                    ctrl_vec[`IMM_MUX_SEL_BASE + `IMM_MUX_SEL_WIDTH:`IMM_MUX_SEL_BASE] <= imm_mux_sel;
                    ctrl_vec[`ALU_SEL_BASE + `ALU_SEL_WIDTH:`ALU_SEL_BASE] <= alu_sel;
                    ctrl_vec[`BRANCH_SEL_BASE + `BRANCH_SEL_WIDTH:`BRANCH_SEL_BASE] <= branch_sel;
                    ctrl_vec[`ALU_A_SEL_BASE + `ALU_A_SEL_WIDTH:`ALU_A_SEL_BASE] <= internal_alu_a_sel;
                    ctrl_vec[`ALU_AUX_BASE + `ALU_AUX_WIDTH:`ALU_AUX_BASE] <= alu_aux;
                end
                ST_OP: begin
                    ctrl_vec <= `OP_SIZE'h0;
                    state <= ST_LD_ST;
                end
                ST_LD_ST: begin
                    ctrl_vec <= `OP_SIZE'h0;
                    state <= ST_WRITE;
                end
                ST_WRITE: begin
                    ctrl_vec <= `OP_SIZE'h0;
                    state <= ST_FETCH;
                    if (branch && (branch_taken | jump))
                        pc <= {branch_pc[31:2], 2'b00};
                    else
                        pc <= pc + 4;
                end
                default: begin
                    ctrl_vec <= `OP_SIZE'h0;
                    state <= ST_FETCH;
                end
            endcase
        end
    end

    always @(*) begin
        case (instr[6:0])
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
                alu_sel = instr[14:12];
                //alu_aux = local_instr[30];
                alu_aux = (instr[14:12] == 3'b101) ?instr[30] : 0;
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
                alu_sel = instr[14:12];
                alu_aux = instr[30];
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
                branch_sel = instr[14:12];
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
                loc_mem_size = instr[14:12];
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
                loc_mem_size = instr[14:12];
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
