`timescale 1ps / 1ps
       
module fc_400x120_120mac_pipeline #(
  parameter int IN_WIDTH    = 16,    // input fixed-point width (signed)
  parameter int W_WIDTH     = 8,     // weight fixed-point width (signed)
  parameter int N_INPUTS    = 400,
  parameter int N_NEURONS   = 120,
  parameter int PROD_WIDTH  = IN_WIDTH + W_WIDTH,
  parameter int ACC_WIDTH   = PROD_WIDTH + $clog2(N_INPUTS) + 2
)(
  input  logic                               clk,
  input  logic                               rst,
  input  logic                               start,        // pulse to start
  output logic                               done, 
  input  logic relu_en,        // high one cycle at end

  // Input feature RAM: indexed 0..N_INPUTS-1
  input  logic signed [IN_WIDTH-1:0]         input_ram [N_INPUTS],

  // Weight RAM: weight_ram[neuron][input_index]
  input  logic signed [W_WIDTH-1:0]          weight_ram [N_NEURONS][N_INPUTS],

  // Biases for each neuron
  input  logic signed [ACC_WIDTH-1:0]        bias_ram [N_NEURONS],

  // Output RAM for 120 neurons
  output logic signed [ACC_WIDTH-1:0]        output_ram [N_NEURONS]
);

  typedef enum logic [2:0] {IDLE, RUN, FLUSH, WRITE, DONE} state_t;
  state_t state;

  // input index
  logic [$clog2(N_INPUTS)-1:0] in_idx;

  // accumulators
  logic signed [ACC_WIDTH-1:0] acc [N_NEURONS];

  // pipeline registers for product
  logic signed [PROD_WIDTH-1:0] prod_reg [N_NEURONS];
  logic                         prod_valid;  // tracks pipeline stage valid

  // done flag
  logic done_r;

  // FSM
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state   <= IDLE;
      in_idx  <= 0;
      done_r  <= 1'b0;
      prod_valid <= 1'b0;
      for (int n = 0; n < N_NEURONS; n++) begin
        acc[n]        <= '0;
        prod_reg[n]   <= '0;
        output_ram[n] <= '0;
      end
    end else begin
      done_r <= 1'b0;

      case (state)

        IDLE: begin
          if (start) begin
            in_idx     <= 0;
            prod_valid <= 1'b0;
            // preload biases
            for (int n = 0; n < N_NEURONS; n++)
              acc[n] <= bias_ram[n];
            state <= RUN;
          end
        end

        RUN: begin
          // stage 1: compute products for current input
          logic signed [IN_WIDTH-1:0] current_input;
          current_input = input_ram[in_idx];
          for (int n = 0; n < N_NEURONS; n++)
            prod_reg[n] <= $signed(current_input) * $signed(weight_ram[n][in_idx]);
          prod_valid <= 1'b1;

          // stage 2: accumulate previous cycle's products
          if (prod_valid) begin
            for (int n = 0; n < N_NEURONS; n++)
              acc[n] <= acc[n] + $signed(prod_reg[n]);
          end

          // advance input index
          if (in_idx == N_INPUTS-1) begin
            state <= FLUSH; // need one extra cycle to add last prods
          end else begin
            in_idx <= in_idx + 1;
          end
        end

        FLUSH: begin
          // final accumulation of last prod_reg
          if (prod_valid) begin
            for (int n = 0; n < N_NEURONS; n++)
              acc[n] <= acc[n] + $signed(prod_reg[n]);
          end
          prod_valid <= 1'b0;
          state <= WRITE;
        end
        
        WRITE: begin
           for (int n = 0; n < N_NEURONS; n++) begin
            if (relu_en) begin
      // ReLU activation
              if (acc[n][ACC_WIDTH-1] == 1'b1) 
                output_ram[n] <= '0;     // clamp negative to 0
              else
                output_ram[n] <= acc[n];
                end else begin
      // Direct pass-through (no activation)
                output_ram[n] <= acc[n];
              end
               end
                 state <= DONE;
                end
        
        
                  // In module port
        DONE: begin
          done_r <= 1'b1;   // pulse done
          state  <= IDLE;
        end

      endcase
    end
  end

  assign done = done_r;

endmodule
