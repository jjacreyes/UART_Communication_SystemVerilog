`timescale 1ns / 1ps

module reciever(
    input logic i_clk, 
    input logic i_rst,
    input logic i_tick_16x_en, // baud_generator input
    input logic i_uart_rx_in,
    output logic [7:0] o_rx_data,
    output logic o_frame_error 
    );
    
    logic [4:0] baud_counter; // Counts from 1 - > 16 ticks : take sample at 8th tick starting from prev. 8th tick
    logic [2:0] bit_counter; // Counts bits sampled
    logic [8:0] shift_reg; // 1 - bit shift reg for serialized storage : Extra bit for Frame Error detect

    typedef enum logic [2:0] {
        S_IDLE = 3'b000,
        S_START = 3'b001,
        S_READ = 3'b010,
        S_STOP = 3'b011,
        S_DONE = 3'b100
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
            S_IDLE: if (!i_uart_rx_in) next_state = S_START; // LOW bit for start
            S_START: if (baud_counter == 4'd7) next_state = S_READ; // Count to 8th ticks (8 - 1 for first tick from IDLE)
            S_READ: if (i_tick_16x_en && baud_counter == 5'd15 && bit_counter == 4'd7) next_state = S_STOP;
            S_STOP: if (i_tick_16x_en && baud_counter == 15) next_state = S_DONE; // Reads last bit to ensure stop + error frame
            S_DONE: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    // Output Logic
    always_ff @ (posedge i_clk) begin
        if (i_rst) begin
            baud_counter <= 4'd0;
            bit_counter <= 3'd0;
            shift_reg <= 8'd0;
            o_rx_data <= 8'd0;
            o_frame_error <= 1'b0;
        end

        else if (i_tick_16x_en) begin
            case (current_state)
                S_IDLE: begin
                    baud_counter <= 4'd0;
                    bit_counter <= 3'd0;
                end
                S_START: begin
                    if (baud_counter == 4'd7) baud_counter <= 4'd0;
                    else baud_counter <= baud_counter +1;
                end
                S_READ: begin
                    if (baud_counter == 15) begin // Reset baud counter for each bit
                        baud_counter <= 4'd0;
                        bit_counter <= bit_counter + 1;
                        shift_reg <= {i_uart_rx_in, shift_reg[7:1]}; // testing the shifting operation
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end
                end
                S_STOP: begin
                    if (baud_counter == 15) begin
                        o_rx_data <= shift_reg; // Samples past last data bit for error
                        o_frame_error <= !i_uart_rx_in;
                    end
                    else begin
                        baud_counter <= baud_counter + 1;

                    end
                end
                endcase
        end
    end

endmodule