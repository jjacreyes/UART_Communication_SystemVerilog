`timescale 1ns / 1ps

module baud_generator #(
    parameter int unsigned F_CLK_HZ = 100_000_000,  // FPGA clock
    parameter int unsigned BAUD = 9600,  // desired baud rate
    parameter int unsigned OVERSAMPLE = 16,  // 16× oversampling
    parameter int unsigned ACC_WIDTH = 32  // NCO accumulator width
) (
    input logic i_clk,
    input logic i_rst,
    output logic o_tick_16x_en  // 1-cycle pulse @ rate of BAUD*OVERSAMPLE
);
    /*========================= DO NOT EDIT BEGINS ===============================*/
    /*========================= DO NOT EDIT BEGINS ===============================*/
    /*========================= DO NOT EDIT BEGINS ===============================*/

    // INCREMENT = round( (BAUD*OVERSAMPLE / F_CLK_HZ) * 2^ACC_WIDTH )
    localparam longint unsigned INCREMENT = ((BAUD * OVERSAMPLE) << ACC_WIDTH) / F_CLK_HZ;
    logic [ACC_WIDTH:0] accumulator;

    always_ff @(posedge i_clk) begin
        // NCO accumulate
        {o_tick_16x_en, accumulator[ACC_WIDTH-1:0]} <= accumulator[ACC_WIDTH-1:0] + INCREMENT;

        if (i_rst) begin
            accumulator <= '0;
            o_tick_16x_en <= 1'b0;
        end
    end

    /*========================= DO NOT EDIT ENDS ===============================*/
    /*========================= DO NOT EDIT ENDS ===============================*/
    /*========================= DO NOT EDIT ENDS ===============================*/
endmodule
