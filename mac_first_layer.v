module mac_first_layer(
	weigth_or_bias,
	one_or_pixel,
	clk,
	enable,
	rst,
	clear_acc,
	out_q4_12
);

	input signed [15:0] weigth_or_bias;
	input [8:0] one_or_pixel;
	input clk, enable, rst, clear_acc;
	
	output signed [15:0] out_q4_12;
	
	wire signed [15:0] in_signed = {3'b000, one_or_pixel, 4'h0};
	wire signed [31:0] product;
	
	assign product = in_signed * weigth_or_bias;
	
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