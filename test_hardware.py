#!/usr/bin/env python3
import argparse
import re
import numpy as np

def ler_mif_imagem(caminho_mif, num_pixels=784):
    """Lê o arquivo .mif e extrai os pixels de 0 a 255."""
    pixels = np.zeros(num_pixels, dtype=np.int64)
    try:
        with open(caminho_mif, 'r') as f:
            conteudo = f.read()
    except FileNotFoundError:
        print(f"Erro: Arquivo {caminho_mif} não encontrado.")
        return None

    match = re.search(r'CONTENT\s+BEGIN(.*?)END;', conteudo, re.DOTALL | re.IGNORECASE)
    if match:
        linhas = match.group(1).strip().split('\n')
        for linha in linhas:
            if ':' in linha:
                partes = linha.split(':')
                end = int(partes[0].strip())
                val_hex = partes[1].strip().replace(';', '')
                pixels[end] = int(val_hex, 16)
    return pixels

def hardware_tanh_pwl(x_q412):
    """Réplica exata do módulo Verilog tanh_pwl_q4_12"""
    abs_x = abs(x_q412)
    if abs_x < 2048:
        abs_y = abs_x
    elif abs_x < 5120:
        abs_y = (abs_x >> 1) + 1024
    elif abs_x < 9216:
        abs_y = (abs_x >> 3) + 2944
    else:
        abs_y = 4096
    return -abs_y if x_q412 < 0 else abs_y

def formatar_como_display(valor_q412):
    """
    Réplica BIT-A-BIT do módulo 'conversor_q4_12_display' em Verilog.
    Simula perfeitamente fios de 16 bits e Complemento de 2.
    """
    # Força o número para o mundo de 16 bits
    val_16 = valor_q412 & 0xFFFF

    # 1. Extraindo Sinal (Bit 15)
    sign = (val_16 >> 15) & 1

    # Extraindo Valor Absoluto (Igual ao 'sign ? (-q4_12_in) : q4_12_in')
    if sign == 1:
        abs_val = ((~val_16) + 1) & 0xFFFF # Complemento de 2
        sinal_str = '-'
    else:
        abs_val = val_16
        sinal_str = ' '

    # 2. Separando Inteiro e Fracionário
    # {1'b0, abs_val[14:12]}
    int_part = (abs_val >> 12) & 0x07
    # abs_val[11:0]
    frac_part = abs_val & 0x0FFF

    # 3. Extraindo as casas decimais (O truque de x10)
    calc1 = frac_part * 10
    digito1 = (calc1 >> 12) & 0x0F
    resto1 = calc1 & 0x0FFF

    calc2 = resto1 * 10
    digito2 = (calc2 >> 12) & 0x0F
    resto2 = calc2 & 0x0FFF

    calc3 = resto2 * 10
    digito3 = (calc3 >> 12) & 0x0F
    resto3 = calc3 & 0x0FFF

    calc4 = resto3 * 10
    digito4 = (calc4 >> 12) & 0x0F

    return f"{sinal_str}{int_part}.{digito1}{digito2}{digito3}{digito4}"

def to_hex_16(valor_int):
    """Converte para Hexadecimal de 16 bits"""
    val_clip = max(min(valor_int, 32767), -32768)
    return format(val_clip & 0xFFFF, '04X')

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mif", type=str, help="Caminho para o arquivo .mif da imagem")
    ap.add_argument("modelo", type=str, help="Caminho para o model_elm_q.npz")
    args = ap.parse_args()

    # 1. Carrega Imagem e Modelo
    pixels = ler_mif_imagem(args.mif)
    if pixels is None: return

    m = np.load(args.modelo, allow_pickle=True)
    W_in_q = m["W_in_q"].astype(np.int64)
    b_q    = m["b_q"].astype(np.int64)
    beta_q = m["beta_q"].astype(np.int64) # Pesos camada 2 (128x10)

    num_neuronios = W_in_q.shape[0] # 128
    num_classes = beta_q.shape[1]   # 10

    # 2. Simula a Primeira Camada (Gera H_hw)
    H_hw = np.zeros(num_neuronios, dtype=np.int64)
    for i in range(num_neuronios):
        acc = 0
        for p in range(784):
            pixel_q412 = pixels[p] << 4
            # Deslocamento aritmético para manter a escala
            mult = (W_in_q[i, p] * pixel_q412) >> 12
            acc += mult
        acc += b_q[i]

        # Saturação de 32 para 16 bits (Igual ao seu MAC agora)
        acc_sat = max(min(acc, 32767), -32768)
        H_hw[i] = hardware_tanh_pwl(acc_sat)

    # 3. Simula a Segunda Camada (Gera a saída Y)
    Y_hw = np.zeros(num_classes, dtype=np.int64)

    for c in range(num_classes): # De 0 a 9
        acc = 0
        for i in range(num_neuronios):
            mult = (H_hw[i] * beta_q[i, c]) >> 12
            acc += mult

        # Saturação final
        Y_hw[c] = max(min(acc, 32767), -32768)

    # 4. Exibe os Resultados
    print("\n" + "="*55)
    print(" 🎯 GABARITO DA SEGUNDA CAMADA (SAÍDA FINAL) ")
    print("="*55)
    print(" Verifique os 10 registradores finais da rede ")
    print("-" * 55)
    print("Classe (Dígito) |   Hexadecimal   |  Visor 7 Segmentos")
    print("-" * 55)

    for c in range(num_classes):
        hex_val = to_hex_16(Y_hw[c])
        display_str = formatar_como_display(Y_hw[c])
        print(f"       {c}        |      0x{hex_val}     |      {display_str}")

    print("="*55)

    # Encontra o vencedor
    predicao = np.argmax(Y_hw)
    print(f"\n >>> A REDE DEVE PREVER O DÍGITO: [ {predicao} ] <<<\n")

if __name__ == "__main__":
    main()
