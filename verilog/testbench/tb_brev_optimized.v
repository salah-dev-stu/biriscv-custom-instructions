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
    $display("Starting BREV optimized test (hardware BREV instruction)");

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

// Monitor for test completion (PC reaches CSR write at 0x80000010)
reg test_results_printed;
reg [31:0] mem_results[0:10];
reg [63:0] mem_word;
initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if PC reaches CSR write instruction
        if (!test_results_printed && u_dut.u_exec0.opcode_pc_i == 32'h80000010) begin
            // Wait 5 cycles for stores and final updates to complete
            repeat (5) @(posedge clk);

            // Read results from memory (0x80009000+ = word addresses 0x1200+)
            // RAM is 64-bit wide, byte address 0x80009000 >> 3 = 0x1200
            mem_word = u_mem.u_ram.ram[14'h1200];
            mem_results[0] = mem_word[31:0];
            mem_results[1] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1201];
            mem_results[2] = mem_word[31:0];
            mem_results[3] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1202];
            mem_results[4] = mem_word[31:0];
            mem_results[5] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1203];
            mem_results[6] = mem_word[31:0];
            mem_results[7] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1204];
            mem_results[8] = mem_word[31:0];
            mem_results[9] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1205];
            mem_results[10] = mem_word[31:0];

            $display("");
            $display("==========================================================");
            $display("BREV Optimized Test Results (Hardware BREV Instruction):");
            $display("==========================================================");
            $display("Input        | Expected     | Actual       | Status");
            $display("-------------|--------------|--------------|--------");
            $display("0x00000000   | 0x00000000   | 0x%08h   | %s", mem_results[0], (mem_results[0] == 32'h00000000) ? "PASS" : "FAIL");
            $display("0xFFFFFFFF   | 0xFFFFFFFF   | 0x%08h   | %s", mem_results[1], (mem_results[1] == 32'hFFFFFFFF) ? "PASS" : "FAIL");
            $display("0x55555555   | 0xAAAAAAAA   | 0x%08h   | %s", mem_results[2], (mem_results[2] == 32'hAAAAAAAA) ? "PASS" : "FAIL");
            $display("0xAAAAAAAA   | 0x55555555   | 0x%08h   | %s", mem_results[3], (mem_results[3] == 32'h55555555) ? "PASS" : "FAIL");
            $display("0x0000000F   | 0xF0000000   | 0x%08h   | %s", mem_results[4], (mem_results[4] == 32'hF0000000) ? "PASS" : "FAIL");
            $display("0xF0000000   | 0x0000000F   | 0x%08h   | %s", mem_results[5], (mem_results[5] == 32'h0000000F) ? "PASS" : "FAIL");
            $display("0x00000001   | 0x80000000   | 0x%08h   | %s", mem_results[6], (mem_results[6] == 32'h80000000) ? "PASS" : "FAIL");
            $display("0x80000000   | 0x00000001   | 0x%08h   | %s", mem_results[7], (mem_results[7] == 32'h00000001) ? "PASS" : "FAIL");
            $display("0x12345678   | 0x1E6A2C48   | 0x%08h   | %s", mem_results[8], (mem_results[8] == 32'h1E6A2C48) ? "PASS" : "FAIL");
            $display("0xDEADBEEF   | 0xF77DB57B   | 0x%08h   | %s", mem_results[9], (mem_results[9] == 32'hF77DB57B) ? "PASS" : "FAIL");
            $display("Completion   | 0x0BEEF00D   | 0x%08h   | %s", mem_results[10], (mem_results[10] == 32'h0BEEF00D) ? "PASS" : "FAIL");
            $display("==========================================================");
            $display("");

            // Display performance metrics
            $display("===========================================");
            $display("Performance Metrics (BREV Optimized):");
            $display("===========================================");
            $display("Total Cycles: %0d", cycle_count);
            $display("Total Instructions Retired: %0d", instruction_count);
            $display("CPI (Cycles Per Instruction): %0f", real'(cycle_count) / real'(instruction_count));
            $display("IPC (Instructions Per Cycle): %0f", real'(instruction_count) / real'(cycle_count));
            $display("===========================================\n");

            test_results_printed = 1;
            $finish;
        end
    end
end

// Timeout after 100000 cycles
initial
begin
    repeat (100000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 100000 cycles");
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
