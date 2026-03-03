
`include "cpu.vh"
// simulation does not detect that the combinational loop is broken in the decoder so we need to turn off the check
/* verilator lint_off UNOPTFLAT */
`define MEMORY_SIZE 21
module cpu(input CLK, 
            input BTN_N, 
            input RX, 
            output TX
            );

    wire mem_en /*verilator public_flat_rd*/;
    wire mem_wr /*verilator public_flat_rd*/;
    wire [2:0] mem_size;
    wire [31:0] mem_addr;
    wire [31:0] rs1, rs2, imm, imm_mux_out, alu_out;
    reg [31:0] rd;
    reg[31:0] load_store_imm, write_back_imm;
    wire [31:0] alu_mux_out;
    wire [4:0] rs1_addr, rs2_addr;
    reg [31:0] pc /*verilator public_flat_rd*/;
    reg [31:0] npc;
    wire branch_taken;
    reg load_store_branch_taken, write_back_branch_taken;
    reg [1:0] csr_control_signal, execute_csr_control_signal;
    reg [11:0] csr_rw_addr, execute_csr_rw_addr;
    reg csr_mret, execute_csr_mret;
    wire csr_data_sel;
    wire [31:0] csr_data_out;
    wire csr_trap_taken;
    wire csr_trap_enabled;
    wire csr_illegal_instr;
    wire [2:0] trap_mtval_sel;
    wire timer_irq;
    reg [31:0] csr_mtval_in;
    wire [31:0] csr_mcause;
    wire [31:0] csr_pc_out;
    wire load_store_exec_out;
    reg illegal_instruction, execute_illegal_instruction, load_store_illegal_instruction;
    reg [31:0] csr_rw_data;
    reg [31:0] decode_pc, op_pc, load_store_pc, write_back_pc;
    wire fetch_stage;
    wire [31:0] memory_bus_out;
    wire trap_load_addr_misaligned, trap_store_addr_misaligned;
    wire trap_ecall, trap_ebreak;
    wire [31:0] trap_pc_in;
    reg  load_store_trap_ecall, load_store_trap_ebreak;
    reg [31:0] instruction, execute_instruction;
    reg [31:0] memory_bus_in;
    reg [31:0] alu_reg;
    reg [31:0] write_back_alu_reg;
    wire [`OP_SIZE:0] ctrl_vec;
    wire [`OP_SIZE:0] nop_ctrl_vec;
    reg [`OP_SIZE:0] op_ctrl_vec;
    wire trap_instr_addr_misaligned;
    wire [31:0] branch_target;
    reg write_back_trap_taken;

    reg [`LOAD_STORE_SIZE:0] load_store_ctrl_vec;
    reg [`WRITE_BACK_SIZE:0] write_back_ctrl_vec;
    
    // Write back control register setting
    assign nop_ctrl_vec[`JUMP_EN_BASE + `JUMP_EN_SIZE - 1: `JUMP_EN_BASE ] = 0;
    assign nop_ctrl_vec[`RD_ADDR_BASE +`RD_ADDR_WIDTH - 1:`RD_ADDR_BASE] = 0;
    assign nop_ctrl_vec[`REG_EN_BASE + `REG_EN_WIDTH - 1:`REG_EN_BASE] = 0;
    assign nop_ctrl_vec[`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH - 1:`REG_IN_SEL_BASE] = 0;
    // LOAD/STORE control vector settings
    assign nop_ctrl_vec[`MEM_EN_BASE + `MEM_EN_WIDTH - 1:`MEM_EN_BASE] = 0;
    assign nop_ctrl_vec[`MEM_WR_BASE + `MEM_WR_WIDTH - 1:`MEM_WR_BASE] = 0;
    assign nop_ctrl_vec[`MEM_ADDR_SEL_BASE + `MEM_ADDR_SEL_WIDTH - 1:`MEM_ADDR_SEL_BASE] = 0;
    assign nop_ctrl_vec[`MEM_SIZE_BASE + `MEM_SIZE_WIDTH - 1:`MEM_SIZE_BASE] = 0;
    // OP control vector settings
    assign nop_ctrl_vec[`IMM_MUX_SEL_BASE + `IMM_MUX_SEL_WIDTH - 1:`IMM_MUX_SEL_BASE] = 0;
    assign nop_ctrl_vec[`ALU_SEL_BASE + `ALU_SEL_WIDTH - 1:`ALU_SEL_BASE] = 0;
    assign nop_ctrl_vec[`BRANCH_SEL_BASE + `BRANCH_SEL_WIDTH - 1:`BRANCH_SEL_BASE] = `COMPARE_INV;
    assign nop_ctrl_vec[`ALU_A_SEL_BASE + `ALU_A_SEL_WIDTH - 1:`ALU_A_SEL_BASE] = 0;
    assign nop_ctrl_vec[`ALU_AUX_BASE + `ALU_AUX_WIDTH - 1:`ALU_AUX_BASE] = 0;

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            op_ctrl_vec <= nop_ctrl_vec;
            load_store_ctrl_vec <= nop_ctrl_vec[`LOAD_STORE_SIZE:0];
            write_back_ctrl_vec <= nop_ctrl_vec[`WRITE_BACK_SIZE:0];
        end else begin
            op_ctrl_vec <= ctrl_vec;
            load_store_ctrl_vec <= ctrl_vec[`LOAD_STORE_SIZE:0];
            write_back_ctrl_vec <= load_store_ctrl_vec[`WRITE_BACK_SIZE:0];
        end
    end

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            execute_csr_control_signal <= 0;
            execute_csr_rw_addr <= 0;
            execute_csr_mret <= 0;
            instruction <= 0;
            execute_instruction <= 0;
            execute_illegal_instruction <= 0;
            load_store_illegal_instruction <= 0;
        end begin
            instruction <= memory_bus_out;
            execute_instruction <= instruction;
            execute_csr_control_signal <= csr_control_signal;
            execute_csr_rw_addr <= csr_rw_addr;
            execute_csr_mret <= csr_mret;
            execute_illegal_instruction <=illegal_instruction; 
            load_store_illegal_instruction <= execute_illegal_instruction;
        end
    end

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            pc <= 0;
            decode_pc <= 0;
            op_pc <= 0;
            load_store_pc <= 0;
            write_back_pc <= 0;
        end else begin
            pc <= npc;
            decode_pc <= pc;
            op_pc     <= decode_pc;
            load_store_pc <= op_pc;
            write_back_pc <= load_store_pc;
            if (csr_trap_taken) begin
                write_back_pc <= csr_pc_out;
            end else 
                write_back_pc <= load_store_pc;
        end
    end

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            load_store_branch_taken <= 0;
            write_back_branch_taken <= 0;
        end else begin
            load_store_branch_taken <= branch_taken;
            write_back_branch_taken <= load_store_branch_taken;
        end
    end

/************************* FETCH STAGE *****************************************/



/************************ DECODE STAGE *****************************************/

    decoder decoder(.clk(CLK),
                    .rst(BTN_N),
                    .instr(memory_bus_out),
                    .imm_val(imm),
                    .rs1_addr(rs1_addr),
                    .rs2_addr(rs2_addr),
                    .fetch_stage(fetch_stage),
                    .ctrl_vec(ctrl_vec),
                    .illegal_instruction_out(illegal_instruction),
                    .csr_control_signal (csr_control_signal),
                    .csr_rw_addr(csr_rw_addr),
                    .csr_mret(csr_mret),
                    .csr_data_sel(csr_data_sel),
                    .trap_ecall(trap_ecall),
                    .trap_ebreak(trap_ebreak)
                    );
    
    // Register file needs to provide register value in Deocde stage. 
    // In writeback stage, the data are being written back to register.
    cpu_register register_file(.CLK(CLK),
                                .rd(rd),
                                .rs1(rs1),
                                .rs2(rs2),
                                .rd_addr(write_back_ctrl_vec[`RD_ADDR_BASE + `RD_ADDR_WIDTH - 1:`RD_ADDR_BASE]),
                                .rs1_addr(rs1_addr),
                                .rs2_addr(rs2_addr),
                                .rd_en (write_back_ctrl_vec[`REG_EN_BASE + `REG_EN_WIDTH - 1:`REG_EN_BASE] && !write_back_trap_taken));

/*************************************** OP STAGE *****************************************/

    compare branch_comp(
                        .a(rs1), 
                        .b(rs2), 
                        .operation(ctrl_vec[`BRANCH_SEL_BASE+`BRANCH_SEL_WIDTH - 1:`BRANCH_SEL_BASE]), 
                        .result(branch_taken));

    mux2 rs1_mux(.a(rs1), 
                .b(op_pc),
                .sel(ctrl_vec[`ALU_A_SEL_BASE + `ALU_A_SEL_WIDTH -  1:`ALU_A_SEL_BASE]), 
                .result(alu_mux_out));

    mux2 imm_mux(.a(imm),
                .b(rs2),
                .sel(ctrl_vec[`IMM_MUX_SEL_BASE + `IMM_MUX_SEL_WIDTH - 1:`IMM_MUX_SEL_BASE]),
                .result(imm_mux_out));

    alu alu(.clk(CLK),
            .a(alu_mux_out),
            .b(imm_mux_out),
            .op(ctrl_vec[`ALU_SEL_BASE + `ALU_SEL_WIDTH - 1:`ALU_SEL_BASE]),
            .aux(ctrl_vec[`ALU_AUX_BASE + `ALU_AUX_WIDTH - 1:`ALU_AUX_BASE]),
            .result(alu_out));

    always @(posedge CLK) begin
        alu_reg <= alu_out;
        write_back_alu_reg <= alu_reg;
    end

    always @(posedge CLK) begin
        load_store_imm <= imm_mux_out;
        write_back_imm <= load_store_imm;
    end

    always @(posedge CLK) begin
        case (csr_data_sel) 
            1'b0: csr_rw_data <= rs1;
            1'b1: csr_rw_data <= imm;
        endcase
    end
/************************************* LOAD AND STORE STAGE *****************************************/

    csr csr_module(
        .CLK(CLK),
        .rst_n(BTN_N),
        .csr_rw_addr(execute_csr_rw_addr),
        .csr_rw_data(csr_rw_data),
        .csr_control_signal(execute_csr_control_signal),
        .csr_data_out(csr_data_out),
        .csr_illegal_instr_out(csr_illegal_instr),
        .csr_trap_taken_in(csr_trap_taken),
        .csr_mcause_in(csr_mcause),
        .csr_pc_in(trap_pc_in),
        .csr_mtval_in(csr_mtval_in),
        .csr_trap_pc_out(csr_pc_out),
        .csr_trap_enabled(csr_trap_enabled),
        .csr_mret_in(execute_csr_mret)
    );

    trap_handler trap_handler(
        .trap_taken(csr_trap_taken),
        .trap_mcause(csr_mcause),
        .mtval_sel_out(trap_mtval_sel),
        .trap_irq_enabled(csr_trap_enabled),
        .trap_instr_addr(trap_instr_addr_misaligned),
        .trap_instr_access_fault(1'b0), //currently not supported. Will be support with MMU or MPU
        .trap_illegal_instr(execute_illegal_instruction | csr_illegal_instr),
        .trap_breakpoint(load_store_trap_ebreak), //not yet supported
        .trap_load_addr_misaligned(trap_load_addr_misaligned),
        .trap_load_access_fault(1'b0),//currently not supported. Will be support with MMU or MPU
        .trap_store_addr_misaligned(trap_store_addr_misaligned),
        .trap_store_access_fault(1'b0),//currently not supported. Will be support with MMU or MPU
        .trap_env_call_m_mode(load_store_trap_ecall),
        .trap_timer_irq(timer_irq) //not supported yet
    );

    always @(posedge CLK) begin
        write_back_trap_taken <= csr_trap_taken;
    end

    assign trap_pc_in =  load_store_pc;
    assign trap_instr_addr_misaligned = branch_target[1:0] != 2'b00 && (load_store_branch_taken || load_store_ctrl_vec[`JUMP_EN_BASE + `JUMP_EN_SIZE - 1:`JUMP_EN_BASE]);

    always @(*) begin
        case (trap_mtval_sel) 
            3'd0: csr_mtval_in = 0;
            3'd1: csr_mtval_in = branch_target;
            3'd2: csr_mtval_in = mem_addr;
            3'd3: csr_mtval_in = execute_instruction;
            3'd4: csr_mtval_in = load_store_pc;
            default: csr_mtval_in = 0;
        endcase
    end

    //assign memory_bus_in = rs2;
    always @(posedge CLK) begin
        memory_bus_in <= rs2;
    end

    assign mem_en = load_store_ctrl_vec[`MEM_EN_BASE + `MEM_EN_WIDTH - 1:`MEM_EN_BASE] || fetch_stage;
    assign mem_wr = load_store_ctrl_vec[`MEM_EN_BASE + `MEM_EN_WIDTH - 1:`MEM_EN_BASE] && load_store_ctrl_vec[`MEM_WR_BASE + `MEM_WR_WIDTH - 1:`MEM_WR_BASE];
    assign mem_size = load_store_ctrl_vec[`MEM_EN_BASE + `MEM_EN_WIDTH - 1:`MEM_EN_BASE] ? load_store_ctrl_vec[`MEM_SIZE_BASE + `MEM_SIZE_WIDTH - 1:`MEM_SIZE_BASE] : 3'b010;

/* verilator lint_off PINMISSING*/
    load_store load_store_unit(.CLK(CLK),
                                .addr(mem_addr),
                                .data_in(memory_bus_in),
                                .data_out(memory_bus_out),
                                .en(mem_en),
                                .size(mem_size),
                                .wr(mem_wr),
                                .reset(BTN_N),
                                .exception_out(load_store_exec_out),
                                .timer_irq(timer_irq),
                                .RX(RX),
                                .TX(TX));
/*lint_on*/

    assign trap_load_addr_misaligned = load_store_exec_out & mem_en & !mem_wr & !fetch_stage;
    assign trap_store_addr_misaligned = load_store_exec_out & mem_en & mem_wr & !fetch_stage;
    /* When we are in the fetch stage but get an exception, the address is not legal*/
    /* This is set in the fetch stage*/
    assign branch_target = load_store_branch_taken ? alu_out : alu_out & ~1;

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            load_store_trap_ebreak <= 0;
            load_store_trap_ecall <= 0;
        end else begin
            load_store_trap_ebreak <= trap_ebreak;
            load_store_trap_ecall <= trap_ecall;
        end
    end
    

    mux2 mem_addr_mux(.a(alu_out), .b(pc), .sel(load_store_ctrl_vec[`MEM_ADDR_SEL_BASE + `MEM_ADDR_SEL_WIDTH - 1:`MEM_ADDR_SEL_BASE]), .result(mem_addr));

/******************************* WRITE BACK STAGE *****************************************/

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            npc <= 0;
        end else if (csr_trap_taken == 1'b1 || execute_csr_mret == 1'b1) begin
            npc <= csr_pc_out & ~1;
        end else if (load_store_branch_taken || load_store_ctrl_vec[`JUMP_EN_BASE  + `JUMP_EN_SIZE - 1:`JUMP_EN_BASE ]) begin
            //npc <= alu_out & ~1;
            npc <= branch_target;
        end else
            npc <= load_store_pc + 4;
    end

always @(*) begin
    case (write_back_ctrl_vec[`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH - 1:`REG_IN_SEL_BASE])
        3'd0: rd = write_back_pc + 4;
        3'd1: rd = write_back_imm;
        3'd2: rd = alu_reg;
        3'd3: rd = memory_bus_out;
        3'd4: rd = csr_data_out;//CSR value here
        default: rd = '0;
    endcase
end
/*
    mux4 rd_in_mux(
                    .a(write_back_pc + 4), 
                    .b(write_back_imm), 
                    .c(alu_reg), 
                    .d(memory_bus_out), 
                    .sel(write_back_ctrl_vec[`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH - 1:`REG_IN_SEL_BASE]), 
                    .result(rd));
*/

endmodule
