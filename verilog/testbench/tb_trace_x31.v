module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;
integer instr_count;

initial
begin
    $display("Tracing x31 register through loop iterations");

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
    $display("Loaded %0d bytes from tcm.bin", i);
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

// Monitor x31 register and key instructions - BOTH PIPES
initial
begin
    instr_count = 0;
    @(negedge rst);

    repeat (200) begin
        @(posedge clk);

        // Check pipe0
        if (u_dut.u_exec0.opcode_valid_i) begin
            instr_count = instr_count + 1;

            if (instr_count >= 70) begin
                if ((u_dut.u_exec0.opcode_opcode_i & 32'h0600707f) == 32'h0000007b) begin
                    $display("P0-Instr %0d: CSEL PC=0x%08h RD=%0d RA=%0d RB=%0d RC=%0d",
                             instr_count, u_dut.u_exec0.opcode_pc_i,
                             u_dut.u_exec0.opcode_rd_idx_i, u_dut.u_exec0.opcode_ra_idx_i,
                             u_dut.u_exec0.opcode_rb_idx_i, u_dut.u_exec0.opcode_rc_idx_i);
                    $display("            operands: RA=0x%08h RB=0x%08h RC=0x%08h",
                             u_dut.u_exec0.opcode_ra_operand_i, u_dut.u_exec0.opcode_rb_operand_i,
                             u_dut.u_exec0.opcode_rc_operand_i);
                end
                else begin
                    $display("P0-Instr %0d: PC=0x%08h OP=0x%08h",
                             instr_count, u_dut.u_exec0.opcode_pc_i, u_dut.u_exec0.opcode_opcode_i);
                end
            end
            else if (u_dut.u_exec0.opcode_rd_idx_i == 5'd31 ||
                     u_dut.u_exec0.opcode_ra_idx_i == 5'd31 ||
                     u_dut.u_exec0.opcode_rb_idx_i == 5'd31) begin
                $display("P0-Instr %0d: PC=0x%08h OP=0x%08h x31=0x%08h",
                         instr_count, u_dut.u_exec0.opcode_pc_i, u_dut.u_exec0.opcode_opcode_i,
                         u_dut.u_issue.u_regfile.REGFILE.reg_r31_q);
            end
        end

        // Check pipe1
        if (u_dut.u_exec1.opcode_valid_i) begin
            instr_count = instr_count + 1;

            if (instr_count >= 70) begin
                if ((u_dut.u_exec1.opcode_opcode_i & 32'h0600707f) == 32'h0000007b) begin
                    $display("P1-Instr %0d: CSEL PC=0x%08h RD=%0d RA=%0d RB=%0d RC=%0d",
                             instr_count, u_dut.u_exec1.opcode_pc_i,
                             u_dut.u_exec1.opcode_rd_idx_i, u_dut.u_exec1.opcode_ra_idx_i,
                             u_dut.u_exec1.opcode_rb_idx_i, u_dut.u_exec1.opcode_rc_idx_i);
                    $display("            operands: RA=0x%08h RB=0x%08h RC=0x%08h",
                             u_dut.u_exec1.opcode_ra_operand_i, u_dut.u_exec1.opcode_rb_operand_i,
                             u_dut.u_exec1.opcode_rc_operand_i);
                end
                else begin
                    $display("P1-Instr %0d: PC=0x%08h OP=0x%08h",
                             instr_count, u_dut.u_exec1.opcode_pc_i, u_dut.u_exec1.opcode_opcode_i);
                end
            end
            else if (u_dut.u_exec1.opcode_rd_idx_i == 5'd31 ||
                     u_dut.u_exec1.opcode_ra_idx_i == 5'd31 ||
                     u_dut.u_exec1.opcode_rb_idx_i == 5'd31) begin
                $display("P1-Instr %0d: PC=0x%08h OP=0x%08h x31=0x%08h",
                         instr_count, u_dut.u_exec1.opcode_pc_i, u_dut.u_exec1.opcode_opcode_i,
                         u_dut.u_issue.u_regfile.REGFILE.reg_r31_q);
            end
        end
    end

    $display("Traced 200 instructions, x31 final value = %0d",
             $signed(u_dut.u_issue.u_regfile.REGFILE.reg_r31_q));
    $finish;
end

// Check for completion marker
reg [31:0] marker;
reg [63:0] mem_word;
initial
begin
    forever begin
        @(posedge clk);
        mem_word = u_mem.u_ram.ram[14'h240C];
        marker = mem_word[31:0];

        if (marker == 32'hDEADBEEF) begin
            $display("");
            $display("=== TEST COMPLETED! ===");

            mem_word = u_mem.u_ram.ram[14'h2400];
            $display("Max result: %0d", $signed(mem_word[31:0]));

            mem_word = u_mem.u_ram.ram[14'h2401];
            $display("Min result: %0d", $signed(mem_word[31:0]));

            $finish;
        end
    end
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
