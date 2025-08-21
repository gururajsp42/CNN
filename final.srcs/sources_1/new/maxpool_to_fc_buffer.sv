`timescale 1ps / 1ps
module maxpool_to_fc_buffer #(
    parameter DW       = 16,   // data width
    parameter IN_CH    = 16,   // number of parallel maxpool outputs
    parameter TOTAL_IN = 400   // FC layer input size
)(
    input  logic clk,
    input  logic rst,

    // Maxpool outputs
    input  logic [DW-1:0] max_out [0:IN_CH-1],
    input  logic          valid_in,  // all 16 are valid this cycle

    // Handshake with FC layer
    output logic [DW-1:0] fc_in [0:TOTAL_IN-1],
    output logic          fc_valid,  // high when buffer full & ready for FC
    input  logic          fc_done    // pulse from FC when finished
);

    // Internal buffer
    logic [DW-1:0] buffer [0:TOTAL_IN-1];
    logic [$clog2(TOTAL_IN):0] wr_ptr;

    typedef enum logic [1:0] {COLLECT, WAIT_FC} state_t;
    state_t state;

    // Write + handshake FSM
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr   <= 0;
            fc_valid <= 1'b0;
            state    <= COLLECT;
        end else begin
            case (state)

                COLLECT: begin
                    if (valid_in) begin
                        // Store 16 parallel values
                        integer i;
                        for (i = 0; i < IN_CH; i++) begin
                            if (wr_ptr + i < TOTAL_IN)
                                buffer[wr_ptr + i] <= max_out[i];
                        end

                        // Update write pointer
                        wr_ptr <= wr_ptr + IN_CH;

                        // Check if full
                        if (wr_ptr + IN_CH >= TOTAL_IN) begin
                            fc_valid <= 1'b1; 
                            state    <= WAIT_FC;  // switch to wait
                        end
                    end
                end

                WAIT_FC: begin
                    if (fc_done) begin
                        wr_ptr   <= 0;       // reset pointer
                        fc_valid <= 1'b0;    // deassert valid
                        state    <= COLLECT; // collect next frame
                    end
                end

            endcase
        end
    end

    // Continuous assign: expose buffer contents to FC layer
    genvar j;
    generate
        for (j = 0; j < TOTAL_IN; j++) begin : out_assign
            assign fc_in[j] = buffer[j];
        end
    endgenerate

endmodule
