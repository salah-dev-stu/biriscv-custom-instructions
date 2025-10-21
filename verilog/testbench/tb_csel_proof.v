module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting CSEL Proof Test (Max/Min Array Finder)");

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
reg signed [31:0] max_result, min_result;
reg [31:0] marker;
reg [63:0] mem_word;
initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if marker has been written to memory (completion signal)
        mem_word = u_mem.u_ram.ram[14'h1206];  // 0x80009030 / 8 = 0x1206 (marker at offset 48)
        marker = mem_word[31:0];

        if (!test_results_printed && marker == 32'hDEADBEEF) begin
            // Wait 5 cycles for stores to complete
            repeat (5) @(posedge clk);

            // Read results from memory at 0x80009000
            // Max stored at 0x80009000, Min at 0x80009004
            mem_word = u_mem.u_ram.ram[14'h1200];  // 0x80009000 / 8 = 0x1200
            max_result = mem_word[31:0];
            min_result = mem_word[63:32];  // Min at upper 32 bits

            mem_word = u_mem.u_ram.ram[14'h1206];  // 0x80009030 / 8 = 0x1206 (marker at offset 48)
            marker = mem_word[31:0];

            $display("");
            $display("==========================================================");
            $display("CSEL Proof Test Results (Max/Min Array Finder):");
            $display("==========================================================");
            $display("Array: [100, 5, -200, 77, 3, -9, 250, -1]");
            $display("");
            $display("Result       | Expected | Actual   | Status");
            $display("-------------|----------|----------|--------");

            $write("Maximum      | 250      | %0d", max_result);
            if (max_result == 250) begin
                $display("      | PASS");
            end else begin
                $display("      | FAIL");
            end

            $write("Minimum      | -200     | %0d", min_result);
            if (min_result == -200) begin
                $display("     | PASS");
            end else begin
                $display("     | FAIL");
            end

            $write("Marker       | 0xDEADBEEF | 0x%08h | ", marker);
            if (marker == 32'hDEADBEEF) begin
                $display("PASS");
            end else begin
                $display("FAIL");
            end

            $display("==========================================================");
            $display("");

            if (max_result == 250 && min_result == -200 && marker == 32'hDEADBEEF) begin
                $display("==========================================");
                $display("Result: ALL TESTS PASSED!");
                $display("CSEL instruction correctly finds max/min");
                $display("==========================================");
            end else begin
                $display("==========================================");
                $display("Result: TESTS FAILED");
                $display("==========================================");
            end
            $display("");

            test_results_printed = 1;
            $finish;
        end
    end
end

// Timeout after 10000 cycles
initial
begin
    repeat (10000) @(posedge clk);
    $display("TIMEOUT: Test reached 10000 cycles without completion");
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
