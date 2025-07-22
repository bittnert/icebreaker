
module dualport_mem #(parameter SIZE=32)(
    input CLK,
    input [31:0] port_a,
    input [$clog2(SIZE) - 1:0] port_a_addr,
    input port_a_en,
    output reg [31:0] port_b,
    input [$clog2(SIZE) - 1:0] port_b_addr
);

    reg [31:0] mem [0:SIZE-1] /*verilator public_flat_rd*/;

    integer i;
initial begin
    for ( i = 0; i < SIZE; i++) begin
        mem[i] = 32'b0; // initialize memory with all zeros
    end 
end

always @(posedge CLK) begin
    port_b <= mem[port_b_addr];
end

always @(posedge CLK) begin
    if (port_a_en) begin
        mem[port_a_addr] <= port_a;
    end
end

endmodule
