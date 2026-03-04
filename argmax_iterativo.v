module argmax_iterativo (
    input wire clk,
    input wire rst,
    input wire enable,          // Se mantido em 1, roda indefinidamente (loop 0 a 9)
    
    // Conexão direta com a porta de LEITURA do reg_bank10
    output wire [3:0] addr_r,
    input wire signed [15:0] data_in, // A nota Q4.12 lida do banco
    
    // Saídas
    output reg [3:0] predicted_digit, // O vencedor final
    output reg done                   // Pulsa em 1 quando termina uma varredura completa
);

    reg [3:0] counter;
    reg signed [15:0] max_score;
    reg [3:0] best_digit;

    // O endereço de leitura do banco é sempre o valor do nosso contador
    // Como a leitura do reg_bank10 é assíncrona, o dado chega instantaneamente!
    assign addr_r = counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 4'd0;
            max_score <= 16'h8000; // -32768 (O menor número possível em 16 bits)
            best_digit <= 4'd0;
            predicted_digit <= 4'd0;
            done <= 1'b0;
            
        end else if (enable) begin
            
            // 1. COMPARAÇÃO
            // O dado do 'counter' atual já está disponível no fio 'data_in'
            if (data_in > max_score) begin
                max_score <= data_in;
                best_digit <= counter;
            end
            
            // 2. LÓGICA DE REPETIÇÃO INDEFINIDA
            if (counter == 4'd9) begin
                // Chegou no último dígito! Terminou uma varredura (0 a 9)
                done <= 1'b1;
                
                // Atualiza a saída final. Precisamos de um 'if' extra aqui porque 
                // se o maior número for o dígito 9, ele acabou de bater o recorde agora.
                if (data_in > max_score) begin
                    predicted_digit <= counter;
                end else begin
                    predicted_digit <= best_digit;
                end
                
                // RESET INTERNO: Prepara o terreno para repetir a varredura no próximo clock
                counter <= 4'd0;
                max_score <= 16'h8000; 
                // Não precisamos resetar o best_digit, ele será sobrescrito naturalmente
                
            end else begin
                // Continua contando normalmente
                done <= 1'b0;
                counter <= counter + 1'b1;
            end
            
        end else begin
            // Se o enable for desligado, o Argmax volta a dormir e zera o processo
            done <= 1'b0;
            counter <= 4'd0;
            max_score <= 16'h8000;
        end
    end

endmodule