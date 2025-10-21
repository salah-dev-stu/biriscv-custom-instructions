module tb_top;
reg clk, rst;
reg [7:0] mem[131072:0];
integer i, f, cycle;

initial begin
    $display("Tracing first 200 cycles");
    clk = 0; rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    for (i=0;i<131072;i=i+1) mem[i] = 0;
    f = $fopen("./build/tcm.bin", "rb");
    i = $fread(mem, f);
    $fclose(f);
    for (i=0;i<131072;i=i+1) u_mem.write(i, mem[i]);
end

initial forever clk = #5 ~clk;

initial begin
    cycle = 0;
    @(negedge rst);
    
    repeat (200) begin
        @(posedge clk);
        cycle = cycle + 1;
        
        if (u_dut.u_exec0.opcode_valid_i) begin
            $display("C%0d: PC=0x%08h OP=0x%08h RD=%0d RA=%0d RB=%0d RC=%0d",
                     cycle,
                     u_dut.u_exec0.opcode_pc_i,
                     u_dut.u_exec0.opcode_opcode_i,
                     u_dut.u_exec0.opcode_rd_idx_i,
                     u_dut.u_exec0.opcode_ra_idx_i,
                     u_dut.u_exec0.opcode_rb_idx_i,
                     u_dut.u_exec0.opcode_rc_idx_i);
        end
    end
    $finish;
end

wire mem_i_rd_w, mem_i_flush_w, mem_i_invalidate_w;
wire [31:0] mem_i_pc_w, mem_d_addr_w, mem_d_data_wr_w;
wire mem_d_rd_w;
wire [3:0] mem_d_wr_w;
wire mem_d_cacheable_w;
wire [10:0] mem_d_req_tag_w;
wire mem_d_invalidate_w, mem_d_writeback_w, mem_d_flush_w;
wire mem_i_accept_w, mem_i_valid_w, mem_i_error_w;
wire [63:0] mem_i_inst_w;
wire [31:0] mem_d_data_rd_w;
wire mem_d_accept_w, mem_d_ack_w, mem_d_error_w;
wire [10:0] mem_d_resp_tag_w;

riscv_core u_dut (
    .clk_i(clk), .rst_i(rst),
    .mem_d_data_rd_i(mem_d_data_rd_w), .mem_d_accept_i(mem_d_accept_w),
    .mem_d_ack_i(mem_d_ack_w), .mem_d_error_i(mem_d_error_w),
    .mem_d_resp_tag_i(mem_d_resp_tag_w),
    .mem_i_accept_i(mem_i_accept_w), .mem_i_valid_i(mem_i_valid_w),
    .mem_i_error_i(mem_i_error_w), .mem_i_inst_i(mem_i_inst_w),
    .intr_i(1'b0), .reset_vector_i(32'h80000000), .cpu_id_i('b0),
    .mem_d_addr_o(mem_d_addr_w), .mem_d_data_wr_o(mem_d_data_wr_w),
    .mem_d_rd_o(mem_d_rd_w), .mem_d_wr_o(mem_d_wr_w),
    .mem_d_cacheable_o(mem_d_cacheable_w), .mem_d_req_tag_o(mem_d_req_tag_w),
    .mem_d_invalidate_o(mem_d_invalidate_w), .mem_d_writeback_o(mem_d_writeback_w),
    .mem_d_flush_o(mem_d_flush_w),
    .mem_i_rd_o(mem_i_rd_w), .mem_i_flush_o(mem_i_flush_w),
    .mem_i_invalidate_o(mem_i_invalidate_w), .mem_i_pc_o(mem_i_pc_w)
);

tcm_mem u_mem (
    .clk_i(clk), .rst_i(rst),
    .mem_i_rd_i(mem_i_rd_w), .mem_i_flush_i(mem_i_flush_w),
    .mem_i_invalidate_i(mem_i_invalidate_w), .mem_i_pc_i(mem_i_pc_w),
    .mem_d_addr_i(mem_d_addr_w), .mem_d_data_wr_i(mem_d_data_wr_w),
    .mem_d_rd_i(mem_d_rd_w), .mem_d_wr_i(mem_d_wr_w),
    .mem_d_cacheable_i(mem_d_cacheable_w), .mem_d_req_tag_i(mem_d_req_tag_w),
    .mem_d_invalidate_i(mem_d_invalidate_w), .mem_d_writeback_i(mem_d_writeback_w),
    .mem_d_flush_i(mem_d_flush_w),
    .mem_i_accept_o(mem_i_accept_w), .mem_i_valid_o(mem_i_valid_w),
    .mem_i_error_o(mem_i_error_w), .mem_i_inst_o(mem_i_inst_w),
    .mem_d_data_rd_o(mem_d_data_rd_w), .mem_d_accept_o(mem_d_accept_w),
    .mem_d_ack_o(mem_d_ack_w), .mem_d_error_o(mem_d_error_w),
    .mem_d_resp_tag_o(mem_d_resp_tag_w)
);
endmodule
