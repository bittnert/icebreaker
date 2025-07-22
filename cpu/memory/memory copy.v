
    module memory #(parameter SIZE=5) (
    input CLK,
    input [31:0] data_in,
    output [31:0] data_out,
    input wr_rd,
    input en,
    input [SIZE + 2: 0] addr,
    input [2:0] size,
    output exception_out
);
/*verilator tracing_on*/
    reg [31:0] mem [2**SIZE: 0] /*verilator public_flat_rd*/;
    /* verilator tracing_off*/

    reg[31:0] loc_data;

    assign exception_out = (en && ((size == 3'b010 && addr[1:0] != 0) || (size == 3'b011) || (size == 3'b001 && (addr[1:0] == 1 || addr[1:0] == 3))))? 1 : 0;
    assign data_out = loc_data;
    //Declare temporary variables
    reg[31:0] shift;
    reg[31:0] mask;
    reg[31:0] temp;

    always @(posedge CLK) begin
        if(wr_rd && en) begin
            case (size) 
                3'b000: begin
                    shift = 8 * addr[1:0];
                    mask = 32'b11111111 << (shift);
                    mem[addr[SIZE + 2: 2]] <= (mem[addr[SIZE + 2: 2]] & ~mask) | ((data_in << shift) & mask);
                end
                3'b001: begin 
                    if(addr[1:0] == 1 || addr[1:0] == 3) begin
                        //we have to throw and exception here.
                    end else begin
                        shift = 8 * addr[1:0];
                        mask = 32'hFFFF << (shift);
                        mem[addr[SIZE + 2: 2]] <= (mem[addr[SIZE + 2: 2]] & ~mask) | ((data_in << shift) & mask);
                    end
                end
                3'b010: begin
                    if (addr[1:0] == 0)
                        mem[addr[SIZE + 2: 2]] <= data_in;
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
                shift = 8 * addr[1:0];
                mask = 32'hFF << (shift);
                temp = (mem[addr[SIZE + 2: 2]] & mask) >> shift;
                loc_data <= {{24{temp[7]}},temp [7:0]};
            end
            3'b001: begin
                if(addr[1:0] == 0 || addr[1:0] == 2) begin
                    shift = 8 * addr[1:0];
                    mask = 32'hFFFF << (shift);
                    temp = (mem[addr[SIZE + 2: 2]] & mask) >> shift;
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
                shift = 8 * addr[1:0];
                mask = 32'hFF << (shift);
                loc_data <= (mem[addr[SIZE + 2: 2]] & mask) >> shift;
            end
            3'b101: begin
                if(addr[1:0] == 0 || addr[1:0] == 2) begin
                    shift = 8 * addr[1:0];
                    mask = 32'hFFFF << (shift);
                    loc_data <= (mem[addr[SIZE + 2: 2]] & mask) >> shift;
                end
            end
            default: ; //Should throw error

        endcase
        //loc_data <= mem[addr[SIZE + 2: 2]];
    end

endmodule
