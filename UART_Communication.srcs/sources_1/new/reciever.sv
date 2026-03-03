`timescale 1ns / 1ps

module reciever(
    input logic i_clk, 
    input logic i_rst,
    input logic i_tick_16x_en, // baud_generator input
    input logic i_uart_rx_in,
    output logic [7:0] o_rx_data,
    output logic o_frame_error 
    );
    
    logic [3:0] baud_counter; // Counts from 1 - > 8 ticks : take sample at 8th tick
    logic [2:0] bit_counter; // Counts bits sampled
    logic [8:0] shift_reg; // 1 - bit shift reg for serialized storage : Extra bit for Frame Error detect

    typedef enum logic [2:0] {
        S_IDLE = 3'b000,
        S_INIT = 3'b001,
        S_READ = 3'b010,
        S_UPDATE = 3'b011,
        S_CHECK_BITS = 3'b100,
        S_DONE = 3'b101
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
            S_IDLE: if (!i_uart_rx-In) next_state = S_INIT; 
            S_INIT: begin
                if (baud_counter == 4'b1000 && i_uart_rx_in == 1'b0) next_state = S_READ; // Count 16 baud ticks -> start of data when LOW bit input
                else next_state = S_INIT; // INIT state is baud_counter ++ until 16 ticks
            end
            S_READ:  begin
                if (baud_counter == 4'b0100) next_state = S_UPDATE; // Sample at 8th tick
                else next_state = S_READ; // READ state unti baud_counter == 8
            end
            S_UPDATE: next_state = S_CHECK_BITS;
            S_CHECK_BITS: begin
                if (bit_counter == 3'b100) next_state = S_DONE;
                else next_state = S_READ; // Loop back into read until bit counter is 8
            end 
            S_DONE: next_state = S_IDLE; // Automatic after 
            default: next_state = S_IDLE;
        endcase
    end

    // Output Logic
    always_comb begin
        baud_counter = 4'b0000;
        bit_counter = 3'b000;
        shift_reg = 8'b00000000; // Reset Shift Reg.

        case (current_state)
            S_IDLE: baud_counter = 4'b0000; // Resets Baud Counter to 0
            S_INIT: baud_counter = baud_counter + 4'b0001;
            S_READ: 

        endcase 
    end


/*
    // Next State Logic
    always_comb begin
        next_state = current_state;
        case(current_state)
            S_IDLE: if(!i_uart_rx_in) next_state = S_INIT;
            S_INIT: begin
                if (baud_counter == 4'b1000 && i_uart_rx_in == 1'b0) next_state = S_READ; // Initialize -> Count 16 baud to move on
                else next_state = S_INIT;
            end
            S_READ: if (baud_counter == 4'b0100) next_state = S_UPDATE; // Sample at 8th baud tick
            S_UPDATE: next_state = S_CHECK_BITS;
            S_CHECK_BITS: begin
                if (bit_counter == 3'b100) next_state = S_CHECK_ERROR;
                else next_state = S_READ;
                end
            S_CHECK_ERROR: next_state = S_DONE;
            S_DONE: if(i_rst) next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    // Output Logic 
    always_comb begin
        baud_counter = 3'b000;
        bit_counter = 3'b000;
        shift_reg = 8'b00000000;

        case (current_state)
            S_IDLE: begin
                baud_counter = 3'b000;
            end
            S_INIT: begin
                baud_counter = baud_counter + 3'b001; // Needs to count to 8 to read
            end 
            S_READ: begin
                baud_counter = baud_counter + 3'b001;
            end
            S_UPDATE: begin
                shift_reg[bit_counter] <= i_uart_rx_in; // Shift serialized input into correct index
                baud_counter = 3'b000;
                bit_counter = bit_counter + 3'b001;
            end
            S_CHECK_ERROR: begin
                assign o_frame_error = shift_reg[8]; 
            end
            S_DONE: begin
                o_rx_data <= shift_reg;
            end
        endcase
    end 
*/
endmodule