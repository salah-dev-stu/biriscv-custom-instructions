module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting SAD minimal debug test");

    // Reset
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Load TCM memory
    for (i=0;i<131072;i=i+1)
        mem[i] = 0;

    f = $fopen("./build/tcm_minimal.bin", "rb");
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

// Debug monitor - print every instruction fetch and decode
initial
begin
    @(negedge rst);

    forever begin
        @(posedge clk);

        // Monitor instruction fetch
        if (u_dut.u_fetch.fetch_valid_o) begin
            $display("[%t] PC=0x%08h  FETCH=0x%08h", $time, u_dut.u_fetch.fetch_pc_o, u_dut.u_fetch.fetch_instr_o);
        end

        // Monitor decode stage
        if (u_dut.u_decode.opcode_valid_i) begin
            $display("[%t] DECODE: opcode=0x%08h  invalid=%b  exec=%b  rd_valid=%b",
                     $time,
                     u_dut.u_decode.opcode_opcode_i,
                     u_dut.u_decode.opcode_invalid_o,
                     u_dut.u_decode.exec_o,
                     u_dut.u_decode.rd_valid_o);

            // Check if it's a SAD instruction
            if ((u_dut.u_decode.opcode_opcode_i & 32'h0600707F) == 32'h0600507B) begin
                $display("[%t] *** SAD INSTRUCTION DETECTED ***", $time);
                $display("    Masked: 0x%08h", u_dut.u_decode.opcode_opcode_i & 32'h0600707F);
                $display("    Expected: 0x0600507B");
                $display("    Match: %b", (u_dut.u_decode.opcode_opcode_i & 32'h0600707F) == 32'h0600507B);
            end
        end

        // Monitor execute stage for SAD
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i & 32'h0600707F) == 32'h0600507B) begin
            $display("[%t] EXEC SAD: alu_func=%b  ra=0x%08h  rb=0x%08h  rc=0x%08h",
                     $time,
                     u_dut.u_exec0.alu_func_r,
                     u_dut.u_exec0.opcode_ra_operand_i,
                     u_dut.u_exec0.opcode_rb_operand_i,
                     u_dut.u_exec0.opcode_rc_operand_i);
        end

        // Monitor ALU for SAD
        if (u_dut.u_exec0.u_alu.alu_func_i == 5'b10001) begin
            $display("[%t] ALU SAD: a=0x%08h  b=0x%08h  c=0x%08h  result=0x%08h",
                     $time,
                     u_dut.u_exec0.u_alu.alu_a_i,
                     u_dut.u_exec0.u_alu.alu_b_i,
                     u_dut.u_exec0.u_alu.alu_c_i,
                     u_dut.u_exec0.u_alu.result_o);
        end

        // Monitor exceptions
        if (u_dut.u_csr.exception_o) begin
            $display("[%t] EXCEPTION: cause=0x%h  pc=0x%08h  opcode=0x%08h",
                     $time,
                     u_dut.u_csr.exception_type_o,
                     u_dut.u_csr.exception_pc_o,
                     u_dut.opcode_opcode_w);
        end
    end
end

// Timeout
initial
begin
    repeat (500) @(posedge clk);
    $display("TIMEOUT after 500 cycles");
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
