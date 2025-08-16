    module rom #(parameter SIZE=5, parameter MEMFILE="data.mem") (
    input CLK,
    output reg [31:0] data,
    //input [31:0] data_in,
    //input wr,
    input [SIZE + 2: 0] addr,
    input [2:0] size,
    input en,
    output exception_out,
    input reset
);
/*verilator tracing_on*/
    reg [31:0] mem [2**SIZE: 0] /*verilator public_flat_rd*/;
    /* verilator tracing_off*/
    reg [31:0] read_data;
    reg [SIZE + 2:0] last_addr;
    reg [2:0] last_size;

    assign exception_out = (en && ((size == 3'b010 && addr[1:0] != 0) || (size == 3'b011) || (size == 3'b001 && (addr[1:0] == 1 || addr[1:0] == 3))))? 1 : 0;

    initial begin
        $readmemh(MEMFILE, mem);
    end

    always @(posedge CLK) begin
        if (reset == 1'b0) begin
            read_data <= mem[0];
            last_addr <= 0;
            last_size <= 3'b010;
        end else begin
            read_data <= mem[addr[SIZE + 2: 2]];
            last_addr <= addr;
            last_size <= size;
        end
    end

    always @(*) begin
        case (last_size)
            3'b000: begin
                case (last_addr[1:0])
                    2'b00: data = {{24{read_data[7]}}, read_data[7:0]};
                    2'b01: data = {{24{read_data[15]}}, read_data[15:8]};
                    2'b10: data = {{24{read_data[23]}}, read_data[23:16]};
                    2'b11: data = {{24{read_data[31]}}, read_data[31:24]};
                endcase
            end
            3'b001: begin
                case (last_addr[1:0])
                    2'b00: data = {{16{read_data[7]}}, read_data[15:0]};
                    2'b10: data = {{16{read_data[31]}}, read_data[31:16]};
                    default: data = 0;
                endcase
            end
            3'b010: begin
                case (last_addr[1:0])
                    2'b00: data = read_data;
                    default: data = 0;
                endcase
            end
            3'b100: begin
                case(last_addr[1:0])
                    2'b00: data = {{24'h0}, read_data[7:0]};
                    2'b01: data = {{24'h0}, read_data[15:8]};
                    2'b10: data = {{24'h0}, read_data[23:16]};
                    2'b11: data = {{24'h0}, read_data[31:24]};
                endcase
            end
            3'b101: begin
                case (last_addr[1:0])
                    2'b00: data = {{16'h0}, read_data[15:0]};
                    2'b10: data = {{16'h0}, read_data[31:16]};
                    default: data = 0;
                endcase
            end
            default: begin
                data  = 0;
            end 
        endcase
    end
/*
    always @(posedge clk) begin
        if (wr & en) begin
            case(size) begin

                3'b000: mem[addr[SIZE + 2: 2]] <= data_in;
                end
            endcase
        end
    end
*/
/*
    always @(posedge CLK) begin
        case (size)
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
            end
            3'b010: begin
                case (addr[1:0])
                    2'b00: data <= mem[addr[SIZE + 2: 2]];
                    default: data <= 0;
                endcase
            end
            3'b100: begin
                case(addr[1:0])
                    2'b00: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][7:0]};
                    2'b01: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][15:8]};
                    2'b10: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][23:16]};
                    2'b11: data <= {{24'h0}, mem[addr[SIZE + 2: 2]][31:24]};
                endcase
            end
            3'b101: begin
                case (addr[1:0])
                    2'b00: data <= {{16'h0}, mem[addr[SIZE+2:2]][15:0]};
                    2'b10: data <= {{16'h0}, mem[addr[SIZE+2:2]][31:16]};
                    default: data <= 0;
                endcase
            end
            default: begin
                data  <= 0;
            end 
        endcase
    end
*/
endmodule
