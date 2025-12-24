`include "cpu.vh"

module load_store (
    input CLK,
    input [31:0] addr, 
    input [31:0] data_in,
    output [31:0] data_out,
    input en,
    input [2:0] size,
    input wr,
    input reset,
    output exception_out,
    input RX,
    output TX
);

    wire [31:0] rom_data, ram_data, uart_data_out, timer_counter;
    wire rom_exception;
    wire ram_exception;
    wire [7:0] uart_data_in;
    wire uart_en, ram_en, rom_en, timer_en;
    reg last_uart_en, last_ram_en, last_rom_en, last_timer_en;
    wire [3:0] ram_mask; 
    assign uart_en = (en && (addr[31:24] == 8'h02));
    assign ram_en = (en && (addr[31:24] == 8'h01));
    assign rom_en = (en && (addr[31:24] == 8'h00));
    assign timer_en = (en && (addr[31:24] == 8'h03));
    assign exception_out = (rom_exception || ram_exception);
    assign data_out = (last_ram_en && !wr)? ram_data : (last_uart_en && !wr)? uart_data_out : (last_rom_en) ? rom_data: (last_timer_en)? timer_counter : 32'h00000000;
    assign ram_mask = (ram_en) ? 4'hF: 4'h0;
    //assign data_out = uart_data_out;

    always @(posedge CLK) begin
        last_ram_en <= ram_en;
        last_uart_en <= uart_en;
        last_rom_en  <= rom_en;
        last_timer_en <= timer_en;
    end

    rom #(.SIZE(10), .MEMFILE("bootloader/bootloader.mem")) bootloader (
                                                .CLK(CLK), 
                                                .addr(addr[10 + 2:0]),
                                                .size(size),
                                                .data(rom_data),
                                                .exception_out(rom_exception),
                                                .en(rom_en),
                                                .reset(reset));
    
    /*
    memory #(.SIZE($clog2(512))) main_ram (
        .CLK(CLK),
        .data_out(ram_data),
        .data_in(data_in),
        .wr_rd(wr),
        .en(ram_en),
        .addr(addr[$clog2(512) + 2:0]),
        .size(size),
        .exception_out(ram_exception)
    );
    */
    /*
    memory main_ram (.CLK(CLK),
        .din(data_in),
        .addr(addr[11:0]),
        .write_en(wr),
        .dout(ram_data));
        */
   /* 
    ram main_ram (.clk(CLK),
        .we(ram_mask),
        .addr,
        .data_in(data_in),
        .data_out(ram_data));
*/
    memory main_ram (.CLK(CLK),
        .data_in(data_in),
        .data_out(ram_data),
        .addr(addr),
        .wr(wr),
        .en(ram_en),
        .size(size),
        .exception(ram_exception));

    uart_mem_interface uart (
        .CLK (CLK ),
        .addr(addr[1:0]),
        .data_in(data_in),
        .data_out(uart_data_out),
        .reset(reset),
        .en(uart_en),
        .wr(wr),
        .TX(TX),
        .RX(RX)
    );

    timer timer (.CLK(CLK),
                .rst(reset),
                .counter_out(timer_counter));
endmodule
