//`include "../params.vh"

module gshare (
  input clk,
  input reset,

  // from fetch: current instr
  /* verilator lint_off UNUSED */
  input [PC_WIDTH-1:0] pc,

  // from execute: last instr
  input [PC_WIDTH-1:0] prev_pc_first,  // prev pc
  input prev_branch_in_first, // whether prev instr is branch
  input prev_taken_first, // whether prev instr taken
  input [PC_WIDTH-1:0] prev_pc_second,  // prev pc
  input prev_branch_in_second, // whether prev instr is branch
  input prev_taken_second, // whether prev instr taken
  // input prev_pred, // prev instr pred result
  // output prev_mispred, // whether prev instr mispred

  // to out: taken or not taken
  output cur_pred// cur instr pred
);

integer i =0;

// pattern history table 
reg [1:0] PHT [0:PHT_LEN-1];

// global history register
reg [GSHARE_WIDTH-1:0] GHR = 0;

// reg [GSHARE_WIDTH-1:0] prev_idx = 0;

// previous instr's index into PHT; aliasing issue exists
wire [GSHARE_WIDTH-1:0] prev_idx_first = prev_pc_first[GSHARE_WIDTH+1:2] ^ GHR;
wire [GSHARE_WIDTH-1:0] prev_idx_second = prev_pc_second[GSHARE_WIDTH+1:2] ^ GHR;

wire [GSHARE_WIDTH-1:0] cur_idx = pc[GSHARE_WIDTH+1:2] ^ GHR;

// cur pred result
assign cur_pred = PHT[cur_idx][1];

// whether last instr is mispred
// assign prev_mispred = (prev_taken != prev_pred);

always @(posedge clk) begin
  if (reset) begin
    // prev_idx <= 0;
    GHR <= 0;
    for (i = 0; i < PHT_LEN; i = i + 1) begin
      PHT[i] <= 2'b10; // initial: weak taken
    end
  end

  // update GHR using last pc from execute
  if (prev_branch_in_first) begin
    GHR <= {GHR[GSHARE_WIDTH-2:0], prev_taken_first};
  end

  // update PHT using previous taken or not taken result
  if (prev_branch_in_first && prev_taken_first) begin
    case (PHT[prev_idx_first])
      2'b00:
        PHT[prev_idx_first] <= 2'b01;
      2'b01:
        PHT[prev_idx_first] <= 2'b10;
      2'b10:
        PHT[prev_idx_first] <= 2'b11;
      2'b11:
        PHT[prev_idx_first] <= 2'b11;
    endcase
  end else if (prev_branch_in_first && !prev_taken_first) begin
    case (PHT[prev_idx_first])
      2'b00:
        PHT[prev_idx_first] <= 2'b00;
      2'b01:
        PHT[prev_idx_first] <= 2'b00;
      2'b10:
        PHT[prev_idx_first] <= 2'b01;
      2'b11:
        PHT[prev_idx_first] <= 2'b10;
    endcase
  end

  /* verilator lint_on UNUSED */
  
  // update GHR using last pc from execute
  if (prev_branch_in_second) begin
    GHR <= {GHR[GSHARE_WIDTH-2:0], prev_taken_second};
  end

  // update PHT using previous taken or not taken result
  if (prev_branch_in_second && prev_taken_second) begin
    case (PHT[prev_idx_second])
      2'b00:
        PHT[prev_idx_second] <= 2'b01;
      2'b01:
        PHT[prev_idx_second] <= 2'b10;
      2'b10:
        PHT[prev_idx_second] <= 2'b11;
      2'b11:
        PHT[prev_idx_second] <= 2'b11;
    endcase
  end else if (prev_branch_in_second && !prev_taken_second) begin
    case (PHT[prev_idx_second])
      2'b00:
        PHT[prev_idx_second] <= 2'b00;
      2'b01:
        PHT[prev_idx_second] <= 2'b00;
      2'b10:
        PHT[prev_idx_second] <= 2'b01;
      2'b11:
        PHT[prev_idx_second] <= 2'b10;
    endcase
  end
end

endmodule
