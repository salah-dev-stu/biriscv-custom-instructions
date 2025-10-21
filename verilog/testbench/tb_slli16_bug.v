module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
    $display("Starting SLLI by 16 test");

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
reg [31:0] test1, test2, test3, test4, marker;
reg [63:0] mem_word;
initial
begin
    test_results_printed = 0;
    forever begin
        @(posedge clk);
        // Check if PC reaches CSR write instruction
        if (!test_results_printed && u_dut.u_exec0.opcode_pc_i == 32'h80000070) begin
            // Wait 5 cycles for stores to complete
            repeat (5) @(posedge clk);

            // Read results from memory
            mem_word = u_mem.u_ram.ram[14'h1200];
            test1 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1201];
            test2 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1202];
            test3 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1203];
            test4 = mem_word[31:0];

            mem_word = u_mem.u_ram.ram[14'h1204];
            marker = mem_word[31:0];

            $display("");
            $display("==========================================================");
            $display("SLLI by 16 Bug Test:");
            $display("==========================================================");
            $display("Test 1: 0x0000FFFF << 16 = 0x%08h (expected 0xFFFF0000)", test1);
            $display("Test 2: 0x00001111 << 16 = 0x%08h (expected 0x11110000)", test2);
            $display("Test 3: 0x0000AAAA << 16 = 0x%08h (expected 0xAAAA0000)", test3);
            $display("Test 4: 0x0000FFFF << 16 = 0x%08h (expected 0xFFFF0000)", test4);
            $display("Marker: 0x%08h (expected 0xC0FFEE00)", marker);
            $display("");

            if (test1 != 32'hFFFF0000) begin
                $display("ERROR: Test 1 failed!");
                $display("  Expected: %b", 32'hFFFF0000);
                $display("  Got:      %b", test1);
                $display("  Diff:     %b", test1 ^ 32'hFFFF0000);
            end else begin
                $display("Test 1: PASS");
            end

            if (test2 != 32'h11110000) begin
                $display("ERROR: Test 2 failed!");
                $display("  Expected: %b", 32'h11110000);
                $display("  Got:      %b", test2);
                $display("  Diff:     %b", test2 ^ 32'h11110000);
            end else begin
                $display("Test 2: PASS");
            end

            if (test3 != 32'hAAAA0000) begin
                $display("ERROR: Test 3 failed!");
                $display("  Expected: %b", 32'hAAAA0000);
                $display("  Got:      %b", test3);
                $display("  Diff:     %b", test3 ^ 32'hAAAA0000);
            end else begin
                $display("Test 3: PASS");
            end

            if (test4 != 32'hFFFF0000) begin
                $display("ERROR: Test 4 failed!");
                $display("  Expected: %b", 32'hFFFF0000);
                $display("  Got:      %b", test4);
                $display("  Diff:     %b", test4 ^ 32'hFFFF0000);
            end else begin
                $display("Test 4: PASS");
            end

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
    $display("TIMEOUT: Test reached 50000 cycles");
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
