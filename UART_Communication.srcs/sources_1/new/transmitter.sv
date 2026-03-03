`timescale 1ns / 1ps

module transmitter(
    input logic i_clk,
    input logic i_rst,
    input logic i_tick_16x_en,
    input logic [7:0] i_tx_data,
    output logic o_uart_tx_out,
    input logic i_transmit
    );
    // Considerations: LSB sent first (SW0 on FPGA)
    // include rising edge detector for transmit button
    //

    logic [4:0] baud_counter; // bits hold for 16 baud ticks
    logic [2:0] bit_counter; 
    logic [7:0] shift_reg; // temp hold for input data

    typedef enum logic [2:0] {
        S_IDLE = 3'b000,
        S_START = 3'b001,
        S_DATA = 3'b010,
        S_DONE = 3'b011
    } state_t;

    state_t current_state, next_state;

    // Reset logic
    always_ff @ (posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            current_state <= S_IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // Next State Logic
    always_comb begin
        next_state = current_state;
        case(current_state)
            S_IDLE: if (transmit_btn) next_state = S_START;
            S_START: if (baud_counter == 5'd15) next_state = S_DATA; // Hold start - bit for 16 ticks
            S_DATA: if (i_tick_16x_en && baud_counter == 5'd15 && bit_counter == 3'd7) next_state = S_STOP; // Serialize complete 8 - bits
            S_DONE: next_state = S_IDLE;
            default: S_IDLE;
        endcase
    end

    // Output Logic
    always_ff @ (posedge i_clk) begin
        if (i_rst) begin
            baud_counter <= 4'd0;
            bit_counter <= 4'd0;
            o_uart_tx_out <= 1'b0; 
            shift_reg <= 8'b0;
        end

        else if (i_tick_16x_en) begin
            case (current_state)
                S_IDLE: begin
                    baud_counter <= 4'd0;
                    bit_counter <= 3'd0;
                end
                S_START: begin
                    o_uart_tx_out <= 1'b1;
                    shift_reg <= i_uart_rx_in; 

                    if (baud_counter == 4'd15) baud_counter <= 4'd0; // 16 tick hold
                    else baud_counter <= baud_counter + 1;
                end
                S_DATA: begin
                    o_uart_tx_out <= shift_reg[0]; // Output LSB -> Shift bits down for shift_reg
                    shift_reg <= {1'b1, shift_reg[7:1]}; // Add HIGH bit for idle state

                    if (baud_counter == 5'd15) baud_counter <= 5'd0; // 16 tick hold
                    else baud_counter <= baud_counter + 1;
                    bit_counter <= bit_counter + 1;
                end
                S_DONE: begin
                    o_uart_tx_out <= shift_reg[0]; // Output new LSB -> Should be HIGH for IDLE
                end
            endcase 
        end
    end

endmodule
