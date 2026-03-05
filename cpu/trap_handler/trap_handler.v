
module trap_handler
    (
        output trap_taken,
        output reg[31:0] trap_mcause,
        output reg [2:0] mtval_sel_out,
        input trap_irq_enabled,
        input trap_instr_addr,
        input trap_instr_access_fault,
        input trap_illegal_instr,
        input trap_breakpoint,
        input trap_load_addr_misaligned,
        input trap_load_access_fault,
        input trap_store_addr_misaligned,
        input trap_store_access_fault,
        input trap_env_call_m_mode,
        input trap_timer_irq
    );

    assign trap_taken = trap_instr_addr || trap_instr_access_fault || 
                        trap_illegal_instr || trap_breakpoint || trap_load_addr_misaligned || 
                        trap_load_access_fault || trap_store_addr_misaligned || trap_store_access_fault ||
                        trap_env_call_m_mode || (trap_irq_enabled && trap_timer_irq);


    always @(*) begin
        // defaults
        trap_mcause = 32'd0;

        if (trap_instr_addr) begin
            trap_mcause = 32'd0;
            mtval_sel_out = 1;
        end else if (trap_instr_access_fault) begin
            trap_mcause = 32'd1;
            mtval_sel_out = 1;
        end else if (trap_illegal_instr) begin
            trap_mcause = 32'd2;
            mtval_sel_out = 3;
        end else if (trap_breakpoint) begin
            trap_mcause = 32'd3;
            mtval_sel_out = 4;
        end else if (trap_load_addr_misaligned) begin
            trap_mcause = 32'd4;
            mtval_sel_out = 2;
        end else if (trap_load_access_fault) begin
            trap_mcause = 32'd5;

            mtval_sel_out = 2;
        end else if (trap_store_addr_misaligned) begin
            trap_mcause = 32'd6;
            mtval_sel_out = 2;

        end else if (trap_store_access_fault) begin
            trap_mcause = 32'd7;
            mtval_sel_out = 2;

        end else if (trap_env_call_m_mode) begin
            trap_mcause = 32'hb;
            mtval_sel_out = 0;

        end else if (trap_irq_enabled && trap_timer_irq) begin
            trap_mcause = 32'h80000007;
            mtval_sel_out = 0;
        end else begin
            trap_mcause = 32'h0;
            mtval_sel_out = 0;
        end
    end

endmodule
