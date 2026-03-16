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
    """Réplica exata do módulo Verilog tanh_pwl_q4_12 (Versão Suave v2)"""
    abs_x = abs(x_q412)

    if abs_x < 2048:
        abs_y = abs_x
    elif abs_x < 5120:
        abs_y = (abs_x >> 1) + 1024
    elif abs_x < 9216:
        abs_y = (abs_x >> 3) + 2944
    else:
        abs_y = 4096

    y = -abs_y if x_q412 < 0 else abs_y
    return y

def formatar_como_display(valor_q412):
    """
    Réplica exata da lógica do 'conversor_q4_12_display' do Verilog.
    Retorna uma string visualmente idêntica ao que aparecerá nos 6 Displays.
    """
    # 1. Extraindo o Valor Absoluto e o Sinal
    sinal = '-' if valor_q412 < 0 else ' '
    abs_val = abs(valor_q412)

    # 2. Separando Inteiro e Fracionário
    # Bits [14:12] = (abs_val >> 12) & 0x07
    int_part = (abs_val >> 12) & 7
    # Bits [11:0] = abs_val & 0x0FFF
    frac_part = abs_val & 4095

    # 3. Extraindo as casas decimais (O mesmo truque do hardware)
    calc1 = frac_part * 10
    digito1 = (calc1 >> 12) & 15
    resto1 = calc1 & 4095

    calc2 = resto1 * 10
    digito2 = (calc2 >> 12) & 15
    resto2 = calc2 & 4095

    calc3 = resto2 * 10
    digito3 = (calc3 >> 12) & 15
    resto3 = calc3 & 4095

    calc4 = resto3 * 10
    digito4 = (calc4 >> 12) & 15

    # Retorna formatado: [Sinal][Inteiro].[D1][D2][D3][D4]
    return f"{sinal}{int_part}.{digito1}{digito2}{digito3}{digito4}"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mif", type=str, help="Caminho para o arquivo .mif da imagem")
    ap.add_argument("modelo", type=str, help="Caminho para o model_elm_q.npz")
    args = ap.parse_args()

    # 1. Carrega Imagem do MIF
    pixels = ler_mif_imagem(args.mif)
    if pixels is None: return

    # 2. Carrega Modelo Quantizado
    m = np.load(args.modelo, allow_pickle=True)
    W_in_q = m["W_in_q"].astype(np.int64)
    b_q    = m["b_q"].astype(np.int64)

    num_neuronios = W_in_q.shape[0] # Deve ser 128 com base no seu projeto

    # 3. Simula a Matemática do Hardware
    H_hw = np.zeros(num_neuronios, dtype=np.int64)

    for i in range(num_neuronios):
        acc = 0
        for p in range(784):
            pixel_q412 = pixels[p] << 4
            mult = (W_in_q[i, p] * pixel_q412) >> 12
            acc += mult

        acc += b_q[i]
        H_hw[i] = hardware_tanh_pwl(acc)

    # 4. Exibe os resultados
    print("\n" + "="*55)
    print(" 🛠️ GABARITO DA PRIMEIRA CAMADA (PÓS-ATIVAÇÃO) ")
    print("="*55)
    print(" Verifique os endereços no botão/chave da sua placa ")
    print("-" * 55)
    print("Endereço (Dec) | Endereço (Hex) |  Visor de 7 Segmentos")
    print("-" * 55)

    for addr in range(num_neuronios):
        hex_addr = format(addr, '02X')
        # Aplica a função para formatar igual aos 6 displays
        display_str = formatar_como_display(H_hw[addr])
        print(f"      {addr:03d}      |      0x{hex_addr}      |      {display_str}")

    print("="*55)

if __name__ == "__main__":
    main()
