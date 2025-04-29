
import cvw::*;
`include "config.vh"
`include "parameter-defs.vh"
module alu_wrapper (input  logic [P.XLEN-1:0] A, B,        // Operands
                   input  logic              W64, UW64,   // W64/.uw-type instruction
                   input  logic              SubArith,    // Subtraction or arithmetic shift
                   input  logic [2:0]        ALUSelect,   // ALU mux select signal
                   input  logic [3:0]        BSelect,     // Binary encoding of if it's a ZBA_ZBB_ZBC_ZBS instruction
                   input  logic [3:0]        ZBBSelect,   // ZBB mux select signal
                   input  logic [2:0]        Funct3,      // For BMU decoding
                   input  logic [6:0]        Funct7,      // For ZKNE and ZKND computation
                   input  logic [4:0]        Rs2E,        // For ZKNE and ZKND computation
                   input  logic [2:0]        BALUControl, // ALU Control signals for B instructions in Execute Stage
                   input  logic              BMUActive,   // Bit manipulation instruction being executed
                   input  logic [1:0]        CZero,       // {czero.nez, czero.eqz} instructions active
                   output logic [P.XLEN-1:0] ALUResult,   // ALU result
                   output logic [P.XLEN-1:0] Sum);        // Sum of operands

alu   #(P) alu(.A(A), .B(B), .W64(W64), .UW64(UW64), 
                .SubArith(SubArith), .ALUSelect(ALUSelect), .BSelect(BSelect), 
                .ZBBSelect(ZBBSelect), .Funct3(Funct3), .Funct7(Funct7), 
                .Rs2E(Rs2E), .BALUControl(BALUControl), .BMUActive(BMUActive),
                .CZero(CZero), .ALUResult(ALUResult), .Sum(Sum));


endmodule