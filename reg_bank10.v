module reg_bank10 (
    input wire clk,
    input wire wr_en,                     // Sinal de Habilitação de Escrita
    
    input wire [3:0] addr_w,              // Endereço de escrita (0 a 9)
    input wire signed [15:0] data_in,     // Dado a ser salvo (Formato Q4.12)
    
    input wire [3:0] addr_r,              // Endereço de leitura (0 a 9)
    output reg signed [15:0] data_out    // Dado lido
);

    // Declaração da matriz de 10 registradores de 16 bits
    reg signed [15:0] memoria [0:9];

    // Escrita Síncrona
    always @(posedge clk) begin
        if (wr_en) begin
				 memoria[addr_w] <= data_in;
         
        end
		  data_out = memoria[addr_r];
    end

    // Leitura Assíncrona
    // Se tentarem ler um endereço inválido (como 10 a 15), retorna 0 para evitar lixo de memória
     

endmodule