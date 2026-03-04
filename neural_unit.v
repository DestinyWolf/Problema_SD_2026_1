module neural_unit(
	addr_mem_bias,
	addr_mem_pixel,
	addr_mem_win,
	addr_mem_beta,
	req_bias,
	req_win,
	req_beta,
	req_pixel,
	is_available_bias,
	is_available_beta,
	is_available_win,
	is_available_pixel,
	data_in_bias,
	data_in_beta,
	data_in_win,
	data_in_pixel,
	clk,
	enable,
	rst,
	output_digit,
	done
	
	
	//to debug
	
);

	input is_available_beta, is_available_bias, is_available_pixel, is_available_win;
	input clk, rst, enable;
	output req_beta, req_bias, req_pixel, req_win;
	output reg done;
	output [3:0] output_digit;
	output [9:0] addr_mem_pixel;
	output [6:0] addr_mem_bias;
	output [16:0] addr_mem_win;
	output [10:0] addr_mem_beta;
	input signed [15:0] data_in_beta, data_in_bias, data_in_win;
	input [7:0] data_in_pixel;


	localparam IDLE = 3'b0, FIRST_LAYER=3'b1, SECOND_LAYER=3'b10, ARGMAX=3'b11, DONE=3'b100;
	reg [2:0] state;
	wire [4:0] first_layer_iteration_counter;
	wire first_layer_iteration_done;
	wire [6:0] addr_register_write_first_layer;
	wire enable_register_write_first_layer;
	wire [3:0] addr_register_write_second_layer;
	wire second_layer_iteration_done, second_layer_iteration_counter;
	wire enable_register_write_second_layer;
	wire argmax_iteration_done;
	wire signed [15:0] data_out_first_layer;
	wire signed [15:0] data_out_second_layer;
	wire signed [15:0] data_out_from_register_to_second_layer;
	wire [6:0] addr_register_read_second_layer;
	wire [3:0] addr_register_read_argmax;
	wire signed [15:0] data_out_from_register_to_argmax;
	
	
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
					if (enable) begin
						state <= FIRST_LAYER;
					end else begin
						state <= IDLE;
					end
				end
				FIRST_LAYER: begin
					if (first_layer_iteration_done) begin
						state <= SECOND_LAYER;
					end else begin
						state <= FIRST_LAYER;
					end
				end
				SECOND_LAYER: begin
					if (second_layer_iteration_done) begin
						state <= ARGMAX;
					end else begin
						state <= SECOND_LAYER;
					end
				end
				ARGMAX: begin
					if (argmax_iteration_done) begin
						state <= DONE;
					end else begin
						state <= ARGMAX;
					end
				end
				DONE: begin
					state <= IDLE;
				end
				default: begin
					state <= IDLE;
				end
			endcase
		end
	end

	
	reg enable_first_layer, enable_second_layer, enable_argmax;
	reg rst_argmax, rst_first_layer, rst_second_layer;
	
	always @(*) begin
		case (state)
			IDLE: begin
				enable_first_layer = 1'b0;
				enable_argmax = 1'b0;
				enable_second_layer = 1'b0;
				rst_first_layer = 1'b1;
				rst_second_layer = 1'b1;
			end
			FIRST_LAYER: begin
				done = 1'b0;
				rst_first_layer = 1'b0;
				enable_first_layer = 1'b1;
				rst_argmax = 1'b1;
			end
			SECOND_LAYER: begin
				rst_argmax = 1'b0;
				rst_second_layer = 1'b0;
				enable_first_layer = 1'b0;
				enable_second_layer = 1'b1;
			end
			ARGMAX: begin
				enable_second_layer = 1'b0;
				enable_argmax = 1'b1;
			end
			DONE: begin
				enable_argmax = 1'b0;
				done = 1'b1;
			end
			
		endcase
	end
	
	
	wire rst_fr_layer, rst_sd_layer, rst_agm;
	
	assign rst_fr_layer = rst_first_layer | rst;
	assign rst_sd_layer = rst_second_layer | rst;
	assign rst_agm = rst_argmax | rst;
	
	
	first_layer fr_layer(
		.enable(enable_first_layer),
		.clk(clk),
		.rst(rst),
		.is_avaliable_pixel(is_available_pixel),
		.req_pixel(req_pixel),
		.addr_pixel(addr_mem_pixel),
		.data_in_pixel(data_in_pixel),
		.is_avaliable_win(is_available_win),
		.req_win(req_win),
		.addr_win(addr_mem_win),
		.data_in_win(data_in_win),
		.is_avaliable_bias(is_available_bias),
		.req_bias(req_bias),
		.addr_bias(addr_mem_bias),
		.data_in_bias(data_in_bias),
		.iteration_counter(first_layer_iteration_counter),
		.done(first_layer_iteration_done),
		.data_to_raw_in_register(data_out_first_layer),
		.addr_to_raw_in_register(addr_register_write_first_layer),
		.enable_register_write(enable_register_write_first_layer),
	);
	
	reg_bank128 reg_first_layer(
        .addr_r(addr_register_read_second_layer),
        .addr_w(addr_register_write_first_layer),
        .data_in(data_out_first_layer),
        .data_out(data_out_from_register_to_second_layer),
        .wr_en(enable_register_write_first_layer),
        .clk(clk)
    );
	 
	 second_layer sd_layer(
		.addr_beta(addr_mem_beta),
		.addr_register(addr_register_read_second_layer),
		.data_in_beta(data_in_beta),
		.data_in_register(data_out_from_register_to_second_layer),
		.addr_register_raw(addr_register_write_second_layer),
		.data_register_raw(data_out_second_layer),
		.enable_register_write(enable_register_write_second_layer),
		.done(second_layer_iteration_done),
		.iteration_counter(second_layer_iteration_counter),
		.clk(clk),
		.enable(enable_second_layer),
		.rst(rst),
		.req_beta(req_beta),
		.is_avaliable_beta(is_available_beta)
	);
	
	reg_bank10 reg_second_layer(
        .addr_r(addr_register_read_argmax),
        .addr_w(addr_register_write_second_layer),
        .data_in(data_out_second_layer),
        .data_out(data_out_from_register_to_argmax),
        .wr_en(enable_register_write_second_layer),
        .clk(clk)
    );
	 
	 argmax_iterativo agm (
        .clk(clk),
        .rst(rst), 
        .enable(enable_argmax), 
        .addr_r(addr_register_read_argmax), 
        .data_in(data_out_from_register_to_argmax),
        .predicted_digit(output_digit), 
        .done(argmax_iteration_done)
    );
	
		
endmodule