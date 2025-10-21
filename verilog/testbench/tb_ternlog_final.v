module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting TERNLOG comprehensive test (15 tests)");

    // Reset
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Load TCM memory
    for (i=0;i<131072;i=i+1)
        mem[i] = 0;

    f = $fopen("ternlog_final_test.bin", "rb");
    if (f == 0) begin
        $display("ERROR: Cannot open ternlog_final_test.bin");
        $finish;
    end
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

// Monitor for test completion (CSR write)
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
            // Wait a few cycles for writes to complete
            repeat (10) @(posedge clk);

            $display("");
            $display("========== TEST RESULTS ==========");

            // Check all 15 test results
            $display("Test 1  (Copy A):        x10 = 0x%08h (expected 0xAAAAAAAA) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r10_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r10_q == 32'hAAAAAAAA) ? "PASS" : "FAIL");

            $display("Test 2  (Copy B):        x11 = 0x%08h (expected 0xCCCCCCCC) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r11_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r11_q == 32'hCCCCCCCC) ? "PASS" : "FAIL");

            $display("Test 3  (AND):           x12 = 0x%08h (expected 0x88888888) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r12_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r12_q == 32'h88888888) ? "PASS" : "FAIL");

            $display("Test 4  (OR):            x13 = 0x%08h (expected 0xEEEEEEEE) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r13_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r13_q == 32'hEEEEEEEE) ? "PASS" : "FAIL");

            $display("Test 5  (XOR):           x14 = 0x%08h (expected 0x66666666) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r14_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r14_q == 32'h66666666) ? "PASS" : "FAIL");

            $display("Test 6  (NAND):          x15 = 0x%08h (expected 0x77777777) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r15_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r15_q == 32'h77777777) ? "PASS" : "FAIL");

            $display("Test 7  (NOR):           x16 = 0x%08h (expected 0x11111111) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r16_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r16_q == 32'h11111111) ? "PASS" : "FAIL");

            $display("Test 8  (XNOR):          x17 = 0x%08h (expected 0x99999999) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r17_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r17_q == 32'h99999999) ? "PASS" : "FAIL");

            $display("Test 9  (NOT A):         x18 = 0x%08h (expected 0x55555555) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r18_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r18_q == 32'h55555555) ? "PASS" : "FAIL");

            $display("Test 10 (NOT B):         x19 = 0x%08h (expected 0x33333333) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r19_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r19_q == 32'h33333333) ? "PASS" : "FAIL");

            $display("Test 11 (A AND NOT B):   x20 = 0x%08h (expected 0x22222222) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r20_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r20_q == 32'h22222222) ? "PASS" : "FAIL");

            $display("Test 12 (B AND NOT A):   x21 = 0x%08h (expected 0x44444444) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r21_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r21_q == 32'h44444444) ? "PASS" : "FAIL");

            $display("Test 13 (Constant 0):    x22 = 0x%08h (expected 0x00000000) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r22_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r22_q == 32'h00000000) ? "PASS" : "FAIL");

            $display("Test 14 (Constant 1):    x23 = 0x%08h (expected 0xFFFFFFFF) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r23_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r23_q == 32'hFFFFFFFF) ? "PASS" : "FAIL");

            $display("Test 15 (Implies A->B):  x24 = 0x%08h (expected 0xDDDDDDDD) %s",
                u_dut.u_issue.u_regfile.REGFILE.reg_r24_q,
                (u_dut.u_issue.u_regfile.REGFILE.reg_r24_q == 32'hDDDDDDDD) ? "PASS" : "FAIL");

            // Count passes
            if ((u_dut.u_issue.u_regfile.REGFILE.reg_r10_q == 32'hAAAAAAAA) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r11_q == 32'hCCCCCCCC) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r12_q == 32'h88888888) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r13_q == 32'hEEEEEEEE) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r14_q == 32'h66666666) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r15_q == 32'h77777777) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r16_q == 32'h11111111) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r17_q == 32'h99999999) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r18_q == 32'h55555555) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r19_q == 32'h33333333) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r20_q == 32'h22222222) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r21_q == 32'h44444444) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r22_q == 32'h00000000) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r23_q == 32'hFFFFFFFF) &&
                (u_dut.u_issue.u_regfile.REGFILE.reg_r24_q == 32'hDDDDDDDD)) begin
                $display("");
                $display("*** ALL 15 TESTS PASSED! ***");
            end else begin
                $display("");
                $display("*** SOME TESTS FAILED ***");
            end
            $display("==================================");

            $finish;
        end
    end
end

// Timeout after 10000 cycles
initial
begin
    repeat (10000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 10000 cycles");
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
