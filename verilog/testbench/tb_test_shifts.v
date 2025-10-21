module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting shift instruction test");

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

// Monitor for test completion (PC reaches CSR write at 0x80000010)
reg test_results_printed;
reg [31:0] mem_results[0:7];
reg [63:0] mem_word;
initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if PC reaches CSR write instruction (at 0x80000074)
        if (!test_results_printed && u_dut.u_exec0.opcode_pc_i == 32'h80000074) begin
            // Wait 5 cycles for stores and final updates to complete
            repeat (5) @(posedge clk);

            // Read results from memory (0x80009000+ = word addresses 0x1200+)
            // RAM is 64-bit wide, byte address 0x80009000 >> 3 = 0x1200
            mem_word = u_mem.u_ram.ram[14'h1200];
            mem_results[0] = mem_word[31:0];
            mem_results[1] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1201];
            mem_results[2] = mem_word[31:0];
            mem_results[3] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1202];
            mem_results[4] = mem_word[31:0];
            mem_results[5] = mem_word[63:32];

            mem_word = u_mem.u_ram.ram[14'h1203];
            mem_results[6] = mem_word[31:0];
            mem_results[7] = mem_word[63:32];

            $display("");
            $display("==========================================================");
            $display("Shift Instruction Test Results:");
            $display("==========================================================");
            $display("Test Description| Expected     | Actual       | Status");
            $display("----------------|--------------|--------------|--------");
            $display("SRLI 4 bits     | 0x01234567   | 0x%08h   | %s", mem_results[0], (mem_results[0] == 32'h01234567) ? "PASS" : "FAIL");
            $display("SRLI 16 bits    | 0x0000ABCD   | 0x%08h   | %s", mem_results[1], (mem_results[1] == 32'h0000ABCD) ? "PASS" : "FAIL");
            $display("SRLI 31 bits    | 0x00000001   | 0x%08h   | %s", mem_results[2], (mem_results[2] == 32'h00000001) ? "PASS" : "FAIL");
            $display("SRLI 1 bit      | 0x7FFFFFFF   | 0x%08h   | %s", mem_results[3], (mem_results[3] == 32'h7FFFFFFF) ? "PASS" : "FAIL");
            $display("SRL 31 (reg)    | 0x00000001   | 0x%08h   | %s", mem_results[4], (mem_results[4] == 32'h00000001) ? "PASS" : "FAIL");
            $display("SLLI+SRLI chain | 0x00000001   | 0x%08h   | %s", mem_results[5], (mem_results[5] == 32'h00000001) ? "PASS" : "FAIL");
            $display("Completion Mark | 0xC0FFEE00   | 0x%08h   | %s", mem_results[6], (mem_results[6] == 32'hC0FFEE00) ? "PASS" : "FAIL");
            $display("==========================================================");
            $display("");

            test_results_printed = 1;
            $finish;
        end
    end
end

// Timeout after 50000 cycles
initial
begin
    repeat (50000) @(posedge clk);
    $display("TIMEOUT: Shift test reached 50000 cycles");
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
