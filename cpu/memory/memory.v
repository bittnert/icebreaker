
    module memory #(parameter SIZE=5, parameter MEMFILE="data.mem") (
    input CLK,
    inout [31:0] data,
    input wr_rd,
    input en,
    input [SIZE + 2: 0] addr,
    input [2:0] size,
    output exception_out
);
/*verilator tracing_on*/
    reg [31:0] mem [2**SIZE: 0] /*verilator public_flat_rd*/;
    /* verilator tracing_off*/

/*verilator tracing_on*/
    wire [31:0] mem_0 = mem[774];
/*verilator tracing_off*/
    reg[31:0] loc_data;

    assign data = (!wr_rd && en) ? loc_data : 32'bz;
    assign exception_out = (en && ((size == 3'b010 && addr[1:0] != 0) || (size == 3'b011) || (size == 3'b001 && (addr[1:0] == 1 || addr[1:0] == 3))))? 1 : 0;

    // Add a public string that can be set from C++
    (* verilator public *) reg [8*1024-1:0] memfile_path;

    initial begin
        $display("Memory file: %s", MEMFILE);
        $readmemh(MEMFILE, mem);
    end
    always @(posedge CLK) begin
        if(wr_rd && en) begin
            case (size) 
                3'b000: begin
                    var[31:0] shift = 8 * addr[1:0];
                    var[31:0] mask = 32'b11111111 << (shift);
                    mem[addr[SIZE + 2: 2]] <= (mem[addr[SIZE + 2: 2]] & ~mask) | ((data << shift) & mask);
                end
                3'b001: begin 
                    if(addr[1:0] == 1 || addr[1:0] == 3) begin
                        //we have to throw and exception here.
                    end else begin
                        var[31:0] shift = 8 * addr[1:0];
                        var [31:0] mask = 32'hFFFF << (shift);
                        mem[addr[SIZE + 2: 2]] <= (mem[addr[SIZE + 2: 2]] & ~mask) | ((data << shift) & mask);
                    end
                end
                3'b010: begin
                    if (addr[1:0] == 0)
                        mem[addr[SIZE + 2: 2]] <= data;
                        // we don't do anything if it is not aligned. Exception will be raised instead.
                end
                default: ; //Should trhow error
            //mem[addr[SIZE + 2: 2]] <= data;
            endcase
        end
    end

    always @(posedge CLK) begin
        case (size)
            3'b000: begin
                var[31:0] shift = 8 * addr[1:0];
                var[31:0] mask = 32'hFF << (shift);
                var[31:0] temp = (mem[addr[SIZE + 2: 2]] & mask) >> shift;
                loc_data <= {{24{temp[7]}},temp [7:0]};
            end
            3'b001: begin
                if(addr[1:0] == 0 || addr[1:0] == 2) begin
                    var[31:0] shift = 8 * addr[1:0];
                    var [31:0] mask = 32'hFFFF << (shift);
                    var [31:0] temp = (mem[addr[SIZE + 2: 2]] & mask) >> shift;
                    loc_data <= {{16{temp[15]}}, temp[15:0]};
                end
                // Otherwise we will throw an exception
            end
            3'b010: begin
                if (addr[1:0] == 0)
                    loc_data <= mem[addr[SIZE + 2: 2]];
                //otherwise we wil throw an exception
            end
            3'b100: begin
                var[31:0] shift = 8 * addr[1:0];
                var[31:0] mask = 32'hFF << (shift);
                loc_data <= (mem[addr[SIZE + 2: 2]] & mask) >> shift;
            end
            3'b101: begin
                if(addr[1:0] == 0 || addr[1:0] == 2) begin
                    var[31:0] shift = 8 * addr[1:0];
                    var [31:0] mask = 32'hFFFF << (shift);
                    loc_data <= (mem[addr[SIZE + 2: 2]] & mask) >> shift;
                end
            end
            default: ; //Should throw error

        endcase
        //loc_data <= mem[addr[SIZE + 2: 2]];
    end

endmodule
