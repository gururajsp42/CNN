`timescale 1ps/1ps
module conv_layer2 #(
    parameter int DATA_WIDTH   = 16,   // width of window pixels & weights
    parameter int OUT_WIDTH    = 16,   // output width after accumulation (quantized to 16-bit)
    parameter int IN_CHANNELS  = 6,
    parameter int OUT_CHANNELS = 16,
    parameter int K            = 5
)(
    input  logic clk,
    input  logic rst,

    // One 5x5 window per input channel, all valid in the same cycle
    input  logic                       valid_in,
    input  logic signed [DATA_WIDTH-1:0] win     [0:IN_CHANNELS-1][0:K*K-1],

    // Weights arranged as [out_ch][in_ch][kernel_flat]
    input  logic signed [DATA_WIDTH-1:0] kernel  [0:OUT_CHANNELS-1][0:IN_CHANNELS-1][0:K*K-1],
    input  logic signed [DATA_WIDTH-1:0]  bias    [0:OUT_CHANNELS-1],

    // Output: one value per out-channel for the current spatial position
    output logic                        valid_out,
    output logic signed [OUT_WIDTH-1:0] cout     [0:OUT_CHANNELS-1]
);

    // ---------------------------------------------------------------
    // Width planning
    localparam int NTERMS     = IN_CHANNELS * K * K;
    localparam int ACC_WIDTH  = (2*DATA_WIDTH) + $clog2(NTERMS) + 2;

    // ----------------------------------------------------------------
    // Pipeline Stage 1: latch the 6×25 input window
    logic                           v_s1;
    logic signed [DATA_WIDTH-1:0]   win_s1 [0:IN_CHANNELS-1][0:K*K-1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            v_s1 <= 1'b0;
            for (int c = 0; c < IN_CHANNELS; c++)
                for (int i = 0; i < K*K; i++)
                    win_s1[c][i] <= '0;
        end else begin
            v_s1 <= valid_in;
            if (valid_in)
                for (int c = 0; c < IN_CHANNELS; c++)
                    for (int i = 0; i < K*K; i++)
                        win_s1[c][i] <= win[c][i];
        end
    end

    // ----------------------------------------------------------------
    // Pipeline Stage 2: MAC across 6 channels × 5×5 for each OUT_CHANNEL
    logic                           v_s2;
    logic signed [ACC_WIDTH-1:0]    acc_s2 [0:OUT_CHANNELS-1];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            v_s2 <= 1'b0;
            for (int oc = 0; oc < OUT_CHANNELS; oc++) acc_s2[oc] <= '0;
        end else begin
            v_s2 <= v_s1;
            if (v_s1) begin
                for (int oc = 0; oc < OUT_CHANNELS; oc++) begin
                    logic signed [ACC_WIDTH-1:0] s;
                    s = {{(ACC_WIDTH-DATA_WIDTH){bias[oc][DATA_WIDTH-1]}}, bias[oc]}; // sign-extend bias
                    for (int ic = 0; ic < IN_CHANNELS; ic++)
                        for (int i = 0; i < K*K; i++)
                            s += $signed(win_s1[ic][i]) * $signed(kernel[oc][ic][i]);
                    acc_s2[oc] <= s;
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // Pipeline Stage 3: Output register + ReLU + quantization to 16-bit
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 1'b0;
            for (int oc = 0; oc < OUT_CHANNELS; oc++) cout[oc] <= '0;
        end else begin
            valid_out <= v_s2;
            if (v_s2) begin
                for (int oc = 0; oc < OUT_CHANNELS; oc++) begin
                    // ReLU: remove negative values
                    logic signed [ACC_WIDTH-1:0] relu_val;
                    relu_val = acc_s2[oc][ACC_WIDTH-1] ? '0 : acc_s2[oc];
                    // Quantize/truncate to 16-bit
                    if (relu_val > 16'sh7FFF)
                        cout[oc] <= 16'sh7FFF;
                    else
                        cout[oc] <= relu_val[15:0];
                end
            end
        end
    end
endmodule
