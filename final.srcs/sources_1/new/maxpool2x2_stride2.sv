`timescale 1ps / 1ps
module maxpool2x2_stride2 #(
    parameter DW = 16
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     win_valid,
    input  logic signed [DW-1:0]     w00, w01, w10, w11,
    output logic                     out_valid,
    output logic signed [DW-1:0]     out
);

    // Horizontal stride-2 toggle
    logic h_toggle;
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            h_toggle <= 1'b0;
        else if (win_valid)
            h_toggle <= ~h_toggle;
    end

    // Pipeline registers for max computation
    logic signed [DW-1:0] m0, m1, m;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            m0 <= '0;
            m1 <= '0;
            m  <= '0;
        end
        else if (win_valid) begin
            m0 <= (w00 > w01) ? w00 : w01;
            m1 <= (w10 > w11) ? w10 : w11;
            m  <= (m0  > m1)  ? m0  : m1;  // uses previous cycle m0/m1
        end
    end

    // Delay out_valid to align with pipelined m
    logic out_valid_d;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            out_valid_d <= 1'b0;
        else
            out_valid_d <= win_valid && h_toggle;
    end

    // Output register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 1'b0;
            out       <= '0;
        end
        else begin
            out_valid <= out_valid_d;
            if (out_valid_d)
                out <= m;
        end
    end

endmodule
