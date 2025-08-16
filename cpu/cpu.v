
`include "cpu.vh"
// simulation does not detect that the combinational loop is broken in the decoder so we need to turn off the check
/* verilator lint_off UNOPTFLAT */
`define MEMORY_SIZE 21
module cpu(input CLK, 
            input BTN_N, 
            input RX, 
            output TX,
            output P1B1);

    wire [31:0] memory_bus;
    wire mem_en /*verilator public_flat_rd*/;
    wire mem_wr /*verilator public_flat_rd*/;
    wire [2:0] mem_size;
    wire [31:0] mem_addr;
    reg [31:0] alu_out_reg;
    wire [31:0] rd, rs1, rs2, imm, imm_mux_out, alu_out;
    wire [31:0] alu_mux_out;
    wire [31:0] alu_a;
    wire alu_mux_sel;
    wire imm_mux_sel;
    wire [2:0] alu_sel;
    wire [2:0] branch_sel;
    wire alu_a_sel;
    wire alu_aux;
    wire mem_addr_sel;
    wire [1:0] rd_in_sel;
    wire [4:0] rd_addr, rs1_addr, rs2_addr;
    reg [31:0] pc /*verilator public_flat_rd*/;
    wire reg_en /*verilator public_flat_rd*/; 
    wire branch_taken;
    reg load_store_branch_taken, write_back_branch_taken, fetch_branch_taken;
    reg [31:0] decode_pc, op_pc, load_store_pc, write_back_pc;
    wire fetch_stage;
    wire [31:0] memory_bus_in, memory_bus_out;
    reg [31:0] alu_reg;
    wire [`OP_SIZE:0] ctrl_vec;
    reg [`OP_SIZE:0] op_ctrl_vec;
    reg [`LOAD_STORE_SIZE:0] load_store_ctrl_vec;
    reg [`WRITE_BACK_SIZE:0] write_back_ctrl_vec;
    
    reg [31:0] alu_mux_addr_in;

    always @(posedge CLK) begin
        alu_mux_addr_in <= mem_addr;
    end 

    always @(posedge CLK) begin
        op_ctrl_vec <= ctrl_vec;
        load_store_ctrl_vec <= op_ctrl_vec[`LOAD_STORE_SIZE:0];
        write_back_ctrl_vec <= load_store_ctrl_vec[`WRITE_BACK_SIZE:0];
    end

    always @(posedge CLK) begin
        decode_pc <= pc;
        op_pc     <= decode_pc;
        load_store_pc <= op_pc;
        write_back_pc <= load_store_pc;
    end

    always @(posedge CLK) begin
        load_store_branch_taken <= branch_taken;
        write_back_branch_taken <= load_store_branch_taken;
        fetch_branch_taken <= write_back_branch_taken;
    end

/************************* FETCH STAGE *****************************************/



/************************ DECODE STAGE *****************************************/

    decoder decoder(.clk(CLK),
                    .rst(BTN_N),
                    .instr(memory_bus_out),
                    .branch_pc(alu_out),
                    .branch_taken(branch_taken_reg),
                    .imm_val(imm),
                    .pc(pc),
                    .rs1_addr(rs1_addr),
                    .rs2_addr(rs2_addr),
                    .ctrl_vec(ctrl_vec),
                    /*
                    .rd_addr(rd_addr),
                    .imm_mux_sel(imm_mux_sel),
                    .mem_en(mem_en),
                    .mem_wr(mem_wr),
                    .alu_sel(alu_sel),
                    .branch_sel(branch_sel),
                    .alu_aux(alu_aux),
                    .reg_en(reg_en),
                    .alu_a_sel(alu_a_sel),
                    .mem_size(mem_size),
                    .rd_in_sel(rd_in_sel),
                    .mem_addr_sel(mem_addr_sel),
                    */
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
                        .operation(op_ctrl_vec[`BRANCH_SEL_BASE+`BRANCH_SEL_WIDTH - 1:`BRANCH_SEL_BASE]), 
                        .result(branch_taken));

    mux2 rs1_mux(.a(rs1), 
                .b(alu_mux_addr_in), 
                .sel(op_ctrl_vec[`ALU_A_SEL_BASE + `ALU_A_SEL_WIDTH -  1:`ALU_A_SEL_BASE]), 
                .result(alu_mux_out));

    mux2 imm_mux(.a(imm),
                .b(rs2),
                .sel(op_ctrl_vec[`IMM_MUX_SEL_BASE + `IMM_MUX_SEL_WIDTH - 1:`IMM_MUX_SEL_BASE]),
                .result(imm_mux_out));

    alu alu(.clk(CLK),
            .a(alu_mux_out),
            .b(imm_mux_out),
            .op(op_ctrl_vec[`ALU_SEL_BASE + `ALU_SEL_WIDTH - 1:`ALU_SEL_BASE]),
            .aux(op_ctrl_vec[`ALU_AUX_BASE + `ALU_AUX_WIDTH - 1:`ALU_AUX_BASE]),
            .result(alu_out));

    always @(posedge CLK) begin
        alu_reg <= alu_out;
        branch_taken_reg <= branch_taken;
    end
/************************************* LOAD AND STORE STAGE *****************************************/
    assign memory_bus_in = rs2;
    assign P1B1 = TX;

/* verilator lint_off PINMISSING*/
    load_store load_store_unit(.CLK(CLK),
                                .addr(mem_addr),
                                .data_in(memory_bus_in),
                                .data_out(memory_bus_out),
                                .en(load_store_ctrl_vec[`MEM_EN_BASE + `MEM_EN_WIDTH - 1:`MEM_EN_BASE]),
                                .size(load_store_ctrl_vec[`MEM_SIZE_BASE + `MEM_SIZE_WIDTH - 1:`MEM_SIZE_BASE]),
                                .wr(load_store_ctrl_vec[`MEM_WR_BASE + `MEM_WR_WIDTH - 1:`MEM_WR_BASE]),
                                .reset(BTN_N),
                                .RX(RX),
                                .TX(TX));
/*lint_on*/





    mux2 mem_addr_mux(.a(alu_reg), .b(pc), .sel(mem_addr_sel), .result(mem_addr));


/******************************* WRITE BACK STAGE *****************************************/

    mux4 rd_in_mux(
                    .a(pc + 4), 
                    .b(imm_mux_out), 
                    .c(alu_reg), 
                    .d(memory_bus_out), 
                    .sel(write_back_ctrl_vec[`REG_IN_SEL_BASE + `REG_IN_SEL_WIDTH - 1:`REG_IN_SEL_BASE]), 
                    .result(rd));


endmodule
