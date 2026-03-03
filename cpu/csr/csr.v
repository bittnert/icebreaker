
module csr (input CLK,
            input rst_n,
            input [11:0] csr_rw_addr,
            input [31:0] csr_rw_data,
            input [1:0] csr_control_signal,
            output reg [31:0] csr_data_out,
            output csr_illegal_instr_out,
            input csr_trap_taken_in,
            input [31:0] csr_mcause_in,
            input [31:0] csr_pc_in,
            input [31:0] csr_mtval_in,
            output reg[31:0] csr_trap_pc_out,
            output csr_trap_enabled,
            input csr_mret_in);

    reg[31:0] misa;
    reg[31:0] mtvec;
    reg[31:0] mtval;
    reg[31:0] mscratch;
    reg[31:0] mepc;
    reg[31:0] mcause;
    reg mie, mpie;

    wire wr_access_en;
    wire illegal_instr;

    wire wr_access_to_ro_reg;
    assign wr_access_to_ro_reg = csr_rw_addr[11:10] == 2'b11 && wr_access_en;
    wire s_u_privilege_access;
    assign s_u_privilege_access = csr_rw_addr[9:8] != 2'b11;
    wire valid_addr1, valid_addr2;

    assign csr_trap_enabled = mie;

    assign valid_addr1 = csr_rw_addr[7:0] <= 8'h06;
    assign valid_addr2 = csr_rw_addr[7:0] == 8'h10;
    /* Signal is high if any write or read access happens*/
    assign wr_access_en = (csr_control_signal == 2'b00 && csr_rw_data != 0);
                            /* Write access to read only register */
    assign illegal_instr =  wr_access_to_ro_reg 
                            /*if csr_rw_addrs[9:8] is not 2'b11, the access is to S or U privilege
                            level registers which is not supported.*/
                            || s_u_privilege_access 
                            /* 0xF11 to 0xF15  are the only valid read only registers. Here we check
                            if a read only register is selected and the address is out of the valid range*/
                            || (csr_rw_addr[11:10] == 2'b11 && ~(csr_rw_addr[7:0] >= 8'h11 && csr_rw_addr[7:0] <= 8'h15))
                            /* 0xF47 and 0xF57 are the only addresses valid with 0xFxx*/
                            || (csr_rw_addr[11:10] == 2'b01 && ~(csr_rw_addr[7:0] == 8'h47 || csr_rw_addr[7:0] == 8'h57))
                            /* There are no valid 0xBxx addresses defined*/
                            || (csr_rw_addr[11:10] == 2'b10)
                            /* All 0x3xx addresses that are defined*/
                            || (csr_rw_addr[11:10] == 2'b00 && ~(
                                valid_addr1 ||
                                valid_addr2 ||
                                csr_rw_addr[7:0] == 8'h12 ||
                                (csr_rw_addr[7:0] >= 8'h40 && csr_rw_addr[7:0] <= 8'h44) ||
                                csr_rw_addr[7:0] == 8'h4A ||
                                csr_rw_addr[7:0] == 8'h4B ||
                                csr_rw_addr[7:0] == 8'h0A ||
                                csr_rw_addr[7:0] == 8'h1A ||
                                (csr_rw_addr[7:0] >= 8'hA0 && csr_rw_addr[7:0] <= 8'hEF) ||
                                (csr_rw_addr[7:0] >= 8'h0C && csr_rw_addr[7:0] <= 8'h0F) ||
                                (csr_rw_addr[7:0] >= 8'h1C && csr_rw_addr[7:0] <= 8'h1F)));

    assign csr_illegal_instr_out = (csr_control_signal != 2'b00) & illegal_instr;

    always @(*) begin
        /* If csr_trap_taken_in is set, it takes priority to csr_mret_in.*/
        if (csr_trap_taken_in) begin
            csr_trap_pc_out = mtvec & ~32'h3;
        end else if (csr_mret_in) begin
            csr_trap_pc_out = mepc & ~32'h3;
        end else begin
            csr_trap_pc_out = mtvec & ~32'h3;
        end
    end

    always @ (posedge CLK) begin
        if (!rst_n) begin
            misa <= 32'h40000100;
            mtvec <= 32'h0;
            mtval <= 32'h0;
            mscratch <= 32'h0;
            mpie <= 0;
            mie <= 0;
            mcause <= 0;
            mepc <= 0;
            mtval <= 32'h0;
        end else if (csr_trap_taken_in == 1) begin
            mcause <= csr_mcause_in;
            mepc   <= csr_pc_in;
            mtval <= csr_mtval_in;
            mpie <= mie;
            mie <= 0;
        end else if (csr_mret_in == 1) begin
            mie <= mpie;
            mpie <= 0;
        end else begin
            if (!illegal_instr && !csr_trap_taken_in) begin
                /*We know that we have access to a valid address. Therefore, can handle
                all access to registers which are read-only and return only 0 the same in
                an else block.*/
                if (csr_rw_addr == 12'h300) begin
                    /*mstatus register*/
                    csr_data_out <= {{31{1'b0}},mie} << 3 | {{31{1'b0}},mpie} << 7 | 32'h1800;
                    if (csr_control_signal == 2'b01) begin
                        mie <= csr_rw_data[3];
                        mpie <= csr_rw_data[7];
                    end else if (csr_control_signal == 2'b10) begin
                        mie <= mie | csr_rw_data[3];
                        mpie <= mpie | csr_rw_data[7];
                    end else if (csr_control_signal == 2'b11) begin
                        if (csr_rw_data[3] == 1) begin
                            mie <= 0;
                        end 
                        
                        if (csr_rw_data[7] == 1) begin
                            mpie <= 0;
                        end
                    end
                end else if (csr_rw_addr == 12'h301)
                    csr_data_out <= misa;
                else if (csr_rw_addr == 12'h305) begin
                    csr_data_out <= mtvec;
                    if (csr_control_signal == 2'b01)
                        mtvec <= (csr_rw_data & ~32'h3);
                    else if (csr_control_signal == 2'b10)
                        mtvec <= (mtvec | csr_rw_data) & ~32'h3;
                    else if (csr_control_signal == 2'b11)
                        mtvec <= (mtvec & ~csr_rw_data) & ~32'h3;
                end else if (csr_rw_addr == 12'h340) begin
                    /*mscratch register*/
                    csr_data_out          <= mscratch;
                    if (csr_control_signal == 2'b01) 
                        /* Apply data to scratch*/
                        mscratch <= csr_rw_data;
                    else if (csr_control_signal == 2'b10)
                        /* set bits set in data*/
                        mscratch <= mscratch | csr_rw_data;
                    else if (csr_control_signal == 2'b11)
                        /*Clear bits set in data*/
                        mscratch <= mscratch & ~csr_rw_data;
                end else if (csr_rw_addr == 12'h341) begin
                    /* Address of MEPC*/
                    csr_data_out <= mepc;
                    if (csr_control_signal == 2'b01) 
                        mepc <= (csr_rw_data & ~32'h3);
                    else if (csr_control_signal == 2'b10)
                        mepc <= (mepc | csr_rw_data) & ~32'h3;
                    else if (csr_control_signal == 2'b11)
                        mepc <= (mepc & ~csr_rw_data) & ~32'h3;
                end else if (csr_rw_addr == 12'h342) begin
                    csr_data_out <= mcause;
                    if (csr_control_signal == 2'b01)
                        mcause <= csr_rw_data;
                    else if (csr_control_signal == 2'b10)
                        mcause <= mcause | csr_rw_data;
                    else if (csr_control_signal == 2'b11)
                        mcause <= mcause & ~csr_rw_data;
                end else if (csr_rw_addr == 12'h343) begin
                    csr_data_out <= mtval;
                    if (csr_control_signal == 2'b01)
                        mtval <= csr_rw_data;
                    else if (csr_control_signal == 2'b10)
                        mtval <= mtval | csr_rw_data;
                    else if (csr_control_signal == 2'b11)
                        mtval <= mtval & ~csr_rw_data;
                end else
                    csr_data_out <= 0;
            end else 
                csr_data_out <= 0;
        end
    end



endmodule
