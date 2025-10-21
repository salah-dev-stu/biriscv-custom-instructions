module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;
integer cycle_count;
integer instruction_count;

initial
begin
    $display("Starting Comparison Test");

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
    $display("Loaded %0d bytes from tcm.bin", i);
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

// Performance counters
initial
begin
    cycle_count = 0;
    instruction_count = 0;

    @(negedge rst);

    forever begin
        @(posedge clk);
        cycle_count = cycle_count + 1;

        // Count retired instructions from both pipes
        if (u_dut.u_issue.pipe0_valid_wb_w)
            instruction_count = instruction_count + 1;
        if (u_dut.u_issue.pipe1_valid_wb_w)
            instruction_count = instruction_count + 1;
    end
end

// Monitor for test completion
reg test_results_printed;
reg [63:0] mem_word;
reg [31:0] marker;
reg signed [31:0] max_result, min_result, sum_result, abs_result;
reg signed [31:0] branch_result, hazard_a0, hazard_t6;
reg signed [31:0] swap_0, swap_1, swap_2, swap_3, swap_4;

initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check completion marker at 0x80009030
        mem_word = u_mem.u_ram.ram[14'h1206];  // 0x80009030 / 8 = 0x1206
        marker = mem_word[31:0];

        if (!test_results_printed && marker == 32'hDEADBEEF) begin
            // Wait for all stores to complete
            repeat (5) @(posedge clk);

            // Read all test results from memory
            // Test 1: Max/Min at 0x80009000, 0x80009004
            mem_word = u_mem.u_ram.ram[14'h1200];  // 0x80009000 / 8
            max_result = mem_word[31:0];
            min_result = mem_word[63:32];

            // Test 2: Conditional sum at 0x80009008
            mem_word = u_mem.u_ram.ram[14'h1201];  // 0x80009008 / 8
            sum_result = mem_word[31:0];

            // Test 3: Abs value at 0x8000900C
            abs_result = mem_word[63:32];

            // Test 4: Branch interaction at 0x80009010
            mem_word = u_mem.u_ram.ram[14'h1202];  // 0x80009010 / 8
            branch_result = mem_word[31:0];

            // Test 5: Data hazards at 0x80009014, 0x80009018
            hazard_a0 = mem_word[63:32];
            mem_word = u_mem.u_ram.ram[14'h1203];  // 0x80009018 / 8
            hazard_t6 = mem_word[31:0];

            // Test 6: Swap results at 0x8000901C-0x8000902C
            swap_0 = mem_word[63:32];
            mem_word = u_mem.u_ram.ram[14'h1204];  // 0x80009020 / 8
            swap_1 = mem_word[31:0];
            swap_2 = mem_word[63:32];
            mem_word = u_mem.u_ram.ram[14'h1205];  // 0x80009028 / 8
            swap_3 = mem_word[31:0];
            swap_4 = mem_word[63:32];

            $display("");
            $display("==========================================================");
            $display("CSEL vs BASELINE Comparison Test Results");
            $display("==========================================================");
            $display("");
            $display("Test 1: Array Max/Min Finder");
            $display("  Maximum:  %0d (expected 99)", max_result);
            $display("  Minimum:  %0d (expected -88)", min_result);
            $display("  Status:   %s", (max_result == 99 && min_result == -88) ? "PASS" : "FAIL");
            $display("");

            $display("Test 2: Conditional Sum (positive values only)");
            $display("  Sum:      %0d (expected 100)", sum_result);
            $display("  Status:   %s", (sum_result == 100) ? "PASS" : "FAIL");
            $display("");

            $display("Test 3: Absolute Value Accumulation");
            $display("  Result:   %0d (expected 413)", abs_result);
            $display("  Status:   %s", (abs_result == 413) ? "PASS" : "FAIL");
            $display("");

            $display("Test 4: Branch Interaction");
            $display("  Result:   %0d", branch_result);
            $display("  Status:   %s", (branch_result != 0) ? "PASS" : "FAIL");
            $display("");

            $display("Test 5: Data Hazards");
            $display("  a0:       %0d", hazard_a0);
            $display("  t6:       %0d", hazard_t6);
            $display("  Status:   %s", (hazard_a0 != 0 && hazard_t6 != 0) ? "PASS" : "FAIL");
            $display("");

            $display("Test 6: Conditional Swap (one bubble sort pass)");
            $display("  Array:    [%0d, %0d, %0d, %0d, %0d]", swap_0, swap_1, swap_2, swap_3, swap_4);
            $display("  Status:   COMPLETE");
            $display("");

            $display("==========================================================");
            $display("Performance Metrics:");
            $display("==========================================================");
            $display("Total Cycles:               %0d", cycle_count);
            $display("Total Instructions Retired: %0d", instruction_count);
            $display("CPI (Cycles Per Instruction): %f", $itor(cycle_count) / $itor(instruction_count));
            $display("IPC (Instructions Per Cycle): %f", $itor(instruction_count) / $itor(cycle_count));
            $display("==========================================================");
            $display("");

            // Overall pass/fail
            if (max_result == 99 && min_result == -88 &&
                sum_result == 100 && abs_result == 413) begin
                $display("==========================================");
                $display("Result: ALL CORE TESTS PASSED!");
                $display("==========================================");
            end else begin
                $display("==========================================");
                $display("Result: SOME TESTS FAILED");
                $display("==========================================");
            end
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
    $display("TIMEOUT: Test reached 50000 cycles without completion");
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
