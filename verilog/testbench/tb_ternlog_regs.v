module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting TERNLOG register direct test");

    // Reset
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Load TCM memory
    for (i=0;i<131072;i=i+1)
        mem[i] = 0;

    f = $fopen("tcm.bin", "rb");
    if (f == 0) begin
        $display("ERROR: Cannot open tcm.bin");
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
reg [31:0] x1_val, x2_val, x10_val, x11_val, x12_val;
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
            // Wait a few cycles
            repeat (5) @(posedge clk);

            // Read register values directly from register file
            x1_val = u_dut.u_issue.u_regfile.REGFILE.reg_r1_q;
            x2_val = u_dut.u_issue.u_regfile.REGFILE.reg_r2_q;
            x10_val = u_dut.u_issue.u_regfile.REGFILE.reg_r10_q;
            x11_val = u_dut.u_issue.u_regfile.REGFILE.reg_r11_q;
            x12_val = u_dut.u_issue.u_regfile.REGFILE.reg_r12_q;

            $display("");
            $display("==========================================================");
            $display("TERNLOG Register Direct Test Results");
            $display("==========================================================");
            $display("");
            $display("Input registers:");
            $display("  x1 (rs1) = 0x%08h", x1_val);
            $display("  x2 (rs2) = 0x%08h", x2_val);
            $display("");

            $display("Test 1 - Copy A (imm8=0xF0):");
            $display("  x10 = 0x%08h | Expected: 0xAAAAAAAA | %s",
                     x10_val, x10_val == 32'hAAAAAAAA ? "PASS" : "FAIL");
            $display("");

            $display("Test 2 - Copy B (imm8=0xCC):");
            $display("  x11 = 0x%08h | Expected: 0xCCCCCCCC | %s",
                     x11_val, x11_val == 32'hCCCCCCCC ? "PASS" : "FAIL");
            $display("");

            $display("Test 3 - AND (imm8=0x88):");
            $display("  x12 = 0x%08h | Expected: 0x88888888 | %s",
                     x12_val, x12_val == 32'h88888888 ? "PASS" : "FAIL");
            $display("");

            $display("==========================================================");

            // Count passes
            if (x10_val == 32'hAAAAAAAA &&
                x11_val == 32'hCCCCCCCC &&
                x12_val == 32'h88888888) begin
                $display("");
                $display("==========================================");
                $display("ALL TERNLOG TESTS PASSED!");
                $display("==========================================");
                $display("");
            end else begin
                $display("");
                $display("==========================================");
                $display("SOME TESTS FAILED - CHECK IMPLEMENTATION");
                $display("==========================================");
                $display("");
            end

            $finish;
        end
    end
end

// Timeout after 100000 cycles
initial
begin
    repeat (100000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 100000 cycles");
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
