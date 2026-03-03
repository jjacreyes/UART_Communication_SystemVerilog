`timescale 1ns / 1ps

module uart_tb();

    localparam int unsigned BAUD_PERIOD = 1 / 9600.0 * 1_000_000_000;  // in ns for 9600 baud
    localparam int unsigned CLOCK_PERIOD = 10; // in ns for 100MHz

    logic sys_clk;
    logic sys_rst;

    // UART Receiver signals
    logic [7:0] rx_data;
    logic uart_rx_in;
    logic frame_error;

    // UART Transmitter signals
    logic transmit_btn;
    logic [7:0] tx_data;
    logic uart_tx_out;
    logic transmit;


    // Testbench Receiver simulation signals
    logic byte_sent;
    logic [3:0] byte_num;
    string data;

    // Testbench Transmitter simulation signals
   // logic [7:0] received_data;

    // Generate the testbench clock
    always #(CLOCK_PERIOD/2) sys_clk = ~sys_clk;

    // Instantiate the UART DUT
    uart_top dut (
        .i_sys_clk(sys_clk),
        .i_sys_rst(sys_rst),

        // UART Receiver
        .i_uart_rx_in(uart_rx_in),
        .o_rx_data(rx_data),
        .o_frame_error(frame_error),

    // UART Transmitter
        .i_transmit_btn(transmit_btn),
        .i_tx_data(tx_data),
        .o_uart_tx_out(uart_tx_out)

    );

    // To avoid waiting for the debouncer, this assignment directly drives the transmit signal for the transmitter
    // assign dut.transmit = transmit;


    initial begin
        // Normal reset procedure
        sys_clk = 0;
        sys_rst = 1;
        tx_data = 0;
        transmit_btn = 0;
        transmit = 0;
        uart_rx_in = 1;

        #100;
        sys_rst = 0;

        // Since uart_top is being simulated, we need to wait for the clock generator to lock.
        // In simple terms, the clock generator needs some time to stabilize before we start sending data.
        wait (dut.clk_gen.locked);
        #500;

        // =====================================
        // UART Receiver test case
        // =====================================
        // UART Receiver test case: Send the character 'A' (ASCII 41 in hex, 65 in decimal) from the transmitter to the receiver
        data = "A";

        // Send a byte from the testbench to the DUT receiver
        send_uart_byte(data);
        wait (byte_sent);

        // A bit of idle time at the end
        #100;


        // =====================================
        // UART Transmitter test case
        // =====================================
        // TODO: Add UART Transmitter test case
        // Set the data to be transmitted...

        // Wait some time...
       #100;


        // Assert the internal transmit signal to start transmission
        transmit = 1;
        #100
        transmit = 0;

        

        // Write a task to capture the data from uart_tx_out...
        receive_uart_byte();

    end

    // Task to simulate the sending of a byte over the UART RX line
    // In SystemVerilog, a task is like a function but it can contain timing controls (like # delays)
    // They are useful for encapsulating repetitive sequences of operations in testbenches. Here, we use a task to simulate sending a byte.
    task automatic send_uart_byte(input string data);

        logic [7:0] b;
        b = data[0];

        // Use this signal to indicate when the full 8-bit byte has been sent
        byte_sent = 0;

        // Send a start bit (logic 0)
        uart_rx_in <= 1'b0;
        byte_num = 0;

        #(BAUD_PERIOD);

        // Data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            uart_rx_in <= b[i];
            byte_num = byte_num + 1;

            #(BAUD_PERIOD);
        end

        // Send a stop bit (logic 1)
        uart_rx_in <= 1'b1;
        byte_num = byte_num + 1;

        #(BAUD_PERIOD);

        // Indicate that the byte has been sent
        byte_sent = 1;

        // Keep the channel idle (logic high)
        uart_rx_in <= 1'b1;
    endtask

    // Task to simulate receiving a byte over the UART TX line
    // This task will monitor the uart_tx_out line and reconstruct the byte being transmitted
    task automatic receive_uart_byte();
        received_data = 0;
        // TODO: Implement this task to capture data from uart_tx_out
        // You can store it in the received_data variable
        
    endtask


endmodule
