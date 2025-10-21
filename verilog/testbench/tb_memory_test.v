module tb_top;

reg clk;
reg rst;
reg [7:0] mem[131072:0];
integer i, f;

initial
begin
    $display("Starting memory test");

    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

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

// Monitor for completion
reg [63:0] mem_word;
reg [31:0] test_results[0:8];
initial
begin
    @(negedge rst);
    repeat (10) @(posedge clk);

    // Wait for CSR write
    wait(u_dut.u_exec0.opcode_pc_i == 32'h80000054);
    repeat (5) @(posedge clk);

    // Read all test results
    mem_word = u_mem.u_ram.ram[14'h1200];
    test_results[0] = mem_word[31:0];
    test_results[1] = mem_word[63:32];

    mem_word = u_mem.u_ram.ram[14'h1201];
    test_results[2] = mem_word[31:0];
    test_results[3] = mem_word[63:32];

    mem_word = u_mem.u_ram.ram[14'h1202];
    test_results[4] = mem_word[31:0];
    test_results[5] = mem_word[63:32];

    mem_word = u_mem.u_ram.ram[14'h1203];
    test_results[6] = mem_word[31:0];
    test_results[7] = mem_word[63:32];

    mem_word = u_mem.u_ram.ram[14'h1204];
    test_results[8] = mem_word[31:0];

    $display("\n========== Memory Test Results ==========");
    $display("Test 1 (li -1):             Expected 0xFFFFFFFF, Got 0x%08h %s", test_results[0], test_results[0] == 32'hFFFFFFFF ? "PASS" : "FAIL");
    $display("Test 2 (li 0xAAAAAAAA):     Expected 0xAAAAAAAA, Got 0x%08h %s", test_results[1], test_results[1] == 32'hAAAAAAAA ? "PASS" : "FAIL");
    $display("Test 3 (li 0x12345678):     Expected 0x12345678, Got 0x%08h %s", test_results[2], test_results[2] == 32'h12345678 ? "PASS" : "FAIL");
    $display("Test 4 (lw/sw passthrough): Expected 0xFFFFFFFF, Got 0x%08h %s", test_results[3], test_results[3] == 32'hFFFFFFFF ? "PASS" : "FAIL");
    $display("Test 5 (AND -1 & -1):       Expected 0xFFFFFFFF, Got 0x%08h %s", test_results[4], test_results[4] == 32'hFFFFFFFF ? "PASS" : "FAIL");
    $display("Test 6 (OR 0 | -1):         Expected 0xFFFFFFFF, Got 0x%08h %s", test_results[5], test_results[5] == 32'hFFFFFFFF ? "PASS" : "FAIL");
    $display("Test 7 (SLLI 1 << 31):      Expected 0x80000000, Got 0x%08h %s", test_results[6], test_results[6] == 32'h80000000 ? "PASS" : "FAIL");
    $display("Test 8 (SRLI 0x8000>>31):   Expected 0x00000001, Got 0x%08h %s", test_results[7], test_results[7] == 32'h00000001 ? "PASS" : "FAIL");
    $display("Marker:                     Expected 0xC0FFEE00, Got 0x%08h %s", test_results[8], test_results[8] == 32'hC0FFEE00 ? "PASS" : "FAIL");
    $display("=========================================\n");

    $finish;
end

// Timeout
initial
begin
    repeat (10000) @(posedge clk);
    $display("TIMEOUT");
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
