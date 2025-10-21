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
    $display("Starting bench");

    if (`TRACE)
    begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end

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

// Debug monitor for instruction execution
initial
begin
    @(negedge rst);
    repeat (10) @(posedge clk);

    // Disable verbose monitoring - test is working
    // $display("\n=== Monitoring first 50 instructions ===");
    // repeat (50) begin
    //     @(posedge clk);
    //     if (u_dut.u_exec0.opcode_valid_i) begin
    //         $display("Time %0t: PC=0x%08h OPCODE=0x%08h INVALID=%b RD=%d rs1=%d alu_func=%h",
    //                  $time, u_dut.u_exec0.opcode_pc_i, u_dut.u_exec0.opcode_opcode_i,
    //                  u_dut.u_exec0.opcode_invalid_i, u_dut.u_exec0.opcode_rd_idx_i,
    //                  u_dut.u_exec0.opcode_ra_idx_i, u_dut.u_exec0.alu_func_r);
    //     end
    // end
    // $display("=== Monitoring complete ===\n");
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

// Monitor for test completion - supports both simple tests and real-world programs
reg test_results_printed;
reg is_real_world_test;  // Detect if this is a real-world program (has JAL in first 0x20 bytes or stores to 0x80009000)
integer store_count_to_result_area;

initial
begin
    test_results_printed = 0;
    is_real_world_test = 0;
    store_count_to_result_area = 0;

    forever begin
        @(posedge clk);

        // Detect real-world test by checking for JAL to process_network_packets
        // Real-world programs have: jal 0x80000068 (0x064000ef) at PC 0x80000004
        // Simple tests have BREV instruction at 0x80000004
        // We detect by seeing PC jump from 0x80000004 to 0x80000068
        if (!is_real_world_test && u_dut.u_exec0.opcode_valid_i &&
            u_dut.u_exec0.opcode_pc_i == 32'h80000068 &&
            u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b0010011) begin  // addi sp, sp, -0x10 (function prologue)
            $display("INFO: Detected real-world test (PC entered process_network_packets at 0x%08h)",
                u_dut.u_exec0.opcode_pc_i);
            is_real_world_test = 1;
        end

        // Detect stores to result area (0x80009000 onwards) - also indicates real-world test
        if (mem_d_wr_w != 4'b0000 && mem_d_addr_w >= 32'h80009000 && mem_d_addr_w < 32'h8000A000) begin
            if (!is_real_world_test) begin
                $display("INFO: Detected real-world test (store to 0x%08h)", mem_d_addr_w);
            end
            is_real_world_test = 1;
            store_count_to_result_area = store_count_to_result_area + 1;
        end

        // IMPORTANT: Check real-world completion FIRST (before simple test check at 0x80000090)
        // Real-world test completion: PC reaches _done loop AND we've seen stores to result area
        if (!test_results_printed && is_real_world_test && u_dut.u_exec0.opcode_pc_i == 32'h80000014) begin
            // Wait for all stores to complete
            repeat (10) @(posedge clk);

            $display("");
            $display("==============================================");
            $display("BREV Real-World Test Results (Test Complete):");
            $display("==============================================");
            $display("Detected %0d stores to result area (0x80009000)", store_count_to_result_area);
            $display("");
            $display("Sample Results from Memory (first 5 packets):");
            $display("Packet | CRC Result   | Swapped      | Hash Result");
            $display("-------|--------------|--------------|-------------");
            $display("0      | 0x%08h   | 0x%08h   | 0x%08h",
                u_mem.u_ram.ram[32'h9000>>3][31:0], u_mem.u_ram.ram[32'h9004>>3][31:0], u_mem.u_ram.ram[32'h9008>>3][63:32]);
            $display("1      | 0x%08h   | 0x%08h   | 0x%08h",
                u_mem.u_ram.ram[32'h900C>>3][63:32], u_mem.u_ram.ram[32'h9010>>3][31:0], u_mem.u_ram.ram[32'h9014>>3][63:32]);
            $display("2      | 0x%08h   | 0x%08h   | 0x%08h",
                u_mem.u_ram.ram[32'h9018>>3][31:0], u_mem.u_ram.ram[32'h901C>>3][63:32], u_mem.u_ram.ram[32'h9020>>3][31:0]);
            $display("3      | 0x%08h   | 0x%08h   | 0x%08h",
                u_mem.u_ram.ram[32'h9024>>3][63:32], u_mem.u_ram.ram[32'h9028>>3][31:0], u_mem.u_ram.ram[32'h902C>>3][63:32]);
            $display("4      | 0x%08h   | 0x%08h   | 0x%08h",
                u_mem.u_ram.ram[32'h9030>>3][31:0], u_mem.u_ram.ram[32'h9034>>3][63:32], u_mem.u_ram.ram[32'h9038>>3][31:0]);
            $display("==============================================");
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

            test_results_printed = 1;
            $finish;
        end

        // Simple test completion: PC reaches CSR write at 0x80000090 AND no stores to result area
        if (!test_results_printed && !is_real_world_test && u_dut.u_exec0.opcode_pc_i == 32'h80000090) begin
            // Wait 3 cycles for stores and final updates to complete
            repeat (3) @(posedge clk);
            $display("");
            $display("==============================================");
            $display("BREV Test Results (Test Complete):");
            $display("==============================================");
            $display("Input        | Expected     | Actual       | Test");
            $display("-------------|--------------|--------------|-----");
            $display("0x00000000   | 0x00000000   | 0x%08h   | All zeros", u_dut.u_issue.u_regfile.REGFILE.reg_r10_q);
            $display("0xFFFFFFFF   | 0xFFFFFFFF   | 0x%08h   | All ones", u_dut.u_issue.u_regfile.REGFILE.reg_r11_q);
            $display("0x55555555   | 0xAAAAAAAA   | 0x%08h   | Alternating 01...", u_dut.u_issue.u_regfile.REGFILE.reg_r12_q);
            $display("0xAAAAAAAA   | 0x55555555   | 0x%08h   | Alternating 10...", u_dut.u_issue.u_regfile.REGFILE.reg_r13_q);
            $display("0x0000000F   | 0xF0000000   | 0x%08h   | Low nibble", u_dut.u_issue.u_regfile.REGFILE.reg_r14_q);
            $display("0xF0000000   | 0x0000000F   | 0x%08h   | High nibble", u_dut.u_issue.u_regfile.REGFILE.reg_r16_q);
            $display("0x00000001   | 0x80000000   | 0x%08h   | LSB set", u_dut.u_issue.u_regfile.REGFILE.reg_r18_q);
            $display("0x80000000   | 0x00000001   | 0x%08h   | MSB set", u_dut.u_issue.u_regfile.REGFILE.reg_r20_q);
            $display("0x12345678   | 0x1E6A2C48   | 0x%08h   | Pattern 1", u_dut.u_issue.u_regfile.REGFILE.reg_r22_q);
            $display("0xDEADBEEF   | 0xF77DB57B   | 0x%08h   | Pattern 2", u_dut.u_issue.u_regfile.REGFILE.reg_r24_q);
            $display("==============================================");
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

            test_results_printed = 1;
            $finish;  // End simulation on completion
        end
    end
end

// Timeout after 100000 cycles (for complex real-world program)
initial
begin
    repeat (100000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 100000 cycles");
    $display("");
    $display("==============================================");
    $display("CSEL Test Results:");
    $display("==============================================");
    $display("Expected | Actual   | Register | Test");
    $display("---------|----------|----------|-----");
    $display("0x1111   | 0x%04h   | x10      | CSEL rs3=0, select rs1", u_dut.u_issue.u_regfile.REGFILE.reg_r10_q);
    $display("0x2222   | 0x%04h   | x11      | CSEL rs3!=0, select rs2", u_dut.u_issue.u_regfile.REGFILE.reg_r11_q);
    $display("0x2222   | 0x%04h   | x12      | CSEL rs3!=0, select rs2", u_dut.u_issue.u_regfile.REGFILE.reg_r12_q);
    $display("0x1111   | 0x%04h   | x13      | CSEL rs3=0, same sources", u_dut.u_issue.u_regfile.REGFILE.reg_r13_q);
    $display("0x2222   | 0x%04h   | x14      | CSEL rs3!=0, same sources", u_dut.u_issue.u_regfile.REGFILE.reg_r14_q);
    $display("0x0000   | 0x%04h   | x15      | CSEL rs3=0, select x0", u_dut.u_issue.u_regfile.REGFILE.reg_r15_q);
    $display("0x1111   | 0x%04h   | x16      | CSEL rs3!=0, select x1", u_dut.u_issue.u_regfile.REGFILE.reg_r16_q);
    $display("==============================================");
    $display("");
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