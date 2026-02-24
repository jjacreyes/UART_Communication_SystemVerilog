`timescale 1ns / 1ps

module reciever(
    input logic i_clk, 
    input logic i_rst,
    input logic i_tick_16x_en, // baud_generator input
    input logic i_uart_rx_in,
    output logic [7:0] o_rx_data,
    output logic o_frame_error 
    );
    
    logic [2:0] baud_counter; // Counts from 1 - > 8 ticks : take sample at 8th tick
    logic [2:0] bit_counter; // Counts bits sampled
    logic [8:0] shift_reg; // 1 - bit shift reg for serialized storage : Extra bit for Frame Error detect

    typedef enum logic [2:0] {
        S_IDLE = 3'b000,
        S_INIT = 3'b001,
        S_READ = 3'b010,
        S_UPDATE = 3'b011,
        S_CHECK_BITS = 3'b100,
        S_CHECK_ERROR = 3'b101,
        S_DONE = 3'b110
    } state_t;
    
    state_t current_state, next_state;


    // Reset logic
    always_ff @ (posedge clk or posedge rst) begin
        if (rst) begin
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
            S_IDLE: if(!i_uart_rx_in) next_state = S_INIT;
            S_INIT: begin
                if (baud_counter == 3'b100 && i_uart_rx_in == 1'b0) next_state = S_READ;
                else next_state = S_INIT;
            end
            S_READ: if (baud_counter == 3'b100) next_state = S_UPDATE;
            S_UPDATE: next_state = S_CHECK_BITS;
            S_CHECK_BITS: begin
                if (bit_counter == 3'b100) next_state = S_CHECK_ERROR;
                else S_READ;
                end
            S_CHECK_ERROR: next_state = S_DONE;
            S_DONE: if(rst) next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase

    end

    // Output Logic 
    always_comb begin
        buad_counter = 3'b000;
        bit_counter = 3'b000;
        shift_reg = 8'b00000000;

        case (current_state)
            S_IDLE: begin
                baud_counter = 3'b000;
            end
            S_INIT: begin
                baud_counter = baud_counter + 3'b001;
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
    
endmodule
