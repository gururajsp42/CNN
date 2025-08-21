`timescale 1ps/1ps
module tb_cnn_layer_6filters;

    localparam DATA_WIDTH = 8;
    localparam OUT_WIDTH  = 16;
    localparam IMG_WIDTH  = 32;

    logic clk;
    logic rst;
    logic valid_in;
   logic          pred_valid;
    
    logic signed [DATA_WIDTH-1:0] px_in;
    
    // Kernels and biases
    logic signed [DATA_WIDTH-1:0] kernels[0:5][0:24];
    logic signed [OUT_WIDTH-1:0]  biases[0:5];

    // Output
    logic signed [15:0]  bias    [0:15];
    logic signed [15:0]  kernel  [0:15][0:5][0:24];
        
    logic signed [7:0]   weight_ram [0:119][0:399];   // 120x400
    logic signed [34:0]  bias_ram   [0:119];          // 120
    
    logic signed [7:0]           fc2_weights [80][120];
    logic signed [50:0]          fc2_bias[80];
    
    logic signed [7:0]           fc3_weights [10][80];
    logic signed [64:0]          fc3_bias[10];
    logic [3:0] pred_class;

    
    cnn_layer_6filters #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .IMG_WIDTH(IMG_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .px_in(px_in),
        .kernels(kernels),
        .biases(biases),
        .bias(bias),
        .kernel(kernel),
       
        .pred_valid(pred_valid),
        
        .weight_ram( weight_ram),
        .bias_ram(bias_ram),
        
        .fc2_weights(fc2_weights),
        .fc2_bias(fc2_bias),
        
        .fc3_weights(fc3_weights),
        .fc3_bias(fc3_bias),
        . pred_class(pred_class)
       
        
  
    );

    // Clock
    always #5 clk = ~clk;

    integer i, f, j, k;

    initial begin
        clk = 0;
        rst = 1;
        valid_in = 0;
        px_in = 0;

        // Reset
        #20;
        rst = 0;

        // Initialize conv kernels and biases (all 1s and 0s)
        for (i = 0; i < 6; i++) begin
            for (f = 0; f < 25; f++) begin
                kernels[i][f] = 8'sd1;
            end
            biases[i] = 16'sd0;
        end
  
        // Initialize FC1 kernel and bias (all 1s, 0s)
        for (i = 0; i <= 15; i = i + 1) begin
            for (j = 0; j <= 5; j = j + 1) begin
                for (k = 0; k <= 24; k = k + 1) begin
                    kernel[i][j][k] = 16'sd1;  
                end
            end
            bias[i] = 16'sd0;
        end

        // Initialize FC1 (400->120) weight/bias
        for (i = 0; i < 120; i++) begin
            bias_ram[i] = 35'sd0;                 // bias = 0
            for (j = 0; j < 400; j++) begin
                weight_ram[i][j] = 8'sd1;         // weights = 1
            end
        end

        // Initialize FC2 (120->80) weight/bias
        for (i = 0; i < 80; i++) begin
            fc2_bias[i] = 51'sd0;                 // bias = 0
            for (j = 0; j < 120; j++) begin
                fc2_weights[i][j] = 8'sd1;        // weights = 1
            end
        end

        // Initialize FC3 (80->10) weight/bias
        for (i = 0; i < 10; i++) begin
            fc3_bias[i] = 65'sd0;                 // bias = 0
            for (j = 0; j < 80; j++) begin
                fc3_weights[i][j] = 8'sd1;        // weights = 1
            end
        end

        // Feed a 32x32 test image with 8-bit pixel values
        @(posedge clk);
        valid_in = 1;
        
        for (i = 0; i < IMG_WIDTH*IMG_WIDTH; i++) begin
            px_in = i; // values 0-255
            $display("TX Pixel[%0d] = %0d", i, px_in);
            @(posedge clk);
        end
        valid_in = 0;

        #10000 $stop;
    end

endmodule
