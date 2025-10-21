module tb_top;

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

// Performance counters
integer instruction_count;
integer cycle_count;

initial
begin
    $display("Starting real-world TERNLOG comparison test");

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

// Performance counter: count retired instructions and cycles
initial
begin
    instruction_count = 0;
    cycle_count = 0;

    @(negedge rst);

    forever begin
        @(posedge clk);
        cycle_count = cycle_count + 1;

        // Count pipe0 instruction retirement
        if (u_dut.u_issue.pipe0_valid_wb_w) begin
            instruction_count = instruction_count + 1;
        end

        // Count pipe1 instruction retirement (dual-issue core)
        if (u_dut.u_issue.pipe1_valid_wb_w) begin
            instruction_count = instruction_count + 1;
        end
    end
end

// Monitor for test completion (CSR write)
reg [63:0] mem_word;
reg [31:0] results [0:13];
integer j;
initial
begin
    @(negedge rst);

    // Wait for CSR write to complete
    forever begin
        @(posedge clk);
        // Check for CSR write instruction (could be any CSR write)
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b1110011) &&
            (u_dut.u_exec0.opcode_opcode_i[14:12] == 3'b001)) begin
            // Wait a few cycles for final stores
            repeat (10) @(posedge clk);

            // Read all 13 results from memory (0x80009000 = RAM address 0x1200)
            for (j = 0; j < 7; j = j + 1) begin
                mem_word = u_mem.u_ram.ram[14'h1200 + j];
                results[j*2] = mem_word[31:0];
                results[j*2 + 1] = mem_word[63:32];
            end

            $display("");
            $display("==========================================================");
            $display("Real-World TERNLOG Test Results");
            $display("Network Packet Filtering with Boolean Logic");
            $display("==========================================================");
            $display("Operation #  | Test Case              | Result");
            $display("-------------|------------------------|----------");
            $display("1            | ACL Filter             | 0x%08h", results[0]);
            $display("2            | Protocol Field Manip   | 0x%08h", results[1]);
            $display("3            | XOR Checksum           | 0x%08h", results[2]);
            $display("4            | Security Masking       | 0x%08h", results[3]);
            $display("5            | Copy A                 | 0x%08h", results[4]);
            $display("6            | XOR                    | 0x%08h", results[5]);
            $display("7            | AND Filter             | 0x%08h", results[6]);
            $display("8            | OR Combine             | 0x%08h", results[7]);
            $display("9            | NAND                   | 0x%08h", results[8]);
            $display("10           | AND NOT                | 0x%08h", results[9]);
            $display("11           | Implies                | 0x%08h", results[10]);
            $display("12           | NOR                    | 0x%08h", results[11]);
            $display("Marker       |                        | 0x%08h", results[12]);
            $display("==========================================================");
            $display("");

            // Verify results match between baseline and optimized
            if (results[0]  == 32'hffff9dff &&
                results[1]  == 32'habcd5500 &&
                results[2]  == 32'h77777777 &&
                results[3]  == 32'hfefdfeff &&
                results[4]  == 32'haaaaaaaa &&
                results[5]  == 32'h66666666 &&
                results[6]  == 32'h00000000 &&
                results[7]  == 32'hffffffff &&
                results[8]  == 32'h77777777 &&
                results[9]  == 32'h22222222 &&
                results[10] == 32'hdddddddd &&
                results[11] == 32'hffffffff &&
                results[12] == 32'hc0de000d) begin
                $display("==========================================");
                $display("ALL TERNLOG TESTS PASSED!");
                $display("==========================================");
            end else begin
                $display("==========================================");
                $display("TEST FAILURES DETECTED!");
                $display("==========================================");
                if (results[0]  != 32'hffff9dff) $display("FAIL: ACL Filter - Expected 0xffff9dff, Got 0x%08h", results[0]);
                if (results[1]  != 32'habcd5500) $display("FAIL: Protocol Field - Expected 0xabcd5500, Got 0x%08h", results[1]);
                if (results[2]  != 32'h77777777) $display("FAIL: XOR Checksum - Expected 0x77777777, Got 0x%08h", results[2]);
                if (results[3]  != 32'hfefdfeff) $display("FAIL: Security Mask - Expected 0xfefdfeff, Got 0x%08h", results[3]);
                if (results[4]  != 32'haaaaaaaa) $display("FAIL: Copy A - Expected 0xaaaaaaaa, Got 0x%08h", results[4]);
                if (results[5]  != 32'h66666666) $display("FAIL: XOR - Expected 0x66666666, Got 0x%08h", results[5]);
                if (results[6]  != 32'h00000000) $display("FAIL: AND Filter - Expected 0x00000000, Got 0x%08h", results[6]);
                if (results[7]  != 32'hffffffff) $display("FAIL: OR Combine - Expected 0xffffffff, Got 0x%08h", results[7]);
                if (results[8]  != 32'h77777777) $display("FAIL: NAND - Expected 0x77777777, Got 0x%08h", results[8]);
                if (results[9]  != 32'h22222222) $display("FAIL: AND NOT - Expected 0x22222222, Got 0x%08h", results[9]);
                if (results[10] != 32'hdddddddd) $display("FAIL: Implies - Expected 0xdddddddd, Got 0x%08h", results[10]);
                if (results[11] != 32'hffffffff) $display("FAIL: NOR - Expected 0xffffffff, Got 0x%08h", results[11]);
                if (results[12] != 32'hc0de000d) $display("FAIL: Marker - Expected 0xc0de000d, Got 0x%08h", results[12]);
                $display("==========================================");
            end
            $display("");

            // Display performance metrics
            $display("==========================================");
            $display("Performance Metrics:");
            $display("==========================================");
            $display("Total Cycles: %0d", cycle_count);
            $display("Total Instructions Retired: %0d", instruction_count);
            $display("CPI (Cycles Per Instruction): %f", $itor(cycle_count) / $itor(instruction_count));
            $display("IPC (Instructions Per Cycle): %f", $itor(instruction_count) / $itor(cycle_count));
            $display("==========================================\n");

            $finish;
        end
    end
end

// Timeout after 50000 cycles
initial
begin
    repeat (50000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 50000 cycles");
    $display("Performance: Cycles=%0d Instructions=%0d", cycle_count, instruction_count);
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
