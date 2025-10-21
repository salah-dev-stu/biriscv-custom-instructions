module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting TERNLOG debug test");

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

// Debug monitor - watch TERNLOG instruction execution
always @(posedge clk) begin
    if (!rst && u_dut.u_exec0.opcode_valid_i) begin
        // Check if this is a TERNLOG instruction
        if ((u_dut.u_exec0.opcode_opcode_i & 32'h0600007f) == 32'h0400007b) begin
            $display("");
            $display("========== TERNLOG INSTRUCTION DETECTED ==========");
            $display("Time: %0t", $time);
            $display("PC: 0x%08h", u_dut.u_exec0.opcode_pc_i);
            $display("Instruction: 0x%08h", u_dut.u_exec0.opcode_opcode_i);
            $display("");
            $display("Operands:");
            $display("  rs1 (ra): x%0d = 0x%08h", u_dut.u_exec0.opcode_ra_idx_i, u_dut.u_exec0.opcode_ra_operand_i);
            $display("  rs2 (rb): x%0d = 0x%08h", u_dut.u_exec0.opcode_rb_idx_i, u_dut.u_exec0.opcode_rb_operand_i);
            $display("  rd:       x%0d", u_dut.u_exec0.opcode_rd_idx_i);
            $display("");
            $display("Immediate extraction:");
            $display("  imm8_r = 0x%02h", u_dut.u_exec0.imm8_r);
            $display("");
            $display("ALU inputs:");
            $display("  alu_func_r = 0x%01h (should be 0xF for TERNLOG)", u_dut.u_exec0.alu_func_r);
            $display("  alu_input_a_r = 0x%08h", u_dut.u_exec0.alu_input_a_r);
            $display("  alu_input_b_r = 0x%08h", u_dut.u_exec0.alu_input_b_r);
            $display("  alu_input_imm8_r = 0x%02h", u_dut.u_exec0.alu_input_imm8_r);
            $display("");
            $display("ALU output:");
            $display("  alu_p_w = 0x%08h", u_dut.u_exec0.alu_p_w);
            $display("==================================================");
            $display("");
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
        // Check for CSR write instruction
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b1110011) &&
            (u_dut.u_exec0.opcode_opcode_i[14:12] == 3'b001)) begin
            // Wait a few cycles
            repeat (10) @(posedge clk);

            $display("");
            $display("========== TEST COMPLETE ==========");
            $display("Register x10 value: 0x%08h", u_dut.u_issue.u_regfile.REGFILE.reg_r10_q);
            $display("Expected:           0xAAAAAAAA");

            if (u_dut.u_issue.u_regfile.REGFILE.reg_r10_q == 32'hAAAAAAAA)
                $display("PASS!");
            else
                $display("FAIL!");
            $display("===================================");

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
