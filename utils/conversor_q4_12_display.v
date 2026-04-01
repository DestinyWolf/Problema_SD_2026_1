// ============================================================================
// Módulo Principal: Converte Q4.12 para 6 Displays de 7 Segmentos
// ============================================================================
module conversor_q4_12_display (
    input wire signed [15:0] q4_12_in,
    
    output wire [6:0] HEX5, // Sinal
    output wire [6:0] HEX4, // Inteiro
    output wire [6:0] HEX3, // Decimal 1
    output wire [6:0] HEX2, // Decimal 2
    output wire [6:0] HEX1, // Decimal 3
    output wire [6:0] HEX0  // Decimal 4
);

    // 1. Extraindo o Valor Absoluto (Módulo) e o Sinal
    wire sign = q4_12_in[15];
    wire [15:0] abs_val = sign ? (-q4_12_in) : q4_12_in;
    
    // 2. Separando Inteiro e Fracionário
    // Bits [14:12] são a parte inteira (0 a 7/8)
    wire [3:0] int_part = {1'b0, abs_val[14:12]}; 
    // Bits [11:0] são a parte fracionária (0 a 4095)
    wire [11:0] frac_part = abs_val[11:0];

    // 3. O Truque Mágico de Hardware para extrair casas decimais
    // Multiplicamos por 10. Os 4 bits superiores do resultado são o dígito!
    // Usamos 16 bits para a conta: 12 do fracionário + 4 de sobra pro dígito.
    
    // Dígito 1 (Décimos)
    wire [15:0] calc1 = {4'd0, frac_part} * 10;
    wire [3:0] digito_dec1 = calc1[15:12];
    wire [11:0] resto1     = calc1[11:0];
    
    // Dígito 2 (Centésimos)
    wire [15:0] calc2 = {4'd0, resto1} * 10;
    wire [3:0] digito_dec2 = calc2[15:12];
    wire [11:0] resto2     = calc2[11:0];
    
    // Dígito 3 (Milésimos)
    wire [15:0] calc3 = {4'd0, resto2} * 10;
    wire [3:0] digito_dec3 = calc3[15:12];
    wire [11:0] resto3     = calc3[11:0];
    
    // Dígito 4 (Décimos de Milésimos)
    wire [15:0] calc4 = {4'd0, resto3} * 10;
    wire [3:0] digito_dec4 = calc4[15:12];

    // 4. Instanciando os Decodificadores de 7 Segmentos
    
    // Display 5: Sinal (Exibe o traço central se negativo, apaga se positivo)
    assign HEX5 = sign ? 7'b0111111 : 7'b1111111; 
    
    // Display 4: Parte Inteira
    decodificador_7seg dec_int  (.bin(int_part),    .seg(HEX4));
    
    // Displays 3 a 0: Casas Decimais
    decodificador_7seg dec_frac1(.bin(digito_dec1), .seg(HEX3));
    decodificador_7seg dec_frac2(.bin(digito_dec2), .seg(HEX2));
    decodificador_7seg dec_frac3(.bin(digito_dec3), .seg(HEX1));
    decodificador_7seg dec_frac4(.bin(digito_dec4), .seg(HEX0));

endmodule


// ============================================================================
// Submódulo Auxiliar: Decodificador Binário para 7 Segmentos (Ativo em Baixa)
// ============================================================================
module decodificador_7seg (
    input wire [3:0] bin,
    output reg [6:0] seg
);
    // Mapeamento padrão para displays ânodo comum (0 acende, 1 apaga)
    always @(*) begin
        case(bin)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // Apagado se for inválido
        endcase
    end
endmodule