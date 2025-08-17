module memory 
    (
    input CLK,
    input [31:0] data_in,
    output reg[31:0] data_out,
    input [31:0] addr,
    input wr,
    input en,
    input [2:0] size,
    output exception
    );

    reg [15:0] data_out_low, data_out_high;
    wire [15:0] data_in_low, data_in_high;

`ifdef SYNTHESIS
// Debug message during synthesis
    SB_SPRAM256KA spram_low (
        .ADDRESS(addr[15:2]),
        .DATAIN(data_in_low),
        .MASKWREN(we[3:0]),
        .WREN(wr & en),
        .CHIPSELECT(1'b1),
        .CLOCK(CLK),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(data_out_low)
    );

    SB_SPRAM256KA spram_high (
        .ADDRESS(addr[15:2]),
        .DATAIN(data_in_high),
        .MASKWREN(we[7:4]),
        .WREN(wr & en),
        .CHIPSELECT(1'b1),
        .CLOCK(CLK),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(data_out_high)
    );

`else
// Simulation model using standard Verilog memory arrays
    //reg [15:0] mem_low[4194304:0]/*verilator public_flat_rd*/;  // For simulation 16 Mbytes.
    //reg [15:0] mem_high[4194304:0]/*verilator public_flat_rd*/; // For Simulation 16 MBytes
    
    initial begin
        /*
        mem_low[0] = 16'h0011;
        mem_low[1] = 16'h2233;
        mem_low[2] = 16'h4455;
        mem_low[3] = 16'h6677;
        mem_low[4] = 16'h8899;
        mem_low[5] = 16'haabb;
        mem_low[6] = 16'hccdd;
        mem_low[7] = 16'heeff;

        mem_high[0] = 16'h0011;
        mem_high[1] = 16'h2233;
        mem_high[2] = 16'h4455;
        mem_high[3] = 16'h6677;
        mem_high[4] = 16'h8899;
        mem_high[5] = 16'haabb;
        mem_high[6] = 16'hccdd;
        mem_high[7] = 16'heeff;
        */

`ifdef RISCOF
    $readmemh("firmware.mem", mem);
`endif

    end
    //reg [15:0] mem_low[524287:0]/*verilator public_flat_rd*/;  // For simulation 16 Mbytes.
    //reg [15:0] mem_high[524287:0]/*verilator public_flat_rd*/; // For Simulation 16 MBytes
    reg [31:0] mem[524287:0]/*verilator public_flat_rd*/; // For Simulation 16 MBytes
    // Read logic for simulation
    always @(posedge CLK) begin
        data_out_low <= mem[addr[20:2]][15:0];
        data_out_high <= mem[addr[20:2]][31:16];
    end
    
    // Write logic for simulation
    always @(posedge CLK) begin
        if (wr && en) begin
            if (we[0]) mem[addr[20:2]][3:0] <= data_in_low[3:0];
            if (we[1]) mem[addr[20:2]][7:4] <= data_in_low[7:4];
            if (we[2]) mem[addr[20:2]][11:8] <= data_in_low[11:8];
            if (we[3]) mem[addr[20:2]][15:12] <= data_in_low[15:12];
            if (we[4]) mem[addr[20:2]][19:16] <= data_in_high[3:0];
            if (we[5]) mem[addr[20:2]][23:20] <= data_in_high[7:4];
            if (we[6]) mem[addr[20:2]][27:24] <= data_in_high[11:8];
            if (we[7]) mem[addr[20:2]][31:28] <= data_in_high[15:12];
        end
    end



`endif

    //Declare temporary variables
    wire[31:0] shift;
    reg[31:0] shift_wr;
    wire[31:0] mask;
    reg[31:0] temp;
    wire[31:0] temp_in;
    reg[7:0] we;

    always @ (*) begin
        if (wr && en) begin
            case (size)
                3'b000: begin
                    shift_wr = 2*addr[1:0];
                    we = 8'h03 << shift_wr;
                end
                3'b001: begin
                    shift_wr = 2*addr[1:0];
                    we = 8'h0F << shift_wr;
                end
                3'b010: begin
                    shift_wr = 0;
                    we = 8'hFF;
                end
                default: begin
                    shift_wr = 0;
                    we = 8'h00;
                end
            endcase
        end else begin
            shift_wr = 0;
            we       = 8'h00;
        end
    end

    always @ (*) begin
        case (size)
            3'b000: begin
                temp = ({data_out_high, data_out_low} & mask) >> shift; 
                data_out = {{24{temp[7]}}, temp [7:0]};
            end
            3'b001: begin
                if (addr[1:0] == 0 || addr[1:0] == 2) begin
                    temp = ({data_out_high, data_out_low} & mask) >> shift;
                    data_out = {{16{temp[15]}}, temp[15:0]};
                end else begin
                    temp = 32'h0;
                    data_out = 32'h0;
                end 
            end
            3'b010: begin
                if (addr[1:0] == 0) begin
                    temp = 32'h0;
                    data_out = {data_out_high, data_out_low};
                end else begin
                    temp = 32'h0;
                    data_out = 32'h0;
                end
            end
            3'b100: begin
                data_out = ({data_out_high, data_out_low} & mask) >> shift;
                temp = 32'h0;
            end
            3'b101: begin
                temp = 32'h0;
                data_out = ({data_out_high, data_out_low} & mask) >> shift;
            end
            default: begin
                temp = 32'h0;
                data_out = 32'h0;
            end
        endcase
    end

    assign temp_in = (data_in << shift);
    assign data_in_low = temp_in[15:0];
    assign data_in_high = temp_in[31:16];
    assign shift = 8*addr[1:0];
    assign mask = (size[1:0] == 2'b00) ? 32'hFF << shift : (size[1:0] == 2'b01) ? 32'hFFFF << shift: 32'hFFFFFFFF;
    //assign data_out = ({data_out_high, data_out_low} & mask) >> shift;
    assign exception = (en && ((size == 3'b010 && addr[1:0] != 0) || (size == 3'b011) || (size == 3'b001 && (addr[1:0] == 1 || addr[1:0] == 3))))? 1 : 0;

endmodule

