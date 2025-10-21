`timescale 1ns/1ps

module tb_brev_sanity_check;

reg clk;
reg rst;

// Instantiate the DUT
biriscv_top u_dut (
    .clk_i(clk),
    .rst_i(rst),
    .intr_i(1'b0),
    .reset_vector_i(32'h80000000)
);

// Clock generation
always #5 clk = ~clk;

// Monitor for test completion (CSR write)
reg [31:0] test_results [0:11];
integer i;
initial begin
    clk = 0;
    rst = 1;

    #100;
    rst = 0;

    @(negedge rst);

    // Wait for CSR write indicating completion
    forever begin
        @(posedge clk);
        if (u_dut.u_exec0.opcode_valid_i &&
            (u_dut.u_exec0.opcode_opcode_i[6:0] == 7'b1110011) &&
            (u_dut.u_exec0.opcode_opcode_i[14:12] == 3'b001)) begin

            repeat (10) @(posedge clk);

            // Read all test results from memory (0x80009000 = RAM address 0x1200)
            for (i = 0; i < 12; i = i + 1) begin
                test_results[i] = {u_mem.u_ram.ram[14'h1200 + i][31:0]};
            end

            $display("==========================================================");
            $display("BREV Comprehensive Sanity Check Results");
            $display("==========================================================");
            $display("Test 1  (Basic):        %s", test_results[0] == 32'h600D0001 ? "PASS" : "FAIL");
            $display("Test 2  (Double BREV):  %s", test_results[1] == 32'h600D0002 ? "PASS" : "FAIL");
            $display("Test 3  (BREV+Shift):   %s", test_results[2] == 32'h600D0003 ? "PASS" : "FAIL");
            $display("Test 4  (Loop):         %s", test_results[3] == 32'h600D0004 ? "PASS" : "FAIL");
            $display("Test 5  (Arithmetic):   %s", test_results[4] == 32'h600D0005 ? "PASS" : "FAIL");
            $display("Test 6  (Conditional):  %s", test_results[5] == 32'h600D0006 ? "PASS" : "FAIL");
            $display("Test 7  (Alternating):  %s", test_results[6] == 32'h600D0007 ? "PASS" : "FAIL");
            $display("Test 8  (Function):     %s", test_results[7] == 32'h600D0008 ? "PASS" : "FAIL");
            $display("Test 9  (Rotate):       %s", test_results[8] == 32'h600D0009 ? "PASS" : "FAIL");
            $display("Test 10 (Edge Cases):   %s", test_results[9] == 32'h600D000A ? "PASS" : "FAIL");
            $display("==========================================================");
            $display("Pass Count: %0d", test_results[10]);
            $display("Total Tests: %0d", test_results[11]);
            $display("==========================================================");

            if (test_results[10] == 10 && test_results[11] == 10) begin
                $display("*** ALL TESTS PASSED - BREV IS WORKING CORRECTLY ***");
            end else begin
                $display("*** SOME TESTS FAILED - CHECK BREV IMPLEMENTATION ***");
            end
            $display("");

            $finish;
        end
    end
end

// Timeout
initial begin
    #100000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule
