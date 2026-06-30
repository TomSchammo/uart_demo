module uart (
    input  wire       clk,   // 27 MHz oscillator, pin 4
    output reg [5:0] led,    // 6 onboard LEDs (active-low), pins 15-20
    output reg uart_tx
);

    initial begin
      led = 6'b111111;
      uart_tx = 1'b1;
    end

    reg [7:0] baud_counter = 8'd0;

    // transmit 16 bit words
    reg [15:0] counter = 16'd0;
    reg [3:0] bit_index = 4'd0;

    // send 8 bits per window
    reg [2:0] bit_counter = 3'd0;

    localparam
           IDLE = 2'd0,
           START = 2'd1,
           DATA  = 2'd2,
           STOP  = 2'd3;


    reg [1:0] state = START;

    // assign led[0] = 1'b0;
    // assign led[2] = 1'b0;
    // assign led[3] = 1'b0;
    // assign led[4] = 1'b0;

    always @(posedge clk) begin
      baud_counter <= baud_counter + 1'b1;

      if (baud_counter == 8'd234) begin
        baud_counter <= 8'd0;

        if (state == START) begin
          uart_tx <= 1'b0;
          state <= DATA;

        end else if (state == DATA) begin
          // has one window been sent
          if (bit_counter == 3'd7) begin
            uart_tx <= counter[bit_index];
            bit_index <= bit_index + 1'b1;
            bit_counter <= 3'd0;
            state <= STOP;
          end else begin
            uart_tx <= counter[bit_index];
            bit_counter <= bit_counter + 1'b1;
            bit_index <= bit_index + 1'b1;
          end

        end else if (state == STOP) begin
          uart_tx <= 1'b1;

          // continue transmitting
          if (bit_index != 4'b0) begin
            state <= START;
          end else begin
            // led[3] <= 1'b0;
            state <= IDLE;
            // NOTE: this branch is never reached
          end
        end else if (state == IDLE) begin
          // led[4] <= 1'b0;
          if (counter == 16'hffff) begin
            counter <= 16'b0;
          end else begin
            counter <= counter + 1'b1;
          end
          state <= START;
        end else begin
          // this should be unreachable
          // led[5] <= 1'b0;
        end
      end
    end


    // assign led = ~counter[5:0];  // active-low: invert so LEDs count visibly
    // assign led = ~counter[15:10];  // active-low: invert so LEDs count visibly
    // assign led = counter[25:20];
endmodule
