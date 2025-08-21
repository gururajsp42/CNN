`timescale 1ps/1ps
module conv2d_1filter_mac_5x5 #(
    parameter DATA_WIDTH = 8,
    parameter OUT_WIDTH  = 16
)(
    input  logic                      clk,
    input  logic                      rst,
    input  logic                      valid_in,
    input  logic signed [DATA_WIDTH-1:0]     px[0:24],   // 5x5 window pixels
    input  logic signed [DATA_WIDTH-1:0]     kernel[0:24], // 5x5 kernel
    input  logic signed [OUT_WIDTH-1:0]      bias,
    output logic                      valid_out,
    output logic signed [OUT_WIDTH-1:0]      out
);

// ===== Stage 1: Latch inputs when valid =====
logic signed [DATA_WIDTH-1:0] px_reg[0:24];
logic signed [DATA_WIDTH-1:0] kernel_reg[0:24];
logic valid_s1;

always_ff @(posedge clk) begin
    if (rst) begin
        px_reg     <= '{default:'0};
        kernel_reg <= '{default:'0};
        valid_s1   <= 1'b0;
    end else begin
        if (valid_in) begin
            for (int i = 0; i < 25; i++) begin
                px_reg[i]     <= px[i];
                kernel_reg[i] <= kernel[i];
            end
        end
        valid_s1 <= valid_in;
    end
end

// ===== Stage 2: Multiply only if valid =====
logic signed [OUT_WIDTH-1:0] mul[0:24];
logic valid_s2;

always_ff @(posedge clk) begin
    if (rst) begin
        mul       <= '{default:'0};
        valid_s2  <= 1'b0;
    end else begin
        if (valid_s1) begin
            for (int i = 0; i < 25; i++) begin
                mul[i] <= $signed(px_reg[i]) * $signed(kernel_reg[i]);
            end
        end
        valid_s2 <= valid_s1;
    end
end

// ===== Stage 3: Sum only if valid =====
logic signed [OUT_WIDTH-1:0] sum_reg;
logic valid_s3;

always_ff @(posedge clk) begin
    if (rst) begin
        sum_reg  <= '0;
        valid_s3 <= 1'b0;
    end else begin
        if (valid_s2) begin
            sum_reg <= mul[0] + mul[1] + mul[2] + mul[3] + mul[4]
                     + mul[5] + mul[6] + mul[7] + mul[8] + mul[9]
                     + mul[10] + mul[11] + mul[12] + mul[13] + mul[14]
                     + mul[15] + mul[16] + mul[17] + mul[18] + mul[19]
                     + mul[20] + mul[21] + mul[22] + mul[23] + mul[24]
                     + bias;
        end
        valid_s3 <= valid_s2;
    end
end

// ===== Stage 4: Output only if valid =====
always_ff @(posedge clk) begin
    if (rst) begin
        out       <= '0;
        valid_out <= 1'b0;
    end else begin
        if (valid_s3) begin
            out <= sum_reg;
        end
        valid_out <= valid_s3;
    end
end

endmodule
