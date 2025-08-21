`timescale 1ps/1ps
module line_buffer_5x5 #(
    parameter IMG_WIDTH , 
    parameter data// image width in pixels
)(
    input  logic           clk,
    input  logic           rst,
    input  logic           valid_in,
    input  logic signed [data-1:0] px_in,

    output logic signed [data-1:0] window[0:24],  // 5x5 = 25 pixels
    output logic           valid_out
);

    // Row buffers (4 lines)
    logic signed [data-1:0] line0[0:IMG_WIDTH-1];
    logic signed [data-1:0] line1[0:IMG_WIDTH-1];
    logic signed [data-1:0] line2[0:IMG_WIDTH-1];
    logic signed [data-1:0] line3[0:IMG_WIDTH-1];

    // Column and row counters
    logic [$clog2(IMG_WIDTH)-1:0] col;
    logic [$clog2(IMG_WIDTH)-1:0] row_cnt;

    // Shift registers for each of the 5 rows (5 elements each)
    logic signed [data-1:0] shift_reg0[0:4];
    logic signed [data-1:0] shift_reg1[0:4];
    logic signed [data-1:0] shift_reg2[0:4];
    logic signed [data-1:0] shift_reg3[0:4];
    logic signed [data-1:0] shift_reg4[0:4];

    // Output valid only when we have filled at least 4 rows and 4 cols
    assign valid_out = valid_in && (row_cnt >= 4) && (col >= 4);

    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            col      <= 0;
            row_cnt  <= 0;

            // Clear buffers for simulation safety
            for (i = 0; i < IMG_WIDTH; i++) begin
                line0[i] <= 0;
                line1[i] <= 0;
                line2[i] <= 0;
                line3[i] <= 0;
            end
            for (i = 0; i < 5; i++) begin
                shift_reg0[i] <= 0;
                shift_reg1[i] <= 0;
                shift_reg2[i] <= 0;
                shift_reg3[i] <= 0;
                shift_reg4[i] <= 0;
            end

        end else if (valid_in) begin
            // Update column and row counters
            if (col == IMG_WIDTH - 1) begin
                col <= 0;
                row_cnt <= row_cnt + 1;
            end else begin
                col <= col + 1;
            end

            // Shift each shift_reg to right by 1
            for (i = 4; i > 0; i = i - 1) begin
                shift_reg4[i] <= shift_reg4[i-1];
                shift_reg3[i] <= shift_reg3[i-1];
                shift_reg2[i] <= shift_reg2[i-1];
                shift_reg1[i] <= shift_reg1[i-1];
                shift_reg0[i] <= shift_reg0[i-1];
            end

            // Insert newest pixels at shift_reg[x][0]
            shift_reg4[0] <= px_in;
            shift_reg3[0] <= line3[col];
            shift_reg2[0] <= line2[col];
            shift_reg1[0] <= line1[col];
            shift_reg0[0] <= line0[col];

            // Update line buffers (shift rows down)
            line0[col] <= line1[col];
            line1[col] <= line2[col];
            line2[col] <= line3[col];
            line3[col] <= px_in;
        end
    end

    // Map window output (5x5)
    always_comb begin
        // Row 0 (top)
        window[ 0] = shift_reg0[4];
        window[ 1] = shift_reg0[3];
        window[ 2] = shift_reg0[2];
        window[ 3] = shift_reg0[1];
        window[ 4] = shift_reg0[0];

        // Row 1
        window[ 5] = shift_reg1[4];
        window[ 6] = shift_reg1[3];
        window[ 7] = shift_reg1[2];
        window[ 8] = shift_reg1[1];
        window[ 9] = shift_reg1[0];

        // Row 2
        window[10] = shift_reg2[4];
        window[11] = shift_reg2[3];
        window[12] = shift_reg2[2];
        window[13] = shift_reg2[1];
        window[14] = shift_reg2[0];

        // Row 3
        window[15] = shift_reg3[4];
        window[16] = shift_reg3[3];
        window[17] = shift_reg3[2];
        window[18] = shift_reg3[1];
        window[19] = shift_reg3[0];

        // Row 4 (bottom)
        window[20] = shift_reg4[4];
        window[21] = shift_reg4[3];
        window[22] = shift_reg4[2];
        window[23] = shift_reg4[1];
        window[24] = shift_reg4[0];
    end

endmodule
