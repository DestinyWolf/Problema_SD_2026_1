module mac_second_layer(
	data_register,
	data_beta,
	clk,
	enable,
	rst,
	clear_acc,
	out_q4_12
);

	input signed [15:0] data_register;
	input signed [15:0] data_beta;
	input clk, enable, rst, clear_acc;
	
	output signed [15:0] out_q4_12;
	
	wire signed [15:0] in_signed = data_beta;
	wire signed [31:0] product;
	
	assign product = in_signed * data_register;
	
	reg signed [31:0] accumulator;
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			accumulator <= 32'sd0;
		end else if (clear_acc) begin
			accumulator <= 32'sd0;
		end else if (enable) begin
			accumulator <= accumulator + product;
		end
	end
	
	
	assign out_q4_12 = accumulator[27:12];
	
endmodule