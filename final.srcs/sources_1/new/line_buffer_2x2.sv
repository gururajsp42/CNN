`timescale 1ps/1ps
module line_buffer_2x2 #(
    parameter W , // feature-map width after conv/relu
    parameter DW 
)(
    input  logic              clk,
    input  logic              rst,     // active-high synchronous reset
    input  logic              en,      // 1 px/cycle
    input  logic signed [DW-1:0] px_in,
    output logic              win_valid,
    output logic signed [DW-1:0] w00, w01, w10, w11 // 2x2 window
);
    // one row delay
    logic signed [DW-1:0] row_buf [0:W-1];
    logic [$clog2(W)-1:0] col;

    // 2-tap shift registers for current and delayed rows
    logic signed [DW-1:0] cur0, cur1;
    logic signed [DW-1:0] del0, del1;

    integer i;
    always_ff @(posedge clk) begin
        if (rst) begin
            col  <= '0;
            cur0 <= '0; cur1 <= '0;
            del0 <= '0; del1 <= '0;
            win_valid <= 1'b0;
            for (i = 0; i < W; i = i + 1)
                row_buf[i] <= '0;
        end else if (en) begin
            // column counter
            col <= (col == W-1) ? '0 : col + 1;

            // shift current row
            cur1 <= cur0;
            cur0 <= px_in;

            // read previous row, then shift
            del1 <= del0;
            del0 <= row_buf[col];

            // write current pixel into row buffer for next row use
            row_buf[col] <= px_in;

            win_valid <= (col != 0); // valid after first column in a row
        end
    end

    assign w00 = del1;
    assign w01 = del0;
    assign w10 = cur1;
    assign w11 = cur0;

endmodule
