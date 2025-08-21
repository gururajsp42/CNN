`timescale 1ps/1ps
module cnn_layer_6filters #(
    parameter DATA_WIDTH = 8,
    parameter OUT_WIDTH  = 16,
    parameter IMG_WIDTH  = 32
)(
    input  logic          clk,
    input  logic          rst,
    input  logic          valid_in,
  
    output logic          pred_valid,
    
 

    
    
    input  logic signed [DATA_WIDTH-1:0]  px_in,
    
    input  logic signed [DATA_WIDTH-1:0]  kernels[0:5][0:24],  
    input  logic signed [OUT_WIDTH-1:0]   biases[0:5],
   
     
    input  logic signed [15:0]  bias    [0:15],
    input  logic signed [15:0]  kernel  [0:15][0:5][0:24],
    
    
    input   logic signed [7:0]       weight_ram [120][400],
    input   logic signed [34:0]      bias_ram [120],
    
    
    
    input  logic signed [7:0]           fc2_weights [80][120],
    input  logic signed [50:0]          fc2_bias[80],
    
    
    
  
    input  logic signed [7:0]           fc3_weights [10][80],
    input  logic signed [64:0]          fc3_bias[10],
    
      output logic [3:0] pred_class
   

    
);

 
    logic      buf_valid;
    logic      valid_out; 
    logic      max_valid[0:5]; 
    logic      relu_valid [0:5];
    logic      buf_2x2_valid[0:5];
    logic      buf_valid_2nd[0:5];
    logic      win_valid[0:15];
    logic      valid_outcon;
    wire       all2_valid;
    logic      fc_start;
    logic      done;
    logic      max2_valid[0:15];
    logic      fc2_done;
    logic      relu_en;
    logic [5:0] conv_valids;
   
    logic signed [15:0] w0 [0:5], w1 [0:5], w2 [0:5], w3 [0:5]; 
    logic signed [OUT_WIDTH-1:0]  out[0:5];  
    logic signed [15:0] relu_out   [0:5]; 
    logic signed [DATA_WIDTH-1:0] window[0:24];
    logic signed [15:0] window_2nd[0:5][0:24];
    logic signed [7:0] window1[0:24];
    logic signed [15:0] pool1_out[0:5];
    logic signed [15:0] w00[0:15], w01[0:15], w10[0:15], w11[0:15]; 
    logic signed [15:0]  cout    [0:15];
    logic [15:0] fc_inputs    [0:399];
    logic signed [15:0]   max2_out[0:15];
    
    logic signed [34:0]        output_ram [120];
  
    logic signed [50:0]        fc2_outputs [80];
    
    logic signed [64:0]          fc3_outputs [10];
    
 
    line_buffer_5x5 #(
        .IMG_WIDTH(32),.data(8)
    ) lb (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .px_in(px_in),
        .window(window),
        .valid_out(buf_valid)
    );
  assign window1=window;
    
    
    
    genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : conv_filters
            conv2d_1filter_mac_5x5 #(
                .DATA_WIDTH(DATA_WIDTH),
                .OUT_WIDTH(OUT_WIDTH)
            ) conv (
                .clk(clk),
                .rst(rst),
                .valid_in(buf_valid),
                .px(window),
                .kernel(kernels[i]),
                .bias(biases[i]),
                .valid_out(conv_valids[i]),         // Ignored here; top valid_out comes from line buffer latency + conv latency
                .out(out[i])
            );
        end
    endgenerate


    // valid_out sync: since conv module latency is 3 cycles after valid_in,
    // here valid_out = buf_valid delayed by conv latency (3 cycles)
assign valid_out = |conv_valids;




generate
    for (i = 0; i < 6; i++) begin : relu_gen
        relu_reg relu_inst (
            .clk       (clk),
            .rst(rst),
            .valid_in  (valid_out),
            .in        (out[i]),
            .out       (relu_out[i]),
            .valid_out (relu_valid[i])
        );
    end
endgenerate


generate
    for (i = 0; i < 6; i++) begin : line_buffer_2x2_gen
        line_buffer_2x2#(.DW(16),.W(28)) linear_buffer (
       .clk(clk),.rst(rst),
                .en(relu_valid[i]),      // 1 px/cycle
   .px_in(relu_out[i]),
   .win_valid( buf_2x2_valid[i]),
   .w00(w0[i]), .w01(w1[i]), .w10(w2[i]), .w11(w3[i]) // 2x2 window
);
    end
endgenerate





generate
    for (i = 0; i < 6; i++) begin : max_pool1_gen
       maxpool2x2_stride2 max_pool1 (
     .clk(clk),
     .rst(rst),
   .win_valid(buf_2x2_valid[i]),
    .w00(w0[i]), .w01(w1[i]), .w10(w2[i]), .w11(w3[i]),
    .out_valid(max_valid[i]),
  .out(pool1_out[i])
);
    end
endgenerate




generate
    for (i = 0; i < 6; i++) begin : linear_5x5_gen
     line_buffer_5x5 # (
        .IMG_WIDTH(14),.data(16))
        linear_5x5 (
        .clk(clk),
        .rst(rst),
        .valid_in(max_valid[i]),
        .px_in(pool1_out[i]),
        .window(window_2nd[i]),
        .valid_out(buf_valid_2nd[i])
    );
    end
endgenerate


logic all_valid; 
assign all_valid =buf_valid_2nd[0] & buf_valid_2nd[1] & buf_valid_2nd[2] & buf_valid_2nd[3] & buf_valid_2nd[4] & buf_valid_2nd[5];


conv_layer2 conv2_inst (
    .clk(clk),
    .rst(rst),
    .valid_in(all_valid),
    .bias(bias),
    .kernel(kernel),
    .win(window_2nd),
    .valid_out(valid_outcon),
    .cout(cout) 
);



generate
    for (i = 0; i <16; i++) begin : line2x2_gen
     line_buffer_2x2 # (
        .DW(16),.W(10))
        line2x2p (
    .clk(clk),
    .rst(rst),     
    .en(valid_outcon),    
    .px_in(cout[i]),
    .win_valid(win_valid[i]),
     .w00(w00[i]), .w01(w01[i]), .w10(w10[i]), .w11(w11[i])
    );
    end
endgenerate



generate
    for (i = 0; i <16; i++) begin : max_gen
     maxpool2x2_stride2 # (.DW(16))
        maxp (
               .clk(clk),
               .rst(rst),
               .win_valid(win_valid[i]),
               .w00(w00[i]), .w01(w01[i]), .w10(w10[i]), .w11(w11[i]),
               .out_valid( max2_valid[i]),
               .out(max2_out[i])
               );
       end
endgenerate


assign all2_valid = max2_valid[0]&max2_valid[1]&max2_valid[2]&max2_valid[3]&max2_valid[4]&max2_valid[5]&max2_valid[6]&max2_valid[7]&max2_valid[8]&max2_valid[9]&max2_valid[10]&max2_valid[11]&max2_valid[12]&max2_valid[13]&max2_valid[14]&max2_valid[15];


maxpool_to_fc_buffer #(.DW(16), .IN_CH(16), .TOTAL_IN(400)) buf_inst (
    .clk(clk),
    .rst(rst),
    .max_out(max2_out),      
    .valid_in(all2_valid),   
    .fc_in(fc_inputs),       
    .fc_valid(fc_start) ,
    .fc_done(pred_valid)   
);




fc_400x120_120mac_pipeline #()
fc_400(
         .clk(clk),
         .rst(rst),
         
         .start(fc_start),              
         .relu_en(1'b1),
         .input_ram(fc_inputs),
         .weight_ram(weight_ram),
         .bias_ram(bias_ram),
         
         .done(done),  
         .output_ram(output_ram)
);




fc_400x120_120mac_pipeline #(.IN_WIDTH(35) , .W_WIDTH (8),  .N_INPUTS (120) , .N_NEURONS(80), .PROD_WIDTH(43),.ACC_WIDTH(51))
fc_120 (
    .clk        (clk),
    .rst        (rst),
    .relu_en(1'b1),
    
    .start      (done),
    .input_ram  (output_ram), 
      
    .weight_ram (fc2_weights),   
    .bias_ram   (fc2_bias),
    .done       (fc2_done),
    .output_ram (fc2_outputs)    
    );


fc_400x120_120mac_pipeline #( .IN_WIDTH(51) , .W_WIDTH (8),  .N_INPUTS (80) , .N_NEURONS(10), .PROD_WIDTH(59),.ACC_WIDTH(65))
fc_80 (
    .clk        (clk),
    .rst        (rst),
    .relu_en(1'b0),
    
    .start      (fc2_done),
    .input_ram  (fc2_outputs),   
    .weight_ram (fc3_weights),   
    .bias_ram   (fc3_bias),
    
    .done       (fc3_done),
    .output_ram (fc3_outputs)    
);

argmax #(
  .N_CLASSES (10),
  .DATA_WIDTH(65)   // ACC_WIDTH from fc3
) argmax_inst (
  .clk       (clk),
  .rst       (rst),
  .start     (fc3_done),      // when FC3 is finished
  .in_vec    (fc3_outputs),   // 10 outputs from FC3
  .class_idx (pred_class),    // predicted class index
  .valid     (pred_valid)     // 1-cycle high
);


endmodule
