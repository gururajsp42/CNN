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


module argmax#(
  parameter int N_CLASSES  = 10,
  parameter int DATA_WIDTH = 65
)(
  input  logic                         clk,
  input  logic                         rst,
  input  logic                         start,   // pulse
  input  logic signed [DATA_WIDTH-1:0] in_vec [N_CLASSES],

  output logic [$clog2(N_CLASSES)-1:0] class_idx,
  output logic                         valid
);

  logic [$clog2(N_CLASSES)-1:0] comb_idx;

  // Pure combinational argmax
  always_comb begin
    logic signed [DATA_WIDTH-1:0] max_val;
    logic [$clog2(N_CLASSES)-1:0] max_idx;
    max_val = in_vec[0];
    max_idx = 0;
    for (int i = 1; i < N_CLASSES; i++) begin
      if (in_vec[i] > max_val) begin
        max_val = in_vec[i];
        max_idx = i[$clog2(N_CLASSES)-1:0];
      end
    end
    comb_idx = max_idx;
  end

  // Latch output on start
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      class_idx <= '0;
      valid     <= 1'b0;
    end else begin
      valid <= 1'b0;
      if (start) begin
        class_idx <= comb_idx;
        valid     <= 1'b1; // one-cycle pulse
      end
    end
  end

endmodule
