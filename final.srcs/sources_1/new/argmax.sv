`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.08.2025 00:37:27
// Design Name: 
// Module Name: argmax
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module argmax #(
  parameter int N_CLASSES  = 10,    // number of outputs
  parameter int DATA_WIDTH = 65     // width of each output (ACC_WIDTH from FC3)
)(
  input  logic                     clk,
  input  logic                     rst,
  input  logic                     start,   // pulse to start argmax
  input  logic signed [DATA_WIDTH-1:0] in_vec [N_CLASSES], // input vector

  output logic [$clog2(N_CLASSES)-1:0] class_idx, // predicted class
  output logic                     valid          // high for 1 cycle when done
);

  typedef enum logic [1:0] {IDLE, SEARCH, DONE} state_t;
  state_t state;

  logic signed [DATA_WIDTH-1:0] max_val;
  logic [$clog2(N_CLASSES)-1:0] max_idx;
  logic [$clog2(N_CLASSES):0]   idx;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state     <= IDLE;
      max_val   <= '0;
      max_idx   <= '0;
      idx       <= '0;
      class_idx <= '0;
      valid     <= 1'b0;
    end else begin
      valid <= 1'b0;

      case (state)
        IDLE: begin
          if (start) begin
            max_val <= in_vec[0];
            max_idx <= 0;
            idx     <= 1;
            state   <= SEARCH;
          end
        end

        SEARCH: begin
          if (in_vec[idx] > max_val) begin
            max_val <= in_vec[idx];
            max_idx <= idx[$clog2(N_CLASSES)-1:0];
          end
          if (idx == N_CLASSES-1) begin
            class_idx <= max_idx;
            state     <= DONE;
          end else begin
            idx <= idx + 1;
          end
        end

        DONE: begin
          valid <= 1'b1;   // pulse valid
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
