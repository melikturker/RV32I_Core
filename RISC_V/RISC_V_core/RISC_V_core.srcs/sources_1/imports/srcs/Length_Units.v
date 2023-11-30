

module Store_Length_Unit(data_in, word_length_in, word_length_out, data_out);
	
	input [31:0] data_in;
	input [1:0] word_length_in; 	// Instead of defining a new variable, func3 can be used to determine length of the data.
	
	output reg [31:0] data_out;
	output reg [1:0] word_length_out;
	
	always @(*) begin
		
		word_length_out = word_length_in;
	
		case(word_length_in)
	
			2'b00: begin // Byte
				data_out = {{24'b0}, data_in[7:0]};	// Only least significant byte of the 32 bit signal will be placed into memory
			end
			
			2'b01: begin // Half Word
				data_out = {{16'b0}, data_in[15:0]};
			end
			
			2'b10: begin // Word
				data_out = data_in;
			end
			
			default: begin
				data_out = data_in;
			end
			
		endcase
	
	end

endmodule 

module Load_Length_Unit(data_in, word_length, is_signed, data_out);
	
	input [31:0] data_in;
	input [1:0] word_length; // Instead of defining a new variable, func3 can be used to determine length of the data.
	input is_signed;
	
	output reg [31:0] data_out;
	
	always @(*)begin
		
		case(word_length)
			
			2'b00: begin	// Byte
				if (is_signed) data_out = { {24{data_in[7]}},  data_in[7:0]};  
				else	data_out = { {24'b0},  data_in[7:0]};  
			end
			2'b01: begin	// Half Word
				if (is_signed) data_out = { {16{data_in[15]}},  data_in[15:0]};  
				else	data_out = { {16'b0},  data_in[15:0]};  
			end
			2'b10: begin	// Word
				data_out = data_in;
			end
			default: begin 
			end
			
			
		endcase
	
	end

endmodule 

