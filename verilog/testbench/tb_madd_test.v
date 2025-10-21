module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

// Performance counters
integer instruction_count;
integer cycle_count;

initial
begin
    $display("Starting MADD instruction test");

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
reg [63:0] mem_word;
reg [31:0] results [0:15];
integer j;
integer pass_count;
initial
begin
    @(negedge rst);

    // Wait for CSR write to complete
    forever begin
        @(posedge clk);
        // Check for CSR write instruction (could be any CSR write)
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b1110011) &&
            (u_dut.u_exec0.opcode_opcode_i[14:12] == 3'b001)) begin
            // Wait a few cycles for final stores
            repeat (10) @(posedge clk);

            // Read results from memory (0x80000000 = RAM address 0x0)
            for (j = 0; j < 7; j = j + 1) begin
                mem_word = u_mem.u_ram.ram[14'h0 + j];
                results[j*2] = mem_word[31:0];
                results[j*2 + 1] = mem_word[63:32];
            end

            $display("");
            $display("==========================================================");
            $display("MADD Instruction Test Results");
            $display("==========================================================");
            $display("DEBUG: Raw memory dump:");
            for (j = 0; j < 13; j = j + 1) begin
                $display("  results[%0d] = 0x%08h (decimal: %0d)", j, results[j], $signed(results[j]));
            end
            $display("");

            // Test validation
            $display("Test 1:  (10 × 20) + 5 = 205         %s - Result: 0x%08h (%0d)",
                     results[0] == 32'd205 ? "PASS" : "FAIL", results[0], results[0]);
            $display("Test 2:  (10 × 20) + 0 = 200         %s - Result: 0x%08h (%0d)",
                     results[1] == 32'd200 ? "PASS" : "FAIL", results[1], results[1]);
            $display("Test 3:  (10 × 20) + 100 = 300       %s - Result: 0x%08h (%0d)",
                     results[2] == 32'd300 ? "PASS" : "FAIL", results[2], results[2]);
            $display("Test 4:  (0 × 20) + 5 = 5            %s - Result: 0x%08h (%0d)",
                     results[3] == 32'd5 ? "PASS" : "FAIL", results[3], results[3]);
            $display("Test 5:  (10 × 0) + 5 = 5            %s - Result: 0x%08h (%0d)",
                     results[4] == 32'd5 ? "PASS" : "FAIL", results[4], results[4]);
            $display("Test 6:  (0 × 0) + 0 = 0             %s - Result: 0x%08h (%0d)",
                     results[5] == 32'd0 ? "PASS" : "FAIL", results[5], results[5]);
            $display("Test 7:  (10 × 20) + (-1) = 199      %s - Result: 0x%08h (%0d)",
                     results[6] == 32'd199 ? "PASS" : "FAIL", results[6], results[6]);
            $display("Test 8:  (10 × 10) + 10 = 110        %s - Result: 0x%08h (%0d)",
                     results[7] == 32'd110 ? "PASS" : "FAIL", results[7], results[7]);
            $display("Test 9:  (0x7FFFFFFF × 2) + 5 = 3    %s - Result: 0x%08h (%0d)",
                     results[8] == 32'd3 ? "PASS" : "FAIL", results[8], results[8]);
            $display("Test 10: (-1 × 10) + 5 = -5          %s - Result: 0x%08h (%0d)",
                     results[9] == 32'hFFFFFFFB ? "PASS" : "FAIL", results[9], $signed(results[9]));
            $display("Test 11: (10 × 20) + (-300) = -100   %s - Result: 0x%08h (%0d)",
                     results[10] == 32'hFFFFFF9C ? "PASS" : "FAIL", results[10], $signed(results[10]));
            $display("Test 12a: (5 × 5) + 0 = 25           %s - Result: 0x%08h (%0d)",
                     results[11] == 32'd25 ? "PASS" : "FAIL", results[11], results[11]);
            $display("Test 12b: (5 × 5) + 25 = 50          %s - Result: 0x%08h (%0d)",
                     results[12] == 32'd50 ? "PASS" : "FAIL", results[12], results[12]);

            $display("==========================================================");

            // Count passes
            pass_count = 0;
            if (results[0] == 32'd205) pass_count = pass_count + 1;
            if (results[1] == 32'd200) pass_count = pass_count + 1;
            if (results[2] == 32'd300) pass_count = pass_count + 1;
            if (results[3] == 32'd5) pass_count = pass_count + 1;
            if (results[4] == 32'd5) pass_count = pass_count + 1;
            if (results[5] == 32'd0) pass_count = pass_count + 1;
            if (results[6] == 32'd199) pass_count = pass_count + 1;
            if (results[7] == 32'd110) pass_count = pass_count + 1;
            if (results[8] == 32'd3) pass_count = pass_count + 1;
            if (results[9] == 32'hFFFFFFFB) pass_count = pass_count + 1;
            if (results[10] == 32'hFFFFFF9C) pass_count = pass_count + 1;
            if (results[11] == 32'd25) pass_count = pass_count + 1;
            if (results[12] == 32'd50) pass_count = pass_count + 1;

            $display("Pass Count:  %0d / 13", pass_count);
            $display("==========================================================");

            if (pass_count == 13) begin
                $display("*** ALL TESTS PASSED - MADD IS WORKING CORRECTLY ***");
            end else begin
                $display("*** %0d TESTS FAILED - CHECK MADD IMPLEMENTATION ***", 13 - pass_count);
            end
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

// Timeout after 50000 cycles
initial
begin
    repeat (50000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 50000 cycles");
    $display("Performance: Cycles=%0d Instructions=%0d", cycle_count, instruction_count);
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
