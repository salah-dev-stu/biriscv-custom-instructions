module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting CSEL test bench");

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
reg [31:0] x10, x11, x12, x13, x14, x15, x16;
reg [31:0] pass_count, fail_count;
initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if PC reaches CSR write instruction (0x80000058 for CSEL test)
        if (!test_results_printed && u_dut.u_exec0.opcode_pc_i == 32'h80000058) begin
            // Wait 5 cycles for all pipeline stages and stores to complete
            repeat (5) @(posedge clk);

            // Read register values directly from register file
            x10 = u_dut.u_issue.u_regfile.REGFILE.reg_r10_q;
            x11 = u_dut.u_issue.u_regfile.REGFILE.reg_r11_q;
            x12 = u_dut.u_issue.u_regfile.REGFILE.reg_r12_q;
            x13 = u_dut.u_issue.u_regfile.REGFILE.reg_r13_q;
            x14 = u_dut.u_issue.u_regfile.REGFILE.reg_r14_q;
            x15 = u_dut.u_issue.u_regfile.REGFILE.reg_r15_q;
            x16 = u_dut.u_issue.u_regfile.REGFILE.reg_r16_q;

            pass_count = 0;
            fail_count = 0;

            $display("");
            $display("==========================================================");
            $display("CSEL Test Results:");
            $display("==========================================================");
            $display("Expected | Actual   | Register | Test Description");
            $display("---------|----------|----------|----------------------------------");

            // Test 1: CSEL with rs3=0 (should select rs1=0x1111)
            $write("0x1111   | 0x%04h   | x10      | ", x10);
            if (x10 == 32'h00001111) begin
                $display("PASS - CSEL rs3=0, select rs1");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3=0, select rs1");
                fail_count = fail_count + 1;
            end

            // Test 2: CSEL with rs3!=0 (should select rs2=0x2222)
            $write("0x2222   | 0x%04h   | x11      | ", x11);
            if (x11 == 32'h00002222) begin
                $display("PASS - CSEL rs3!=0, select rs2");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3!=0, select rs2");
                fail_count = fail_count + 1;
            end

            // Test 3: CSEL with larger non-zero rs3
            $write("0x2222   | 0x%04h   | x12      | ", x12);
            if (x12 == 32'h00002222) begin
                $display("PASS - CSEL rs3!=0 (large value)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3!=0 (large value)");
                fail_count = fail_count + 1;
            end

            // Test 4: CSEL with same sources, rs3=0
            $write("0x1111   | 0x%04h   | x13      | ", x13);
            if (x13 == 32'h00001111) begin
                $display("PASS - CSEL rs3=0, same sources");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3=0, same sources");
                fail_count = fail_count + 1;
            end

            // Test 5: CSEL with same sources, rs3!=0
            $write("0x2222   | 0x%04h   | x14      | ", x14);
            if (x14 == 32'h00002222) begin
                $display("PASS - CSEL rs3!=0, same sources");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3!=0, same sources");
                fail_count = fail_count + 1;
            end

            // Test 6: CSEL selecting x0 register
            $write("0x0000   | 0x%04h   | x15      | ", x15);
            if (x15 == 32'h00000000) begin
                $display("PASS - CSEL rs3=0, select x0");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3=0, select x0");
                fail_count = fail_count + 1;
            end

            // Test 7: CSEL rs3!=0 selecting x1
            $write("0x1111   | 0x%04h   | x16      | ", x16);
            if (x16 == 32'h00001111) begin
                $display("PASS - CSEL rs3!=0, select rs2=x1");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL - CSEL rs3!=0, select rs2=x1");
                fail_count = fail_count + 1;
            end

            $display("==========================================================");
            $display("");
            $display("==========================================");
            $display("Test Summary:");
            $display("==========================================");
            $display("Passed: %0d / 7", pass_count);
            $display("Failed: %0d / 7", fail_count);
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

// Timeout after 10000 cycles
initial
begin
    repeat (10000) @(posedge clk);
    $display("TIMEOUT: Test reached 10000 cycles without completion");
    $display("PC never reached expected CSR write at 0x80000058");
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
