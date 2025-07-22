    module rom #(parameter SIZE=5, parameter MEMFILE="data.mem") (
    input CLK,
    output reg [31:0] data,
    input [SIZE + 2: 0] addr,
    input [2:0] size,
    input en,
    output exception_out
);
/*verilator tracing_on*/
    reg [31:0] mem [2**SIZE: 0] /*verilator public_flat_rd*/;
    /* verilator tracing_off*/

    assign exception_out = (en && ((size == 3'b010 && addr[1:0] != 0) || (size == 3'b011) || (size == 3'b001 && (addr[1:0] == 1 || addr[1:0] == 3))))? 1 : 0;

    initial begin
        $readmemh(MEMFILE, mem);
    end


    always @(posedge CLK) begin
        case (size)
        /*j
            3'b000: begin
                //data <= {{24{temp[7]}},temp [7:0]};
                data <= mem[addr[SIZE + 2: 2]] & mask;
            end
            */
            3'b000: begin
                case (addr[1:0])
                    2'b00: data <= {{24{mem[addr[SIZE+2:2]][7]}}, mem[addr[SIZE + 2: 2]][7:0]};
                    2'b01: data <= {{24{mem[addr[SIZE+2:2]][15]}}, mem[addr[SIZE + 2: 2]][15:8]};
                    2'b10: data <= {{24{mem[addr[SIZE+2:2]][23]}}, mem[addr[SIZE + 2: 2]][23:16]};
                    2'b11: data <= {{24{mem[addr[SIZE+2:2]][31]}}, mem[addr[SIZE + 2: 2]][31:24]};
                endcase
            end
            3'b001: begin
                case (addr[1:0])
                    2'b00: data <= {{16{mem[addr[SIZE+2:2]][7]}}, mem[addr[SIZE+2:2]][15:0]};
                    2'b10: data <= {{16{mem[addr[SIZE+2:2]][31]}}, mem[addr[SIZE+2:2]][31:16]};
                    default: data <= 0;
                endcase
                    /*
                if(addr[1:0] == 0 || addr[1:0] == 2) begin
                    data <= {{16{temp[15]}}, temp[15:0]};
                end else 
                    data <= 0;
                    */
                // Otherwise we will throw an exception
            end
            3'b010: begin
                case (addr[1:0])
                    2'b00: data <= mem[addr[SIZE + 2: 2]];
                    default: data <= 0;
                endcase
                /*
                if (addr[1:0] == 0)
                    //data <= mem[addr[SIZE + 2: 2]];
                    data <= temp;
                else
                    data <= 0;
                    */
                //otherwise we wil throw an exception
            end
            3'b100: begin
                case(addr[1:0])
                    2'b00: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][7:0]};
                    2'b01: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][15:8]};
                    2'b10: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][23:16]};
                    2'b11: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][31:24]};
                endcase
                //data <= (mem[addr[SIZE + 2: 2]] >> shift) & mask;
            end
            3'b101: begin
                case (addr[1:0])
                    2'b00: data <= {{16'h0}, mem[addr[SIZE+2:2]][15:0]};
                    2'b10: data <= {{16'h0}, mem[addr[SIZE+2:2]][31:16]};
                    default: data <= 0;
                endcase

/*
                if(addr[1:0] == 0 || addr[1:0] == 2) 
                    data <= (mem[addr[SIZE + 2: 2]] >> shift) & mask;
                else
                    data <= 0;
                    */
            end
            default: begin
                data  <= 0;
            end 

        endcase
        //loc_data <= mem[addr[SIZE + 2: 2]];
    end

endmodule
