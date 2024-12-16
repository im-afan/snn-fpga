/* PASSED TESTS */

/*
 * LIF Scheduler
 * Schedules LIFs (tells lif_array to enable)
 * by reading the synaptic crossbar FIFO values
 * if the FIFO is not empty, it schedules a LIF operation on that tile
 */

module lif_scheduler (
    input wire clk,
    input wire en,

    input wire lif_done,

    input wire mac_out_fifo_empty,
    input wire tile_idx_fifo_empty,

    input wire mac_out_fifo_pop_done,
    input wire tile_idx_fifo_pop_done,

    output reg mac_out_fifo_pop,
    output reg tile_idx_fifo_pop,

    output reg lif_en
);
    wire ready;
    wire pop_done;
    assign ready = ~(mac_out_fifo_empty || tile_idx_fifo_empty);
    assign pop_done = (mac_out_fifo_pop_done && tile_idx_fifo_pop_done) || ~(mac_out_fifo_pop || tile_idx_fifo_pop);

    always_ff @(posedge clk) begin
        if(~en) begin
            lif_en <= 0;
            mac_out_fifo_pop <= 0;
            tile_idx_fifo_pop <= 0;
        end else begin
            if(ready && pop_done) begin
                if(~lif_done) begin
                    lif_en <= 1;
                    mac_out_fifo_pop <= 0;
                    tile_idx_fifo_pop <= 0;
                end else begin
                    lif_en <= 0;
                    mac_out_fifo_pop <= 1;
                    tile_idx_fifo_pop <= 1;
                end
            end else begin
                lif_en <= 0;
            end
        end
    end
endmodule