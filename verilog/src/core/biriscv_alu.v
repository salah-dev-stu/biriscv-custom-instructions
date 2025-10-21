//-----------------------------------------------------------------
//                         biRISC-V CPU
//                            V0.8.1
//                     Ultra-Embedded.com
//                     Copyright 2019-2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------
module biriscv_alu
(
    // Inputs
     input  [  4:0]  alu_op_i
    ,input  [ 31:0]  alu_a_i
    ,input  [ 31:0]  alu_b_i
    ,input  [ 31:0]  alu_c_i
    ,input  [  7:0]  alu_imm8_i

    // Outputs
    ,output [ 31:0]  alu_p_o
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [31:0]      result_r;

reg [31:16]     shift_right_fill_r;
reg [31:0]      shift_right_1_r;
reg [31:0]      shift_right_2_r;
reg [31:0]      shift_right_4_r;
reg [31:0]      shift_right_8_r;

reg [31:0]      shift_left_1_r;
reg [31:0]      shift_left_2_r;
reg [31:0]      shift_left_4_r;
reg [31:0]      shift_left_8_r;

// SAD temporary registers for absolute differences
reg [8:0] sad_abs0_r, sad_abs1_r, sad_abs2_r, sad_abs3_r;

wire [31:0]     sub_res_w = alu_a_i - alu_b_i;

//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------
always @ (alu_op_i or alu_a_i or alu_b_i or alu_c_i or alu_imm8_i or sub_res_w)
begin
    shift_right_fill_r = 16'b0;
    shift_right_1_r = 32'b0;
    shift_right_2_r = 32'b0;
    shift_right_4_r = 32'b0;
    shift_right_8_r = 32'b0;

    shift_left_1_r = 32'b0;
    shift_left_2_r = 32'b0;
    shift_left_4_r = 32'b0;
    shift_left_8_r = 32'b0;

    case (alu_op_i)
       //----------------------------------------------
       // Shift Left
       //----------------------------------------------   
       `ALU_SHIFTL :
       begin
            if (alu_b_i[0] == 1'b1)
                shift_left_1_r = {alu_a_i[30:0],1'b0};
            else
                shift_left_1_r = alu_a_i;

            if (alu_b_i[1] == 1'b1)
                shift_left_2_r = {shift_left_1_r[29:0],2'b00};
            else
                shift_left_2_r = shift_left_1_r;

            if (alu_b_i[2] == 1'b1)
                shift_left_4_r = {shift_left_2_r[27:0],4'b0000};
            else
                shift_left_4_r = shift_left_2_r;

            if (alu_b_i[3] == 1'b1)
                shift_left_8_r = {shift_left_4_r[23:0],8'b00000000};
            else
                shift_left_8_r = shift_left_4_r;

            if (alu_b_i[4] == 1'b1)
                result_r = {shift_left_8_r[15:0],16'b0000000000000000};
            else
                result_r = shift_left_8_r;
       end
       //----------------------------------------------
       // Shift Right
       //----------------------------------------------
       `ALU_SHIFTR, `ALU_SHIFTR_ARITH:
       begin
            // Arithmetic shift? Fill with 1's if MSB set
            if (alu_a_i[31] == 1'b1 && alu_op_i == `ALU_SHIFTR_ARITH)
                shift_right_fill_r = 16'b1111111111111111;
            else
                shift_right_fill_r = 16'b0000000000000000;

            if (alu_b_i[0] == 1'b1)
                shift_right_1_r = {shift_right_fill_r[31], alu_a_i[31:1]};
            else
                shift_right_1_r = alu_a_i;

            if (alu_b_i[1] == 1'b1)
                shift_right_2_r = {shift_right_fill_r[31:30], shift_right_1_r[31:2]};
            else
                shift_right_2_r = shift_right_1_r;

            if (alu_b_i[2] == 1'b1)
                shift_right_4_r = {shift_right_fill_r[31:28], shift_right_2_r[31:4]};
            else
                shift_right_4_r = shift_right_2_r;

            if (alu_b_i[3] == 1'b1)
                shift_right_8_r = {shift_right_fill_r[31:24], shift_right_4_r[31:8]};
            else
                shift_right_8_r = shift_right_4_r;

            if (alu_b_i[4] == 1'b1)
                result_r = {shift_right_fill_r[31:16], shift_right_8_r[31:16]};
            else
                result_r = shift_right_8_r;
       end       
       //----------------------------------------------
       // Arithmetic
       //----------------------------------------------
       `ALU_ADD : 
       begin
            result_r      = (alu_a_i + alu_b_i);
       end
       `ALU_SUB : 
       begin
            result_r      = sub_res_w;
       end
       //----------------------------------------------
       // Logical
       //----------------------------------------------       
       `ALU_AND : 
       begin
            result_r      = (alu_a_i & alu_b_i);
       end
       `ALU_OR  : 
       begin
            result_r      = (alu_a_i | alu_b_i);
       end
       `ALU_XOR : 
       begin
            result_r      = (alu_a_i ^ alu_b_i);
       end
       //----------------------------------------------
       // Comparision
       //----------------------------------------------
       `ALU_LESS_THAN : 
       begin
            result_r      = (alu_a_i < alu_b_i) ? 32'h1 : 32'h0;
       end
       `ALU_LESS_THAN_SIGNED :
       begin
            if (alu_a_i[31] != alu_b_i[31])
                result_r  = alu_a_i[31] ? 32'h1 : 32'h0;
            else
                result_r  = sub_res_w[31] ? 32'h1 : 32'h0;
       end
       //----------------------------------------------
       // Conditional Select
       //----------------------------------------------
       `ALU_CSEL :
       begin
            result_r      = (alu_c_i == 32'b0) ? alu_a_i : alu_b_i;
       end
       //----------------------------------------------
       // Bit Reverse
       //----------------------------------------------
       `ALU_BREV :
       begin
            // Reverse all 32 bits: bit 0 becomes bit 31, bit 1 becomes bit 30, etc.
            result_r = {alu_a_i[0],  alu_a_i[1],  alu_a_i[2],  alu_a_i[3],
                        alu_a_i[4],  alu_a_i[5],  alu_a_i[6],  alu_a_i[7],
                        alu_a_i[8],  alu_a_i[9],  alu_a_i[10], alu_a_i[11],
                        alu_a_i[12], alu_a_i[13], alu_a_i[14], alu_a_i[15],
                        alu_a_i[16], alu_a_i[17], alu_a_i[18], alu_a_i[19],
                        alu_a_i[20], alu_a_i[21], alu_a_i[22], alu_a_i[23],
                        alu_a_i[24], alu_a_i[25], alu_a_i[26], alu_a_i[27],
                        alu_a_i[28], alu_a_i[29], alu_a_i[30], alu_a_i[31]};
       end
       //----------------------------------------------
       // Bitwise Ternary Logic (2-source + 8-bit immediate)
       //----------------------------------------------
       `ALU_TERNLOG :
       begin
            // For each bit position, use rs1[i], rs2[i], 0 as 3-bit index into imm8 LUT
            // Third input is constant 0, so index = {rs1[i], rs2[i], 0}
            result_r = {alu_imm8_i[{alu_a_i[31], alu_b_i[31], 1'b0}],
                        alu_imm8_i[{alu_a_i[30], alu_b_i[30], 1'b0}],
                        alu_imm8_i[{alu_a_i[29], alu_b_i[29], 1'b0}],
                        alu_imm8_i[{alu_a_i[28], alu_b_i[28], 1'b0}],
                        alu_imm8_i[{alu_a_i[27], alu_b_i[27], 1'b0}],
                        alu_imm8_i[{alu_a_i[26], alu_b_i[26], 1'b0}],
                        alu_imm8_i[{alu_a_i[25], alu_b_i[25], 1'b0}],
                        alu_imm8_i[{alu_a_i[24], alu_b_i[24], 1'b0}],
                        alu_imm8_i[{alu_a_i[23], alu_b_i[23], 1'b0}],
                        alu_imm8_i[{alu_a_i[22], alu_b_i[22], 1'b0}],
                        alu_imm8_i[{alu_a_i[21], alu_b_i[21], 1'b0}],
                        alu_imm8_i[{alu_a_i[20], alu_b_i[20], 1'b0}],
                        alu_imm8_i[{alu_a_i[19], alu_b_i[19], 1'b0}],
                        alu_imm8_i[{alu_a_i[18], alu_b_i[18], 1'b0}],
                        alu_imm8_i[{alu_a_i[17], alu_b_i[17], 1'b0}],
                        alu_imm8_i[{alu_a_i[16], alu_b_i[16], 1'b0}],
                        alu_imm8_i[{alu_a_i[15], alu_b_i[15], 1'b0}],
                        alu_imm8_i[{alu_a_i[14], alu_b_i[14], 1'b0}],
                        alu_imm8_i[{alu_a_i[13], alu_b_i[13], 1'b0}],
                        alu_imm8_i[{alu_a_i[12], alu_b_i[12], 1'b0}],
                        alu_imm8_i[{alu_a_i[11], alu_b_i[11], 1'b0}],
                        alu_imm8_i[{alu_a_i[10], alu_b_i[10], 1'b0}],
                        alu_imm8_i[{alu_a_i[9],  alu_b_i[9],  1'b0}],
                        alu_imm8_i[{alu_a_i[8],  alu_b_i[8],  1'b0}],
                        alu_imm8_i[{alu_a_i[7],  alu_b_i[7],  1'b0}],
                        alu_imm8_i[{alu_a_i[6],  alu_b_i[6],  1'b0}],
                        alu_imm8_i[{alu_a_i[5],  alu_b_i[5],  1'b0}],
                        alu_imm8_i[{alu_a_i[4],  alu_b_i[4],  1'b0}],
                        alu_imm8_i[{alu_a_i[3],  alu_b_i[3],  1'b0}],
                        alu_imm8_i[{alu_a_i[2],  alu_b_i[2],  1'b0}],
                        alu_imm8_i[{alu_a_i[1],  alu_b_i[1],  1'b0}],
                        alu_imm8_i[{alu_a_i[0],  alu_b_i[0],  1'b0}]};
       end
       //----------------------------------------------
       // Conditional Move (condition evaluated in exec stage)
       //----------------------------------------------
       `ALU_CMOV :
       begin
            // alu_c_i contains the condition evaluation result (1 bit extended to 32)
            // If condition is true (alu_c_i != 0), select alu_a_i, else select alu_b_i
            result_r      = (alu_c_i != 32'b0) ? alu_a_i : alu_b_i;
       end
       //----------------------------------------------
       // Sum of Absolute Differences (4x 8-bit packed)
       //----------------------------------------------
       `ALU_SAD :
       begin
            // Compute absolute differences directly (unsigned comparison avoids signed arithmetic issues)
            sad_abs0_r = (alu_a_i[7:0] >= alu_b_i[7:0]) ?
                         {1'b0, alu_a_i[7:0] - alu_b_i[7:0]} :
                         {1'b0, alu_b_i[7:0] - alu_a_i[7:0]};

            sad_abs1_r = (alu_a_i[15:8] >= alu_b_i[15:8]) ?
                         {1'b0, alu_a_i[15:8] - alu_b_i[15:8]} :
                         {1'b0, alu_b_i[15:8] - alu_a_i[15:8]};

            sad_abs2_r = (alu_a_i[23:16] >= alu_b_i[23:16]) ?
                         {1'b0, alu_a_i[23:16] - alu_b_i[23:16]} :
                         {1'b0, alu_b_i[23:16] - alu_a_i[23:16]};

            sad_abs3_r = (alu_a_i[31:24] >= alu_b_i[31:24]) ?
                         {1'b0, alu_a_i[31:24] - alu_b_i[31:24]} :
                         {1'b0, alu_b_i[31:24] - alu_a_i[31:24]};

            // Sum all absolute differences and add to accumulator (rs3 = alu_c_i)
            result_r = alu_c_i + {23'b0, sad_abs0_r} + {23'b0, sad_abs1_r} + {23'b0, sad_abs2_r} + {23'b0, sad_abs3_r};
       end
       default  :
       begin
            result_r      = alu_a_i;
       end
    endcase
end

assign alu_p_o    = result_r;

endmodule
