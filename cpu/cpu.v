
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
    wire [31:0] rd, rs1, rs2, imm, imm_mux_out, alu_out;
    reg[31:0] load_store_imm, write_back_imm;
    wire [31:0] alu_mux_out;
    wire [4:0] rd_addr, rs1_addr, rs2_addr;
    reg [31:0] pc /*verilator public_flat_rd*/;
    reg [31:0] npc;
    wire branch_taken;
    reg load_store_branch_taken, write_back_branch_taken, fetch_branch_taken;
    reg [31:0] decode_pc, op_pc, load_store_pc, write_back_pc;
    wire fetch_stage;
    wire [31:0] memory_bus_out;
    reg [31:0] memory_bus_in;
    reg [31:0] alu_reg;
    reg [31:0] write_back_alu_reg;
    wire [`OP_SIZE:0] ctrl_vec;
    wire [`OP_SIZE:0] nop_ctrl_vec;
    reg [`OP_SIZE:0] op_ctrl_vec;
    
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
        end
    end

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            load_store_branch_taken <= 0;
            write_back_branch_taken <= 0;
            fetch_branch_taken <= 0;
        end else begin
            load_store_branch_taken <= branch_taken;
            write_back_branch_taken <= load_store_branch_taken;
            fetch_branch_taken <= write_back_branch_taken;
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
                    .ctrl_vec(ctrl_vec)
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
                                .rd_en (write_back_ctrl_vec[`REG_EN_BASE + `REG_EN_WIDTH - 1:`REG_EN_BASE]));

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
/************************************* LOAD AND STORE STAGE *****************************************/
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
                                .RX(RX),
                                .TX(TX));
/*lint_on*/

    mux2 mem_addr_mux(.a(alu_out), .b(pc), .sel(load_store_ctrl_vec[`MEM_ADDR_SEL_BASE + `MEM_ADDR_SEL_WIDTH - 1:`MEM_ADDR_SEL_BASE]), .result(mem_addr));

/******************************* WRITE BACK STAGE *****************************************/

    always @(posedge CLK) begin
        if (BTN_N == 0) begin
            npc <= 0;
        end else if (load_store_branch_taken || load_store_ctrl_vec[`JUMP_EN_BASE  + `JUMP_EN_SIZE - 1:`JUMP_EN_BASE ]) begin
            npc <= alu_out & ~1;
        end else
            npc <= load_store_pc + 4;
    end

    mux4 rd_in_mux(
                    .a(write_back_pc + 4), 
                    .b(write_back_imm), 
                    .c(alu_reg), 
                    .d(memory_bus_out), 
                    .sel(write_back_ctrl_vec[`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH - 1:`REG_IN_SEL_BASE]), 
                    .result(rd));


endmodule
