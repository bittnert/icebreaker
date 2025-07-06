

module cpu_register(
    input CLK,
    input [31:0] rd,
    output reg [31:0] rs1,
    output reg [31:0] rs2,
    input[4:0] rd_addr,
    input[4:0] rs1_addr,
    input[4:0] rs2_addr,
    input rd_en
);

/*
reg [31:0] mem[31:0];

always @(posedge CLK) begin
    if (rs1_addr != 4'b0) begin
        rs1 <= mem[rs1_addr];
    end else begin
        rs1 <= 0;
    end
end

always @(posedge CLK) begin
    if (rs2_addr != 4'b0) begin
        rs2 <= mem[rs2_addr];
    end else begin
        rs2 <= 0;
    end
end

always @(posedge CLK) begin
    if (rd_en && rd_addr != 0) begin
        mem[rd_addr] <= rd;
    end
end
*/

wire [31:0] in_data;

assign in_data = (rd_addr == 5'b0)? 0 : rd;

dualport_mem reg_a (
    .CLK(CLK), 
    .port_a(in_data), 
    .port_a_addr(rd_addr), 
    .port_a_en(rd_en), 
    .port_b(rs1), 
    .port_b_addr(rs1_addr));

dualport_mem reg_b (
    .CLK(CLK), 
    .port_a(in_data), 
    .port_a_addr(rd_addr), 
    .port_a_en(rd_en), 
    .port_b(rs2), 
    .port_b_addr(rs2_addr));

endmodule
