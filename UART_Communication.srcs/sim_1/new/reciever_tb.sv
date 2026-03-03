`timescale 1ns / 1ps

module reciever_tb();

    logic i_clk;
    logic i_rst;
    logic i_tick_16x_en;
    logic i_uart_rx_in;
    logic [7:0] o_rx_data;
    logic o_frame_error;

    reciever dut(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_tick_16x_en(i_tick_16x_en),
        .o_rx_data(o_rx_data),
        .o_frame_error(o_frame_error)
    );

    // 1 - bit takes ~ 104160 ns
    always #10 clk = ~clk;
    always #(1/9600) i_tick_16x_en = ~i_tick_16x_en;

    initial begin
        clk = 0;
        i_tick_16x_en = 0;
        i_rst = 0;
        o_rx_data = 8'b00000000;
        o_frame_error = 1'b0;
        i_uart_rx_in = 1'b1; // Start in Idle

        // reset pulse
        i_rst = 1; 
        #10;
        i_rst = 0;
        #10;

        // LOW to start reading data
        i_uart_rx_in = 1'b0; // start reading
        #104160 // length of a single bit

        // ASCII "A" = 01000001
        i_uart_rx_in = 1'b0; // start reading
        #104160;
        i_uart_rx_in = 1'b1; // start reading
        #104160;
        i_uart_rx_in = 1'b0; // start reading
        #104160;
        i_uart_rx_in = 1'b0; // start reading
        #104160;
        i_uart_rx_in = 1'b0; // start reading
        #104160;
        i_uart_rx_in = 1'b0; // start reading
        #104160;
        i_uart_rx_in = 1'b0; // start reading
        #104160;
        i_uart_rx_in = 1'b1; // start reading
        #104160;

        #100;
    end
    

endmodule