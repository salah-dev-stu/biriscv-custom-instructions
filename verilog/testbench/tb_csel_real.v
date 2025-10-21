module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting CSEL Real-World Program Test");

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
reg signed [31:0] max_val, min_val, sum_val, abs_val, branch_val, hazard_val1, hazard_val2;
reg signed [31:0] swap_arr[0:4];
reg [31:0] marker;
reg [63:0] mem_word;
integer pass_count, fail_count;

initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if marker has been written to memory (completion signal)
        mem_word = u_mem.u_ram.ram[14'h240C];  // 0x80009030 / 4 = 0x240C (marker at offset 48)
        marker = mem_word[31:0];

        if (!test_results_printed && marker == 32'hDEADBEEF) begin
            // Wait 10 cycles for all stores to complete
            repeat (10) @(posedge clk);

            // Read all results from memory at 0x80009000
            mem_word = u_mem.u_ram.ram[14'h2400];  max_val = mem_word[31:0];       // 0x00: max
            mem_word = u_mem.u_ram.ram[14'h2401];  min_val = mem_word[31:0];       // 0x04: min
            mem_word = u_mem.u_ram.ram[14'h2402];  sum_val = mem_word[31:0];       // 0x08: conditional sum
            mem_word = u_mem.u_ram.ram[14'h2403];  abs_val = mem_word[31:0];       // 0x0C: abs accumulator
            mem_word = u_mem.u_ram.ram[14'h2404];  branch_val = mem_word[31:0];    // 0x10: branch interaction
            mem_word = u_mem.u_ram.ram[14'h2405];  hazard_val1 = mem_word[31:0];   // 0x14: data hazard result
            mem_word = u_mem.u_ram.ram[14'h2406];  hazard_val2 = mem_word[31:0];   // 0x18: data hazard t6
            mem_word = u_mem.u_ram.ram[14'h2407];  swap_arr[0] = mem_word[31:0];   // 0x1C: array[0]
            mem_word = u_mem.u_ram.ram[14'h2408];  swap_arr[1] = mem_word[31:0];   // 0x20: array[1]
            mem_word = u_mem.u_ram.ram[14'h2409];  swap_arr[2] = mem_word[31:0];   // 0x24: array[2]
            mem_word = u_mem.u_ram.ram[14'h240A];  swap_arr[3] = mem_word[31:0];   // 0x28: array[3]
            mem_word = u_mem.u_ram.ram[14'h240B];  swap_arr[4] = mem_word[31:0];   // 0x2C: array[4]
            mem_word = u_mem.u_ram.ram[14'h240C];  marker = mem_word[31:0];        // 0x30: marker

            pass_count = 0;
            fail_count = 0;

            $display("");
            $display("===============================================================");
            $display("CSEL Real-World Program Test Results:");
            $display("===============================================================");
            $display("");

            // Test 1: Array Max/Min Finder
            $display("Test 1: Array Max/Min Finder");
            $display("  Array: [42, -17, 99, -5, 63, -88, 7, 0]");
            $write("  Maximum: Expected=99, Actual=%0d ", max_val);
            if (max_val == 99) begin
                $display("PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL");
                fail_count = fail_count + 1;
            end

            $write("  Minimum: Expected=-88, Actual=%0d ", min_val);
            if (min_val == -88) begin
                $display("PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL");
                fail_count = fail_count + 1;
            end
            $display("");

            // Test 2: Conditional Sum (positive values only)
            $display("Test 2: Conditional Sum (positive values only)");
            $display("  Array: [10, -5, 20, -15, 30, -25, 40]");
            $write("  Sum: Expected=100, Actual=%0d ", sum_val);
            if (sum_val == 100) begin
                $display("PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL");
                fail_count = fail_count + 1;
            end
            $display("");

            // Test 3: Branchless Absolute Value
            $display("Test 3: Branchless Absolute Value");
            $display("  abs(-42) + abs(17) + abs(-99) + abs(0) + abs(255)");
            $write("  Sum: Expected=413, Actual=%0d ", abs_val);
            if (abs_val == 413) begin
                $display("PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL");
                fail_count = fail_count + 1;
            end
            $display("");

            // Test 4: CSEL with Branch Interactions
            $display("Test 4: CSEL with Branch Interactions");
            $write("  Branch accumulator result: %0d ", branch_val);
            if (branch_val != 0) begin
                $display("PASS (non-zero)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL (zero)");
                fail_count = fail_count + 1;
            end
            $display("");

            // Test 5: CSEL with Data Hazards
            $display("Test 5: CSEL with Data Hazards (RAW)");
            $write("  Hazard chain results: val1=%0d, val2=%0d ", hazard_val1, hazard_val2);
            if (hazard_val1 != 0 && hazard_val2 != 0) begin
                $display("PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL");
                fail_count = fail_count + 1;
            end
            $display("");

            // Test 6: Conditional Array Swap
            $display("Test 6: Conditional Array Swap (Bubble sort one pass)");
            $display("  Original: [30, 10, 50, 20, 40]");
            $display("  After 1 pass: [%0d, %0d, %0d, %0d, %0d]",
                     swap_arr[0], swap_arr[1], swap_arr[2], swap_arr[3], swap_arr[4]);
            // After one bubble sort pass: [10, 30, 20, 40, 50] - largest moved to end
            if (swap_arr[4] == 50) begin
                $display("  PASS - Largest element moved to end");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL - Largest element not in correct position");
                fail_count = fail_count + 1;
            end
            $display("");

            // Check completion marker
            $write("Completion Marker: Expected=0xDEADBEEF, Actual=0x%08h ", marker);
            if (marker == 32'hDEADBEEF) begin
                $display("PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL");
                fail_count = fail_count + 1;
            end

            $display("===============================================================");
            $display("");
            $display("==========================================");
            $display("Test Summary:");
            $display("==========================================");
            $display("Passed: %0d / 8", pass_count);
            $display("Failed: %0d / 8", fail_count);
            if (fail_count == 0)
                $display("Result: ALL TESTS PASSED!");
            else
                $display("Result: SOME TESTS FAILED");
            $display("==========================================");
            $display("");

            test_results_printed = 1;
            $finish;
        end
    end
end

// Timeout after 50000 cycles (complex program)
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
