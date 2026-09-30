# Timing Optimization Pass 3 — Registered RF Source Indices

The post-synthesis critical path after pass 2 was:

- Startpoint `_2628_` = `dbg_ir[15]` / instruction-register opcode bit
- Endpoint `_2550_` = `dmem_wdata[1]`, optimized from the `op_b_q` storage path

This shows the remaining setup bottleneck is the DECODE path from the instruction opcode through source-address selection and the asynchronous 8x16 register-file read mux into the operand register.

Pass 3 adds two 3-bit source-index registers (`src1_idx_q`, `src2_idx_q`) and one FSM state (`S_RF_READ`).

The path is now split into:

1. `IR/opcode -> source-index registers`
2. `source-index registers -> register-file read mux -> op_a_q/op_b_q`

The ISA is unchanged. Non-JMP instructions gain one internal cycle. The directed self-check remains valid with the existing 180-cycle run length.
