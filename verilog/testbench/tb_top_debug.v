// Simple debug testbench to trace CSEL execution
module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

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

// Monitor CSEL execution
reg [31:0] csel_count;
initial
begin
    csel_count = 0;
    @(negedge rst);
    repeat (10) @(posedge clk);

    forever begin
        @(posedge clk);
        // Detect CSEL instruction (opcode = 0x7B)
        if (u_dut.u_exec0.opcode_valid_i && (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'h7B)) begin
            csel_count = csel_count + 1;
            $display("\n=== CSEL #%0d at Time %0t ===", csel_count, $time);
            $display("PC: 0x%08h", u_dut.u_exec0.opcode_pc_i);
            $display("Opcode: 0x%08h", u_dut.u_exec0.opcode_opcode_i);
            $display("RD (from exec): x%0d", u_dut.u_exec0.opcode_rd_idx_i);

            // Decode the CSEL instruction manually
            $display("RS1 (bits 19:15): x%0d", u_dut.u_exec0.opcode_opcode_i[19:15]);
            $display("RS2 (bits 24:20): x%0d", u_dut.u_exec0.opcode_opcode_i[24:20]);
            $display("RS3 (bits 31:27): x%0d", u_dut.u_exec0.opcode_opcode_i[31:27]);
            $display("RD  (bits 11:7):  x%0d", u_dut.u_exec0.opcode_opcode_i[11:7]);

            // Show operand values
            $display("Operand A (RS1 value): 0x%08h", u_dut.u_exec0.opcode_ra_operand_i);
            $display("Operand B (RS2 value): 0x%08h", u_dut.u_exec0.opcode_rb_operand_i);
            $display("Operand C (RS3 value): 0x%08h", u_dut.u_exec0.opcode_rc_operand_i);

            // Show ALU inputs and result
            $display("ALU Input A: 0x%08h", u_dut.u_exec0.alu_input_a_r);
            $display("ALU Input B: 0x%08h", u_dut.u_exec0.alu_input_b_r);
            $display("ALU Input C: 0x%08h", u_dut.u_exec0.alu_input_c_r);
            $display("ALU Result (alu_p_w): 0x%08h", u_dut.u_exec0.alu_p_w);
        end

        // Check for completion
        if (u_dut.u_exec0.opcode_valid_i && u_dut.u_exec0.opcode_pc_i == 32'h80000028) begin
            $display("\n========================================");
            $display("Program completed! Total CSEL count: %0d", csel_count);
            $display("========================================");

            // Dump memory results
            repeat (10) @(posedge clk);
            $display("\nMemory Dump (Results Area):");
            $display("Address 0x80009000 region (RAM index 0x1200):");
            for (i = 16'h1200; i < 16'h1210; i = i + 1) begin
                $display("  RAM[0x%04h] = 0x%016h", i, u_mem.u_ram.ram[i]);
            end

            $display("\nRegister x10 (completion marker): 0x%08h",
                     u_dut.u_issue.u_regfile.REGFILE.reg_r10_q);

            $finish;
        end
    end
end

// Timeout
initial
begin
    repeat (50000) @(posedge clk);
    $display("\nTIMEOUT after 50000 cycles");
    $display("CSEL instructions executed: %0d", csel_count);
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
