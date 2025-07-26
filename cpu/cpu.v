
`include "cpu.vh"
// simulation does not detect that the combinational loop is broken in the decoder so we need to turn off the check
/* verilator lint_off UNOPTFLAT */
`define MEMORY_SIZE 21
module cpu(input CLK, 
            input BTN_N, 
            input RX, 
            output TX);

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
    wire fetch_stage;
    wire [31:0] memory_bus_in, memory_bus_out;
    
    reg [31:0] alu_mux_addr_in;

    always @(posedge CLK) begin
        alu_mux_addr_in <= mem_addr;
    end 

    compare branch_comp(.a(rs1), .b(rs2), .operation(branch_sel), .result(branch_taken));

    assign memory_bus_in = rs2;

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

    cpu_register register_file(.CLK(CLK),
                                .rd(rd),
                                .rs1(rs1),
                                .rs2(rs2),
                                .rd_addr(rd_addr),
                                .rs1_addr(rs1_addr),
                                .rs2_addr(rs2_addr),
                                .rd_en (reg_en ));

    mux2 rs1_mux(.a(rs1), .b(alu_mux_addr_in), .sel(alu_a_sel), .result(alu_mux_out));

    mux2 imm_mux(.a(imm),.b(rs2),.sel(imm_mux_sel),.result(imm_mux_out));


    mux2 mem_addr_mux(.a(alu_out), .b(pc), .sel(mem_addr_sel), .result(mem_addr));

    decoder decoder(.clk(CLK),
                    .rst(BTN_N),
                    .instr(memory_bus_out),
                    .branch_pc(alu_out),
                    .branch_taken(branch_taken),
                    .pc(pc),
                    .rd_addr(rd_addr),
                    .rs1_addr(rs1_addr),
                    .rs2_addr(rs2_addr),
                    .imm_mux_sel(imm_mux_sel),
                    .imm_val(imm),
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
                    .fetch_stage (fetch_stage )
                    );

    alu alu(.a(alu_mux_out)
            , .b(imm_mux_out)
            , .op(alu_sel)
            , .aux(alu_aux)
            , .result(alu_out));

    mux4 rd_in_mux(.a(pc + 4), .b(imm_mux_out), .c(alu_out), .d(memory_bus_out), .sel(rd_in_sel), .result(rd));


endmodule
