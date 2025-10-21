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
    $display("Starting CMOV instruction test");

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
reg [63:0] mem_word;
reg [31:0] results [0:10];
integer j;
integer pass_count;
initial
begin
    @(negedge rst);

    // Wait for CSR write to complete
    forever begin
        @(posedge clk);
        // Check for CSR write instruction
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b1110011) &&
            (u_dut.u_exec0.opcode_opcode_i[14:12] == 3'b001)) begin
            // Wait a few cycles for final stores
            repeat (10) @(posedge clk);

            // Read all 11 results from memory (address 0x80000000)
            for (j = 0; j < 6; j = j + 1) begin
                mem_word = u_mem.u_ram.ram[j];
                results[j*2] = mem_word[31:0];
                if ((j*2 + 1) < 11)
                    results[j*2 + 1] = mem_word[63:32];
            end

            $display("");
            $display("==========================================================");
            $display("CMOV Instruction Test Results");
            $display("==========================================================");

            $display("Test 1  - rs3=0 (select rs2):        %s - Result: 0x%08h (Expected: 0x00002222)",
                     results[0] == 32'h00002222 ? "PASS" : "FAIL", results[0]);
            $display("Test 2  - rs3!=0 (select rs1):       %s - Result: 0x%08h (Expected: 0x00001111)",
                     results[1] == 32'h00001111 ? "PASS" : "FAIL", results[1]);
            $display("Test 3  - rs3=100 (select rs1):      %s - Result: 0x%08h (Expected: 0x00001111)",
                     results[2] == 32'h00001111 ? "PASS" : "FAIL", results[2]);
            $display("Test 4  - same src, rs3=0:           %s - Result: 0x%08h (Expected: 0x00001111)",
                     results[3] == 32'h00001111 ? "PASS" : "FAIL", results[3]);
            $display("Test 5  - same src, rs3!=0:          %s - Result: 0x%08h (Expected: 0x00002222)",
                     results[4] == 32'h00002222 ? "PASS" : "FAIL", results[4]);
            $display("Test 6  - rs1=x0, rs3=0:             %s - Result: 0x%08h (Expected: 0x00001111)",
                     results[5] == 32'h00001111 ? "PASS" : "FAIL", results[5]);
            $display("Test 7  - rs1=x0, rs3!=0:            %s - Result: 0x%08h (Expected: 0x00000000)",
                     results[6] == 32'h00000000 ? "PASS" : "FAIL", results[6]);
            $display("Test 8  - rs3=-1 (select rs1):       %s - Result: 0x%08h (Expected: 0x00001111)",
                     results[7] == 32'h00001111 ? "PASS" : "FAIL", results[7]);
            $display("Test 9  - chain test 1:              %s - Result: 0x%08h (Expected: 0x00003333)",
                     results[8] == 32'h00003333 ? "PASS" : "FAIL", results[8]);
            $display("Test 10 - chain test 2:              %s - Result: 0x%08h (Expected: 0x00004444)",
                     results[9] == 32'h00004444 ? "PASS" : "FAIL", results[9]);
            $display("Test 11 - Success marker:            %s - Result: 0x%08h (Expected: 0xC0DE000D)",
                     results[10] == 32'hC0DE000D ? "PASS" : "FAIL", results[10]);
            $display("==========================================================");

            // Count passes
            pass_count = 0;
            if (results[0] == 32'h00002222) pass_count = pass_count + 1;
            if (results[1] == 32'h00001111) pass_count = pass_count + 1;
            if (results[2] == 32'h00001111) pass_count = pass_count + 1;
            if (results[3] == 32'h00001111) pass_count = pass_count + 1;
            if (results[4] == 32'h00002222) pass_count = pass_count + 1;
            if (results[5] == 32'h00001111) pass_count = pass_count + 1;
            if (results[6] == 32'h00000000) pass_count = pass_count + 1;
            if (results[7] == 32'h00001111) pass_count = pass_count + 1;
            if (results[8] == 32'h00003333) pass_count = pass_count + 1;
            if (results[9] == 32'h00004444) pass_count = pass_count + 1;
            if (results[10] == 32'hC0DE000D) pass_count = pass_count + 1;

            $display("");
            $display("Pass Count: %0d / 11 tests", pass_count);
            $display("==========================================================");

            if (pass_count == 11) begin
                $display("");
                $display("==========================================");
                $display("ALL CMOV TESTS PASSED!");
                $display("==========================================");
            end else begin
                $display("");
                $display("==========================================");
                $display("SOME TESTS FAILED - CHECK IMPLEMENTATION");
                $display("==========================================");
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
