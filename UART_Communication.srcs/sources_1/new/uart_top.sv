`timescale 1ns / 1ps

module uart_top #(
    parameter int unsigned F_CLK_HZ   = 100_000_000,
    parameter int unsigned BAUD       = 9600,
    parameter int unsigned OVERSAMPLE = 16
) (
    input logic i_sys_clk,
    input logic i_sys_rst,
    input logic i_transmit_btn,
    output logic [7:0] o_rx_data,
    input logic [7:0] i_tx_data,
    input logic i_uart_rx_in,
    output logic o_uart_tx_out,
    output logic o_frame_error
);
    /*========================= DO NOT EDIT BEGINS ===============================*/
    /*========================= DO NOT EDIT BEGINS ===============================*/
    /*========================= DO NOT EDIT BEGINS ===============================*/
    logic clk, rst;
    logic locked;
    logic tick_16x_en;
    logic transmit;

    // Clock generator module
    clk_wiz_0 clk_gen (
        .clk_in1 (i_sys_clk),
        .reset   (i_sys_rst),
        .locked  (locked),
        .clk_out1(clk)
    );

    proc_sys_reset_0 rst_gen
    (
      .slowest_sync_clk(clk),
      .ext_reset_in(i_sys_rst),
      .aux_reset_in('0),
      .mb_debug_sys_rst('0),
      .dcm_locked(locked),    
      .mb_reset(),
      .bus_struct_reset(),
      .peripheral_reset(rst),
      .interconnect_aresetn(), 
      .peripheral_aresetn() 
    );

    // Transmit button debouncer module
    debouncer #(
        .DEBOUNCE_COUNT(500_000)
    ) debounce_transmit (
        .i_clk(clk),
        .i_rst(rst),
        .i_btn_in(i_transmit_btn),
        .o_btn_out(transmit)
    );

    // Baud rate generator module
    baud_generator #(
        .F_CLK_HZ(F_CLK_HZ),
        .BAUD(BAUD),
        .OVERSAMPLE(OVERSAMPLE)
    ) u_baud (
        .i_clk(clk),
        .i_rst(rst),
        .o_tick_16x_en(tick_16x_en)
    );


    /*========================= DO NOT EDIT ENDS ===============================*/
    /*========================= DO NOT EDIT ENDS ===============================*/
    /*========================= DO NOT EDIT ENDS ===============================*/

    // TODO: Create the receiver and transmitter instances here
    // For transmitter: use signals clk, rst, tick_16x_en, transmit, i_tx_data, o_uart_tx_out
    // For receiver:    use signals clk, rst, tick_16x_en, o_frame_error, o_rx_data, i_uart_rx_in
    reciever rx (
        .i_clk(clk),
        .i_rst(rst),
        .i_tick_16x_en(tick_16x_en),
        .i_uart_rx_in(i_uart_rx_in),
        .o_rx_data(o_rx_data),
        .o_frame_error(o_frame_error)
    );

    transmitter tx (
        .i_clk(clk),
        .i_rst(rst),
        .i_tick_16x_en(tick_16x_en),
        .i_transmit(transmit),
        .i_tx_data(i_tx_data),
        .o_uart_tx_out(o_uart_tx_out)
    );
    
    // TODO: Instantiate ILA and add connections


endmodule
