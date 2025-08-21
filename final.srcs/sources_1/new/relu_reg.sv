`timescale 1ps/1ps
module relu_reg #(
    parameter DW_IN  = 16,    // wide enough for conv sum
    parameter DW_OUT = 16     // optional truncate width
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     valid_in,
    input  logic signed [DW_IN-1:0]  in,
    output logic signed [DW_OUT-1:0] out,
    output logic                     valid_out
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            out       <= '0;
            valid_out <= 1'b0;
        end else begin
            if (in < 0)
                out <= '0;
            else
                out <= in[DW_OUT-1:0]; // truncation only
            valid_out <= valid_in;
        end
    end
endmodule
