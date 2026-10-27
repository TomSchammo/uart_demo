module uart (
    input logic rst,
    input  logic       clk,   // 27 MHz oscillator, pin 4
    output logic [5:0] led,    // 6 onboard LEDs (active-low), pins 15-20
    output logic uart_tx
);

    logic [7:0] baud_counter;

    // transmit 16 bit words
    logic [15:0] counter;
    logic [3:0] bit_index;
    logic [15:0] idle_counter;

    // send 8 bits per window
    logic [2:0] bit_counter;

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;

    state_t state;


    always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
        baud_counter <= 8'd0;
        counter      <= 16'd0;
        bit_index    <= 4'd0;
        bit_counter  <= 3'd0;
        state        <= START;
        uart_tx      <= 1'b1;
        led          <= 6'b111110;
        idle_counter <= 16'd0;
      end else begin
        led[0]       <= 1'b1;
        baud_counter <= baud_counter + 1'b1;

        if (baud_counter == 8'd234) begin
          baud_counter <= 8'd0;

          unique case (state)
          START: begin
            uart_tx <= 1'b0;
            state <= DATA;
          end
          DATA: begin
            uart_tx <= counter[bit_index];
            bit_index <= bit_index + 1'b1;

            // has one window been sent
            if (bit_counter == 3'd7) begin
              bit_counter <= 3'd0;
              state <= STOP;
            end else begin
              bit_counter <= bit_counter + 1'b1;
            end
          end
          STOP: begin
            uart_tx <= 1'b1;

            // continue transmitting
            if (bit_index != 4'b0) begin
              state <= START;
            end else begin
              state <= IDLE;
            end
          end
          IDLE: begin
            idle_counter <= idle_counter + 1'b1;
            if (idle_counter == 16'hffff) begin
              led[5]       <= ~led[5];
              counter <= counter + 1'b1;
              state <= START;
            end
          end
        endcase
      end
    end
  end

endmodule
