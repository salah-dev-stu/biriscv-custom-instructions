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
    $display("Starting CMOV instruction test");

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
reg [31:0] result;
reg [31:0] marker;
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
            // Wait a few cycles for final stores
            repeat (10) @(posedge clk);

            // Read result from memory at 0x80001000 (byte address)
            // Memory is 64-bit wide, indexed by 64-bit words
            // 0x80001000 = byte 4096, word 512
            // Memory stores data with 16-bit word byte-swapping
            result = {u_mem.u_ram.ram[512][23:16], u_mem.u_ram.ram[512][31:24],
                     u_mem.u_ram.ram[512][7:0], u_mem.u_ram.ram[512][15:8]};
            marker = {u_mem.u_ram.ram[512][63:56], u_mem.u_ram.ram[512][55:48],
                     u_mem.u_ram.ram[512][47:40], u_mem.u_ram.ram[512][39:32]};

            $display("");
            $display("==========================================================");
            $display("Test Completed");
            $display("==========================================================");
            $display("Result: 0x%08h (Expected: 0x00002222)", result);
            $display("Marker: 0x%08h (Expected: 0xC0DE000D)", marker);

            if (marker == 32'hC0DE000D) begin
                $display("SUCCESS: Test completed with correct marker!");
            end else begin
                $display("WARNING: Marker mismatch!");
            end

            $display("==========================================================");
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

// Timeout after 100000 cycles
initial
begin
    repeat (100000) @(posedge clk);
    $display("TIMEOUT: Simulation reached 100000 cycles");
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
