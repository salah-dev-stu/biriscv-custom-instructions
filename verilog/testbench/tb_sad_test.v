module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

// Performance counters
integer instruction_count;
integer cycle_count;

// Test results
reg [31:0] test_results[6:0];  // 7 test results
integer num_passed;

initial
begin
    $display("Starting SAD instruction test");

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
    $display("Loaded %0d bytes into TCM memory", i);
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

// Performance counter: count retired instructions and cycles
initial
begin
    instruction_count = 0;
    cycle_count = 0;

    @(negedge rst);

    forever begin
        @(posedge clk);
        cycle_count = cycle_count + 1;

        // Count pipe0 instruction retirement
        if (u_dut.u_issue.pipe0_valid_wb_w) begin
            instruction_count = instruction_count + 1;
        end

        // Count pipe1 instruction retirement (dual-issue core)
        if (u_dut.u_issue.pipe1_valid_wb_w) begin
            instruction_count = instruction_count + 1;
        end
    end
end

// Monitor for test completion (CSR write)
initial
begin
    @(negedge rst);

    // Wait for CSR write to complete
    forever begin
        @(posedge clk);
        // Check for CSR write instruction (test completion marker)
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b1110011) &&
            (u_dut.u_exec0.opcode_opcode_i[14:12] == 3'b001)) begin
            // Wait a few cycles for final stores
            repeat (10) @(posedge clk);

            // Read test results from memory at 0x80001000
            // Memory is 64-bit wide, indexed by 64-bit words
            // Results stored at: 0x80001000, 0x80001004, 0x80001008, ...
            // 0x80001000 = byte address 4096, word address 512 (64-bit words)
            for (i = 0; i < 7; i = i + 1) begin
                // Each word is 64 bits, we store 2 results per word
                if (i[0] == 0) begin
                    // Even index: lower 32 bits of word (512 + i/2) - little endian
                    test_results[i] = u_mem.u_ram.ram[512 + i/2][31:0];
                end else begin
                    // Odd index: upper 32 bits of word (512 + i/2) - little endian
                    test_results[i] = u_mem.u_ram.ram[512 + i/2][63:32];
                end
            end

            $display("");
            $display("==========================================================");
            $display("SAD Instruction Test Results");
            $display("==========================================================");

            num_passed = 0;

            // Test 1: All zeros
            $display("Test 1 (all zeros): result=0x%08h, expected=0x00000000 %s",
                     test_results[0], (test_results[0] == 32'h00000000) ? "PASS" : "FAIL");
            if (test_results[0] == 32'h00000000) num_passed = num_passed + 1;

            // Test 2: Simple difference (0xA = 10)
            $display("Test 2 (simple diff): result=0x%08h, expected=0x0000000A %s",
                     test_results[1], (test_results[1] == 32'h0000000A) ? "PASS" : "FAIL");
            if (test_results[1] == 32'h0000000A) num_passed = num_passed + 1;

            // Test 3: Negative differences (0xA = 10)
            $display("Test 3 (negative diff): result=0x%08h, expected=0x0000000A %s",
                     test_results[2], (test_results[2] == 32'h0000000A) ? "PASS" : "FAIL");
            if (test_results[2] == 32'h0000000A) num_passed = num_passed + 1;

            // Test 4: Mixed differences (6)
            $display("Test 4 (mixed diff): result=0x%08h, expected=0x00000006 %s",
                     test_results[3], (test_results[3] == 32'h00000006) ? "PASS" : "FAIL");
            if (test_results[3] == 32'h00000006) num_passed = num_passed + 1;

            // Test 5: With accumulator (110 = 0x6E)
            $display("Test 5 (with accumulator): result=0x%08h, expected=0x0000006E %s",
                     test_results[4], (test_results[4] == 32'h0000006E) ? "PASS" : "FAIL");
            if (test_results[4] == 32'h0000006E) num_passed = num_passed + 1;

            // Test 6: Maximum byte differences (1020 = 0x3FC)
            $display("Test 6 (max diff): result=0x%08h, expected=0x000003FC %s",
                     test_results[5], (test_results[5] == 32'h000003FC) ? "PASS" : "FAIL");
            if (test_results[5] == 32'h000003FC) num_passed = num_passed + 1;

            // Test 7: Identical values (0)
            $display("Test 7 (identical): result=0x%08h, expected=0x00000000 %s",
                     test_results[6], (test_results[6] == 32'h00000000) ? "PASS" : "FAIL");
            if (test_results[6] == 32'h00000000) num_passed = num_passed + 1;

            $display("==========================================================");
            $display("Tests Passed: %0d/7", num_passed);
            if (num_passed == 7) begin
                $display("SUCCESS: All tests passed!");
            end else begin
                $display("FAILURE: %0d tests failed", 7 - num_passed);
            end
            $display("==========================================================");
            $display("");

            // Display performance metrics
            $display("==========================================");
            $display("Performance Metrics:");
            $display("==========================================");
            $display("Total Cycles: %0d", cycle_count);
            $display("Total Instructions Retired: %0d", instruction_count);
            $display("CPI (Cycles Per Instruction): %f", $itor(cycle_count) / $itor(instruction_count));
            $display("IPC (Instructions Per Cycle): %f", $itor(instruction_count) / $itor(cycle_count));
            $display("==========================================\n");

            $finish;
        end
    end
end

// Wait for CSR write (test completion) or timeout
initial
begin
    repeat (5000) @(posedge clk);
    $display("TIMEOUT after 5000 cycles");
    $display("Performance: Cycles=%0d Instructions=%0d", cycle_count, instruction_count);

    // Debug: print raw memory at 0x80001000 and some before
    $display("\n=== Memory Dump around 0x80001000 ===");
    $display("Program area (word 0-2):");
    for (i = 0; i < 3; i = i + 1) begin
        $display("  Word %0d: 0x%016h", i, u_mem.u_ram.ram[i]);
    end
    $display("Result area (word 512-515):");
    for (i = 512; i < 516; i = i + 1) begin
        $display("  Word %0d: 0x%016h", i, u_mem.u_ram.ram[i]);
    end

    // Read test results from memory at 0x80001000
    // 0x80001000 = byte address 4096, word address 512 (64-bit words)
    for (i = 0; i < 7; i = i + 1) begin
        if (i[0] == 0) begin
            // Even index: lower 32 bits of word (512 + i/2) - little endian
            test_results[i] = u_mem.u_ram.ram[512 + i/2][31:0];
        end else begin
            // Odd index: upper 32 bits of word (512 + i/2) - little endian
            test_results[i] = u_mem.u_ram.ram[512 + i/2][63:32];
        end
    end

    $display("\n==========================================================");
    $display("SAD Instruction Test Results");
    $display("==========================================================");

    num_passed = 0;

    $display("Test 1: result=0x%08h, expected=0x00000000 %s", test_results[0], (test_results[0] == 32'h00000000) ? "PASS" : "FAIL");
    if (test_results[0] == 32'h00000000) num_passed = num_passed + 1;

    $display("Test 2: result=0x%08h, expected=0x0000000A %s", test_results[1], (test_results[1] == 32'h0000000A) ? "PASS" : "FAIL");
    if (test_results[1] == 32'h0000000A) num_passed = num_passed + 1;

    $display("Test 3: result=0x%08h, expected=0x0000000A %s", test_results[2], (test_results[2] == 32'h0000000A) ? "PASS" : "FAIL");
    if (test_results[2] == 32'h0000000A) num_passed = num_passed + 1;

    $display("Test 4: result=0x%08h, expected=0x00000006 %s", test_results[3], (test_results[3] == 32'h00000006) ? "PASS" : "FAIL");
    if (test_results[3] == 32'h00000006) num_passed = num_passed + 1;

    $display("Test 5: result=0x%08h, expected=0x0000006E %s", test_results[4], (test_results[4] == 32'h0000006E) ? "PASS" : "FAIL");
    if (test_results[4] == 32'h0000006E) num_passed = num_passed + 1;

    $display("Test 6: result=0x%08h, expected=0x000003FC %s", test_results[5], (test_results[5] == 32'h000003FC) ? "PASS" : "FAIL");
    if (test_results[5] == 32'h000003FC) num_passed = num_passed + 1;

    $display("Test 7: result=0x%08h, expected=0x00000000 %s", test_results[6], (test_results[6] == 32'h00000000) ? "PASS" : "FAIL");
    if (test_results[6] == 32'h00000000) num_passed = num_passed + 1;

    $display("==========================================================");
    $display("Tests Passed: %0d/7", num_passed);
    if (num_passed == 7) begin
        $display("SUCCESS: All SAD tests passed!");
    end else begin
        $display("FAILURE: %0d tests failed", 7 - num_passed);
    end
    $display("==========================================================\n");

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
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
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

    // Outputs
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
    // Inputs
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

    // Outputs
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
