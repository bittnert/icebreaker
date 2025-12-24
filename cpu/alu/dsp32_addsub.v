// -----------------------------------------------------------------------------
// 32-bit Adder/Subtractor using iCE40 SB_MAC16 DSP blocks
// Uses 2 DSP slices in cascade, with output registers enabled
// Works with Yosys + nextpnr for iCE40UP family
// -----------------------------------------------------------------------------

/* verilator lint_off PINMISSING */
module dsp32_addsub #
(
    parameter REGISTER_OUTPUT = 1   // 1 = use DSP output register
)
(
    input  wire         clk,
    input  wire         add_sub,   // 0 = add, 1 = subtract
    input  wire [31:0]  a,
    input  wire [31:0]  b,
    output wire [31:0]  y
);

    SB_MAC16 #( .NEG_TRIGGER(0), 
                .C_REG(0),
                .A_REG(0),
                .B_REG(0),
                .D_REG(0),
                .TOP_8x8_MULT_REG(0),
                .BOT_8x8_MULT_REG(0),
                .PIPELINE_16x16_MULT_REG1(0),
                .PIPELINE_16x16_MULT_REG2(0),
                .MODE_8x8(0),
                .A_SIGNED(0),
                .B_SIGNED(0),
                .TOPOUTPUT_SELECT(REGISTER_OUTPUT),
                .TOPADDSUB_LOWERINPUT(0), //select A as lower input for top adder
                .TOPADDSUB_UPPERINPUT(1), //select C as upper input for top adder
                .TOPADDSUB_CARRYSELECT(2), //HCI (high carry in) is set to LCO ^ ADDSUBTOP to support add/subtract operation
                .BOTADDSUB_LOWERINPUT(0), //select B as lower input for bottom adder
                .BOTADDSUB_UPPERINPUT(1), //select D as upper input for bottom adder
                .BOTADDSUB_CARRYSELECT(3),  //LCI (low carry in) is set to CI. This allows 
                                            //for add/subtract operation. For subtraction, CI has to be set to 1 to work with the two's complement conversion inside the DSP slice.
                .BOTOUTPUT_SELECT(REGISTER_OUTPUT)
    ) dsp (
	    .CLK(clk), 
        .CE(1'b1), 
	    .C(a[31:16]), 
        .A(b[31:16]),  //top adder/subtractor calculate A +(-) C.
        .B(b[15:0]),  //bottom adder/subtractor calculate B +(-) D.  
        .D(a[15:0]),  //Therefore, the lower 16 bits from a and b are used here.
	    .AHOLD(1'h0), 
        .BHOLD(1'h0), 
        .CHOLD(1'h0), 
        .DHOLD(1'h0),
	    .IRSTTOP(1'h0), 
        .IRSTBOT(1'h0),
	    .ORSTTOP(1'h0), 
        .ORSTBOT(1'h0),
	    .OLOADTOP(1'h0), 
        .OLOADBOT(1'h0),
	    .ADDSUBTOP(add_sub), 
        .ADDSUBBOT(add_sub),
	    .OHOLDTOP(1'h0), 
        .OHOLDBOT(1'h0),
	    .CI(1'h0), 
        .ACCUMCI(1'h0), 
        .SIGNEXTIN(1'h0),
	    .O(y)
);


endmodule

/* verilator lint_on UNOPTFLAT */
