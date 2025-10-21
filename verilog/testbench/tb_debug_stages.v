module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting debug stages test");

    // Reset
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Load TCM memory
    for (i=0;i<131072;i=i+1)
        mem[i] = 0;

    f = $fopen("./build/tcm.bin", "rb");
    i = $fread(mem, f);
    $fclose(f);
    for (i=0;i<131072;i=i+1)
        u_mem.write(i, mem[i]);
end

initial
begin
    forever
    begin
        clk = #5 ~clk;
    end
end

// Monitor for test completion
reg test_results_printed;
reg [31:0] stage0, stage1, stage2, stage3, stage4, stage5, marker;
reg [63:0] mem_word;
initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if PC reaches CSR write instruction
        if (!test_results_printed && u_dut.u_exec0.opcode_pc_i == 32'h800000D8) begin
            // Wait 5 cycles for stores to complete
            repeat (5) @(posedge clk);

            // Read results from memory
            mem_word = u_mem.u_ram.ram[14'h1200];
            stage0 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1201];
            stage1 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1202];
            stage2 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1203];
            stage3 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1204];
            stage4 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1205];
            stage5 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1206];
            marker = mem_word[31:0];

            $display("");
            $display("==========================================================");
            $display("Bit Reversal Debug - Stage by Stage Analysis:");
            $display("==========================================================");
            $display("Initial:  0x%08h (should be 0xFFFFFFFF)", stage0);
            $display("Stage 1:  0x%08h (swap 16-bit halves, should be 0xFFFFFFFF)", stage1);
            $display("Stage 2:  0x%08h (swap bytes, should be 0xFFFFFFFF)", stage2);
            $display("Stage 3:  0x%08h (swap nibbles, should be 0xFFFFFFFF)", stage3);
            $display("Stage 4:  0x%08h (swap 2-bit pairs, should be 0xFFFFFFFF)", stage4);
            $display("Stage 5:  0x%08h (swap individual bits, FINAL, should be 0xFFFFFFFF)", stage5);
            $display("Marker:   0x%08h (should be 0xC0FFEE00)", marker);
            $display("");

            if (stage0 != 32'hFFFFFFFF) begin
                $display("ERROR: Initial value corrupted!");
                $display("  Expected: %b", 32'hFFFFFFFF);
                $display("  Got:      %b", stage0);
                $display("  Diff:     %b", stage0 ^ 32'hFFFFFFFF);
            end

            if (stage1 != 32'hFFFFFFFF) begin
                $display("ERROR: Stage 1 corrupted!");
                $display("  Expected: %b", 32'hFFFFFFFF);
                $display("  Got:      %b", stage1);
                $display("  Diff:     %b", stage1 ^ 32'hFFFFFFFF);
            end

            if (stage2 != 32'hFFFFFFFF) begin
                $display("ERROR: Stage 2 corrupted!");
                $display("  Expected: %b", 32'hFFFFFFFF);
                $display("  Got:      %b", stage2);
                $display("  Diff:     %b", stage2 ^ 32'hFFFFFFFF);
            end

            if (stage3 != 32'hFFFFFFFF) begin
                $display("ERROR: Stage 3 corrupted!");
                $display("  Expected: %b", 32'hFFFFFFFF);
                $display("  Got:      %b", stage3);
                $display("  Diff:     %b", stage3 ^ 32'hFFFFFFFF);
            end

            if (stage4 != 32'hFFFFFFFF) begin
                $display("ERROR: Stage 4 corrupted!");
                $display("  Expected: %b", 32'hFFFFFFFF);
                $display("  Got:      %b", stage4);
                $display("  Diff:     %b", stage4 ^ 32'hFFFFFFFF);
            end

            if (stage5 != 32'hFFFFFFFF) begin
                $display("ERROR: Stage 5 (FINAL) corrupted!");
                $display("  Expected: %b", 32'hFFFFFFFF);
                $display("  Got:      %b", stage5);
                $display("  Diff:     %b", stage5 ^ 32'hFFFFFFFF);
            end

            $display("==========================================================");
            $display("");

            test_results_printed = 1;
            $finish;
        end
    end
end

// Timeout after 50000 cycles
initial
begin
    repeat (50000) @(posedge clk);
    $display("TIMEOUT: Test reached 50000 cycles");
    $finish;
end

wire          mem_i_rd_w;
wire          mem_i_flush_w;
wire          mem_i_invalidate_w;
wire [ 31:0]  mem_i_pc_w;
wire [ 31:0]  mem_d_addr_w;
wire [ 31:0]  mem_d_data_wr_w;
wire          mem_d_rd_w;
wire [  3:0]  mem_d_wr_w;
wire          mem_d_cacheable_w;
wire [ 10:0]  mem_d_req_tag_w;
wire          mem_d_invalidate_w;
wire          mem_d_writeback_w;
wire          mem_d_flush_w;
wire          mem_i_accept_w;
wire          mem_i_valid_w;
wire          mem_i_error_w;
wire [ 63:0]  mem_i_inst_w;
wire [ 31:0]  mem_d_data_rd_w;
wire          mem_d_accept_w;
wire          mem_d_ack_w;
wire          mem_d_error_w;
wire [ 10:0]  mem_d_resp_tag_w;

riscv_core
u_dut
(
     .clk_i(clk)
    ,.rst_i(rst)
    ,.mem_d_data_rd_i(mem_d_data_rd_w)
    ,.mem_d_accept_i(mem_d_accept_w)
    ,.mem_d_ack_i(mem_d_ack_w)
    ,.mem_d_error_i(mem_d_error_w)
    ,.mem_d_resp_tag_i(mem_d_resp_tag_w)
    ,.mem_i_accept_i(mem_i_accept_w)
    ,.mem_i_valid_i(mem_i_valid_w)
    ,.mem_i_error_i(mem_i_error_w)
    ,.mem_i_inst_i(mem_i_inst_w)
    ,.intr_i(1'b0)
    ,.reset_vector_i(32'h80000000)
    ,.cpu_id_i('b0)
    ,.mem_d_addr_o(mem_d_addr_w)
    ,.mem_d_data_wr_o(mem_d_data_wr_w)
    ,.mem_d_rd_o(mem_d_rd_w)
    ,.mem_d_wr_o(mem_d_wr_w)
    ,.mem_d_cacheable_o(mem_d_cacheable_w)
    ,.mem_d_req_tag_o(mem_d_req_tag_w)
    ,.mem_d_invalidate_o(mem_d_invalidate_w)
    ,.mem_d_writeback_o(mem_d_writeback_w)
    ,.mem_d_flush_o(mem_d_flush_w)
    ,.mem_i_rd_o(mem_i_rd_w)
    ,.mem_i_flush_o(mem_i_flush_w)
    ,.mem_i_invalidate_o(mem_i_invalidate_w)
    ,.mem_i_pc_o(mem_i_pc_w)
);

tcm_mem
u_mem
(
     .clk_i(clk)
    ,.rst_i(rst)
    ,.mem_i_rd_i(mem_i_rd_w)
    ,.mem_i_flush_i(mem_i_flush_w)
    ,.mem_i_invalidate_i(mem_i_invalidate_w)
    ,.mem_i_pc_i(mem_i_pc_w)
    ,.mem_d_addr_i(mem_d_addr_w)
    ,.mem_d_data_wr_i(mem_d_data_wr_w)
    ,.mem_d_rd_i(mem_d_rd_w)
    ,.mem_d_wr_i(mem_d_wr_w)
    ,.mem_d_cacheable_i(mem_d_cacheable_w)
    ,.mem_d_req_tag_i(mem_d_req_tag_w)
    ,.mem_d_invalidate_i(mem_d_invalidate_w)
    ,.mem_d_writeback_i(mem_d_writeback_w)
    ,.mem_d_flush_i(mem_d_flush_w)
    ,.mem_i_accept_o(mem_i_accept_w)
    ,.mem_i_valid_o(mem_i_valid_w)
    ,.mem_i_error_o(mem_i_error_w)
    ,.mem_i_inst_o(mem_i_inst_w)
    ,.mem_d_data_rd_o(mem_d_data_rd_w)
    ,.mem_d_accept_o(mem_d_accept_w)
    ,.mem_d_ack_o(mem_d_ack_w)
    ,.mem_d_error_o(mem_d_error_w)
    ,.mem_d_resp_tag_o(mem_d_resp_tag_w)
);

endmodule
