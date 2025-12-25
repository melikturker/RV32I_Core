`timescale 1ps / 1ps

module PC_sel_Unit(opcode, funct3, is_flushed, Z, N, RF_sel_in, flush, RF_sel_out, PC_sel, rst);

	input [6:0] opcode;
	input [2:0] funct3, RF_sel_in;
	input is_flushed, Z, N, rst;
	
	output reg [2:0] RF_sel_out;
	output reg [1:0] PC_sel;
	output reg flush;

	
	always @(*) begin
		// Default assignments to prevent latch
		RF_sel_out = RF_sel_in;
		PC_sel = 2'b00;  // PC+4 (normal sequential execution)
		flush = 1'b0;
	
		if(rst) begin
			RF_sel_out = 3'b000;
			PC_sel = 2'b00;
			flush = 1'b0;
		end
		
		else begin
			case(opcode) 
				7'b0010111: begin //AUIPC
					RF_sel_out = RF_sel_in;
					PC_sel = 2'b00; 
					flush = 1'b0;
				end
				
				7'b1101111: begin // JAL
					RF_sel_out = RF_sel_in;
					PC_sel = 2'b10;
					flush = 1'b1;
				end
				
				7'b1100111: begin //JALR
					if(funct3 == 3'b000) begin 
						RF_sel_out = RF_sel_in;
						PC_sel = 2'b11;
						flush = 1'b1;
					end
				end
				
				7'b0010011: begin // I-type (addi, andi, slli, ...)
					RF_sel_out = RF_sel_in;
					// PC_sel and flush use defaults (00, 0)
				end
				
				7'b0110011: begin // R-type (add, sub, and, ...)
					RF_sel_out = RF_sel_in;
					// PC_sel and flush use defaults (00, 0)
				end 
				
				
				7'b1100011: begin // B types
					
					RF_sel_out = RF_sel_in;
					
					case (funct3)
						3'b000: begin // BEQ
							if(Z) begin
								PC_sel = 2'b01; 
								flush = 1'b1;
							end
							else begin 
								PC_sel = 2'b00; 
								flush = 1'b0;
							end
						end
						
						3'b001: begin // BNE
							if(!Z) begin
								PC_sel = 2'b01; 
								flush = 1'b1;
							end
							else begin 
								PC_sel = 2'b00; 
								flush = 1'b0;
							end
						end
						
						3'b100: begin // BLT
							if(N) begin
								PC_sel = 2'b01; 
								flush = 1'b1;
							end
							else begin 
								PC_sel = 2'b00; 
								flush = 1'b0;
							end
						end
						
						3'b101: begin //BGE
							if(!N) begin
								PC_sel = 2'b01; 
								flush = 1'b1;
							end
							else begin 
								PC_sel = 2'b00; 
								flush = 1'b0;
							end
						end
						
						3'b110: begin // BLTU
							if(N) begin
								PC_sel = 2'b01; 
								flush = 1'b1;
							end
							else begin 
								PC_sel = 2'b00; 
								flush = 1'b0;
							end
						end
						
						3'b111: begin // BGEU
							if(!N) begin
								PC_sel = 2'b01; 
								flush = 1'b1;
							end
							else begin 
								PC_sel = 2'b00; 
								flush = 1'b0;
							end
						end
					endcase
				end
				
				default: begin 
					RF_sel_out = RF_sel_in;
					PC_sel = 2'b00;
					flush = 1'b0;
				end
			endcase
		end
	end
endmodule 