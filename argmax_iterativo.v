module argmax_iterativo (
    input wire clk,
    input wire rst,
    input wire enable,
    
    output wire [3:0] addr_r,
    input wire signed [15:0] data_in, 
    
    output reg [3:0] predicted_digit, 
    output reg done                   
);

    reg [3:0] counter;
    reg signed [15:0] max_score;
    reg [3:0] best_digit;
    
    // Máquina de estados simples para o Argmax
    reg [1:0] state;
    localparam IDLE = 2'd0;
    localparam REQUEST_DATA = 2'd1;
    localparam EVALUATE = 2'd2;

    // O endereço sempre reflete o contador atual
    assign addr_r = counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 4'd0;
            max_score <= -16'sd32768; // Menor valor possível em Q4.12
            best_digit <= 4'd0;
            predicted_digit <= 4'd0;
            done <= 1'b0;
            state <= IDLE;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    counter <= 4'd0;
                    max_score <= -16'sd32768;
                    state <= REQUEST_DATA; // Vai pro estado pedir o dado 0
                end
                
                REQUEST_DATA: begin
                    // O endereço 'counter' já está em addr_r.
                    // Apenas esperamos 1 clock para o banco de registradores responder
                    state <= EVALUATE;
                end
                
                EVALUATE: begin
                    // 1. O dado do 'counter' atual FINALMENTE chegou e é estável.
                    if (data_in > max_score) begin
                        max_score <= data_in;
                        best_digit <= counter;
                    end
                    
                    // 2. Lógica de repetição e fim
                    if (counter == 4'd9) begin
                        // Chegamos no final. Atualiza a saída final.
                        if (data_in > max_score) begin
                            predicted_digit <= counter;
                        end else begin
                            predicted_digit <= best_digit;
                        end
                        
                        done <= 1'b1; // Sinaliza que acabou
                        state <= IDLE; // Reseta para próxima varredura
                        
                    end else begin
                        // Prepara o próximo endereço
                        counter <= counter + 4'd1;
                        state <= REQUEST_DATA; // Volta para esperar 1 clock da memória
                    end
                end
            endcase
            
        end else begin
            // Se desabilitado, dorme
            done <= 1'b0;
            counter <= 4'd0;
            state <= IDLE;
        end
    end

endmodule