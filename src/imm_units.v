`timescale 1ns / 1ps

module imm_I(in, out);
	input [11:0] in;
	output wire [31:0]out;

	assign out = { {21{in[11]}}, in[10:0]};
endmodule

module imm_S(in, out);

	input [11:0] in;
	output wire [31:0]out;

	assign out = { {21{in[11]}}, in[10:5], in[4:1], in[0]};

endmodule

module imm_B(in, out);
	input [11:0] in;
	output wire [31:0]out;
	
	assign out = { {20{in[11]}}, in[0], in[10:5], in[4:1], 1'b0};
endmodule

module imm_U(in, out);
	input [19:0] in;
	output wire [31:0]out;
	
	assign out = { in[19:0], 12'b0};
endmodule

module imm_J(in, out);
	input [19:0] in;
	output wire [31:0]out;
	
	assign out = { {12{in[19]}},   in[7:0], in[8], in[18:13], in[12:9], 1'b0};
endmodule