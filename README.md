# CoProcessador para o segundo problema do PBL de Sistema Digitais

<div align="center">
<h1>

[Estrutura Implementada](#estrutura-implementada) | [ISA](#conjunto-de-instruções-isa) | [Barramentos](#barramentos)

</h1>
</div>

## Estrutura Implementada

<details>
<sumary><h2>Estrutura Implementada</h2></sumary>

O Processador implementado possui tres modulos principais:

- [Unidade de Controle](#unidade-de-controle)
- [Unidade de Inferencia](#unidade-de-inferencia)
- [Load/Store Unit](#load-store-unit)

<div align="center">
  <figure>
    <img src="Docs/Diagrama-Arquitetura.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 1</b> - Estrutura Do Coprocessador implementado
      </p>
    </figcaption>
  </figure>
</div>


Cada uma dessas unidade possui responsabilidade e barramentos de entradas e saidas bem definidas. A seguir abordaremos um pouco de cada modulo.

### Unidade de Controle

<details>
<sumary><h3>Unidade de Controle</h3></sumary>

O modulo da unidade de controle se conecta a todo coprocessador e fica responsavel por receber as instruções e sinais de controle externo bem como retornar as flags de controle e o resultado das operações. A entrada de dados e instruções no coprocessador é feita atraves do barramento `Data In` e a saida de dados é feita atraves do barramento `Data Out`, esses barramentos serão detalhados na seção de [Barramentos](#barramentos).

Dentro do modulo da unidade de controle é realizada a decodificação da instrução, a depender da instrução o processador pode ir para um estado de memoria ou um estado de inferencia.
Os tipos de instrução serão abordados na seção [Conjunto de Instruções (ISA)](#conjunto-de-instruções-isa). Durante a execução de uma instrução nenhuma outra podera ser executada, sendo assim, é necessaria aguardar o termino de uma instrução para que seja possivel enviar outra.

> [!WARNING]
> Caso uma instrução seja enviada enquanto o coprocessador está executando outra, a flag de erro poderá ser ativada.

Ao fim da execução da instrução o coprocessador retornara ao estado `IDLE` permitindo assim a leitura de uma nova instrução.
</details>

### Unidade de Inferencia

<details>
<sumary><h3>Unidade de Inferencia</h3></sumary>

A unidade de inferencia é o modulo responsanvel por abrigar os **MACs** e os bancos de registradores utilizados durante o processo de calculo. Este modulo pode ser divido em cinco submodulos

submodulo | descricao
:---: | :---
Primeira Camada | Modulo responsavel por realizar os calculos contidos na camada oculta do ELM
Banco de 128 Registradores | Banco de registradores responsavel por armazenar o resultado dos neuronios da camada oculta
Segunda Camada | Modulo responsavel por realizar os calculos contidos na camada de saida
Banco de 10 Registradores | Modulo responsavel por armazenar o resultado dos neuronios da camada de saida
Argmax Iterativo | Modulo comparador que busca a posição do registrador que contem o resultado de maior valor da camada de saida
Unidade de controle de Inferencia | Modulo responsavel por organizar o execução de modo que cada etapa da ELM seja executada corretamente.

#### Primeira Camada

<details>
<sumary><h5>Primeira Camada</h5></sumary>

A primeira camada abriga 4 acumuladores, registradores de dados e a função de ativação.
Para completar o calculo de todos os neuronios da primeira camada é necessario 32 passos

> [!NOTE]
> Entenda como passo, todo o processo de calculo dos neuronios contidos nessa camada, neste caso 4

Cada passo necessita individualmente de 18844 ciclos de clock para ser executado totalmente.

A geração dos endereçamentos de leitura das memorias é feito dentro da primeira camada, assim como a geração do endereçamento de escrita no banco de registradores.
Alem da função de ativação e dos acumuladores, a primeira camada conta com duas maquinas de estado responsaveis por gerenciar o fluxo de execução dos passos e emitir as flags de termino, solicitação de dado e demais handshakes de controle para evitar a leitura incorreta de dados.

> [!NOTE]
> A função de ativação implementada foi a Tangente Hiperbolica, para sua implementação foi utilizada a tecnica de aproximação linear por partes.

</details>

#### Banco de registradores

<details>
<sumary><h5>Banco de Registradores</h5></sumary>

Modulo que armazena um conjunto de registradores organizados em colunas onde é possivel realizar operações de leitura e escrita.

</details>

#### Segunda Camada

<details>
<sumary><h5>Segunda Camada</h5></sumary>

A segunda camada, assim como a primeira armazena seus acumuladores, registradores de dados e suas FMS(Maquinas de Estado Finito, Finite Machine State).
Possui 5 neuronios e necessita de apenas 2 passos para realizar o calculo de todos da camada de saida. Faz o gerenciamento dos endereçamentos de leitura das memorias e ogerenciamento dos endereçamentos de escrita no banco de registradores. Para essa organização conta com duas FMS semelhantes a da primeira camada.

> [!WARNING]
> A Camada de saida não possui função de ativação, sabendo disto, o modulo da segunda camada não implementa nenhum modulo para calculo de uma possivel função de ativação.

</details>

#### Argmax Iterativo

<details>
<sumary><h5>Argmax Iterativo</h5></sumary>

O argmax iterativo é um modulo comparador sequencial que faz a leitura do banco com 10 registradores e busca o registrador de maior valor, ao encontrar, armazena a posição daquele registrador e coloca em sua saida o valor armazenado.


</details>

</details>

### Load/Store Unit

<details>
<sumary><h3>Load/Store Unit</h3></sumary>

Este modulo é responsavel por gerenciar as operações de leitura e escrita de memoria. Se trata de um modulo de memoria generico que implementa a criação dinamica de memorias **RAM** de duas portas com base na familia do dispositivo e do tipo de memoria a ser utilizado.

Na implementação foram necessarias 4 instancias do modulo Load/Store.

Nome | Descrição
:---: | :---
mem_img | Instancia do LSU responsavel por armazenar 784 valores de 8 bits correspondente aos pixeis da imagem
mem_win | Instrancia do LSU responsavel por armazenar 100352 valores de 16 bits correspondentes aos pesos da camada oculta
mem_bias | Instancia do LSU responsavel por armazenar 128 valores de 16 bits correspondentes aos bias da camada oculta
mem_beta | Instancia do LSU responsavel por armazenar 1280 valores de 16 bits correspondentes aos valores de beta da camada de saida

Cada instancia de memoria implementada possui largura e profundidade distintas.

> [!WARNING]
> Antes de realizar a operação de leitura ou escrita em uma das memorias verificar o numero de endereços validos, caso seja enviado um dado para um endereço não valido a flag de erro será ativada.

</details>
</details>

## Conjunto de Instruções (ISA)

<details>
<sumary><h2>Conjunto de Instruções (ISA)</h2></sumary>

O coprocessador implementado possui um pequeno conjunto de seis instruções, sendo cinco delas de [memoria](#instruções-de-memória) e uma instrução de [controle](#instruções-de-controle).

Instrução | OP Code | Função
:---: | :---: | :-----
[**Store Image**](#store-image) | 000 | Responsavel por armazenar um pixel da imagem na memoria
[**Store Weights Addr**](#store-weights-addr) | 001 | Responsavel por guardar o endereço a ser amarmazenad o peso que sera enviado pela instrução `Store Weights Value`
[**Store Weights Value**](#store-weights-value) | 010 | Responsavel por armazenar um o peso na memoria
[**Store Bias**](#store-bias) | 011 | Responsavel por armazenar um bias na memoria
[**Store Beta**](#store-beta) | 100 | Responsavel por armazenar um valor de beta na memoria
[**Start**](#start) | 101 | Responsavel por iniciar o processo de inferencia a partir dos dados contidos nas memorias
**Status** | 110 | Instrução não utilizada pois tanto o resultado quanto as flags estão sendo atualizadas diretamente no barramento sem a necessidade de solicitação
**NOP** | 111 | Não executa nenhuma operação, utilizada para a inserção de bolhas em arquiteturas que implementam pipeline.

### Instruções de Memória

<details>
<sumary><h4>Instruções de Memória</h4></sumary>

As instruções de memoria levam em media cinco ciclos de clock para serem concluidas e ativam a flag de busy enquanto estão sendo executadas e a flag de done ao serem concluidas

#### Store Image

<details>
<sumary><h5>Store Image</h5></sumary>

Campos da instrução

<div align="center">
  <figure>
    <img src="Docs/diagrama-inst-img.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 2</b> - Formato da instrução Store Image
      </p>
    </figcaption>
  </figure>
</div>

Descrição dos campos

Campo | Tamanho | Descrição
:---: | :---: | :---
OP Code | 3 | Código da Instrução
Endereçamento | 10 | Endereço da memoria que o dado será armazenado
Dado | 8 | Valor do pixel a ser armazenado na memoria

</details>

#### Store Weights Addr

<details>
<sumary><h5>Store Weights Addr</h5></sumary>

Campos da instrução

<div align="center">
  <figure>
    <img src="Docs/diagrama-inst-addr.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 3</b> - Formato da instrução Store Weights Addr
      </p>
    </figcaption>
  </figure>
</div>

Descrição dos campos

Campo | Tamanho | Descrição
:---: | :---: | :---
OP Code | 3 | Codigo da Instrução
Endereçamento | 17 | Endereço de memoria onde será armazenado o peso a ser enviado

> [!WARNING]
> Essa instrução não ativa a flag de done e por se tratar do armazenamento de um valor em um registrador não necessita de espera.

> [!NOTE]
> Essa instrução é uma exceção as instruções de memoria, sua execução leva, geralmente, 2 ciclos.

</details>

#### Store Weights Value

<details>
<sumary><h5>Store Weights Value</h5></sumary>

Campos da instrução

<div align="center">
  <figure>
    <img src="Docs/diagrama-inst-value.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 4</b> - Formato da instrução Store Weights Value
      </p>
    </figcaption>
  </figure>
</div>

Descrição dos campos

Campo | Tamanho | Descrição
:---: | :---: | :---
OP Code | 3 | Código da Instrução
Dado | 16 | Valor a ser armazenado na memoria

</details>

#### Store Bias

<details>
<sumary><h5>Store Bias</h5></sumary>

Campos da instrução

<div align="center">
  <figure>
    <img src="Docs/diagrama-inst-bias.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 5</b> - Formato da instrução Store Bias
      </p>
    </figcaption>
  </figure>
</div>

Descrição dos campos

Campo | Tamanho | Descrição
:---: | :---: | :---
OP Code | 3 | Codigo da instrução
Endereçamento | 7 | Endereço de memoria onde será armazenado o dado
Dado | 16 | Valor a ser armazenado na memoria

</details>

#### Store Beta

<details>
<sumary><h5>Store Beta</h5></sumary>

Campos da instrução

<div align="center">
  <figure>
    <img src="Docs/diagrama-inst-beta.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 6</b> - Formato da instrução Store Beta
      </p>
    </figcaption>
  </figure>
</div>

Descrição dos campos

Campo | Tamanho | Descrição
:---: | :---: | :---
OP Code | 3 | Código da instrução
Endereçamento | 11 | Endereço de memoria onde será armazenado o dado
Dado | 16 | Valor a ser armazenado na memoria

</details>
</details>

### Instruções de Controle

<details>
<sumary><h4>Instruções de Controle</h4></sumary>

O coprocessador possui uma unica instrução de controle que é a `Start`. O tempo de execução é o tempo de execução da inferencia + 2 ciclos de clock.

> [!NOTE]
> Ao fim da execução da inferencia a flag de done será ativa e o resultado da inferencia será posto no barramento de saida.

#### Start

<details>
<sumary><h5>Start</h5></sumary>

Campos da instrução

<div align="center">
  <figure>
    <img src="Docs/diagrama-inst-start.png" width="600px"/>
    <figcaption>
      <p align="center">
        <b>Figura 7</b> - Formato da instrução Start
      </p>
    </figcaption>
  </figure>
</div>

Descrição dos campos

Campo | Tamanho | Descrição
:---: | :---: | :---
OP Code | 3 | Código da instrução

</details>
</details>
</details>


## Barramentos

<details>
<sumary><h2>Barramentos</h2></sumary>
O coprocessador possui tres barramentos principais, dois de entrada e um de saida.

Barramento | Tamanho | Descrição
:---: | :---: | :---
Data In | 32 | Barramento de dados de entrada
Signals | 3 | Barramento para envio de sinais de controle externos ao coprocessador
Data Out | 32 | Barramento de dados de saida

### Data In

<details>
<sumary><h4>Data In</h4></sumary>

Esse barramento é utilizado unico e exclusivamente para o envio das instruções do coprocessador. Possui 32 bits que deverão ser preenchidos de acordo com a instrução que será executada.

</details>

### Signals

<details>
<sumary><h4>Signals</h4></sumary>

Esse barramento é utilizado para envio de sinais de controle externos para o coprocessador. Possui tres bits, sendo cada bit utilizado para um sinal de controle.

Bit | Nome do Sinal | Utilidade
:---: | :---: | :---
0 | Enable | utilizado para sinalizar que a instrução presente no barramento de entrada deve ser executada.
1 | Clear Operation | Utilizado para limpar resquicios da execução de uma instrução anterior que deu erro alem de desativar a flag de erro permitindo a execução de uma nova instrução. **OBS:** Não apaga dados enviados erroneamente a memoria.
2 | Reset | Usado para resetar os registradores do coprocessador.

</details>

### Data Out

<details>
<sumary><h4>Data Out</h4></sumary>

Barramento de saida de dados do coprocessador, possui largura de 32 bits, entretanto nem todos os bits são utilizados.

- Os 4 primeiros bits representam o numero predizido pela rede neural, o resultado desses bits só é confiavel após a conclusão da operação de inferencia
- O 5 bit é a flag de **Done**, esta flag é ativada sempre que uma operação é concluida e permanece ativada até que uma nova instrução comece a ser executada.
- O 6 bit é a flag de **Busy**, indica que uma operação ainda esta sendo executada pelo coprocessador.
- o 7 bit é a flag de **Error**, indica que a instrução anterior não foi executada corretamente, mesmo que tenha sido concluida o seu resultado não é confiavel.

> [!WARNING]
> Mesmo que uma operação seja concluida, caso o sinal de enable ainda esteja em nivel logico alto, a flag de **Done** não sera acionada até que o sinal retorne ao nivel logico baixo, evitando a execução de instruções erroneamente, ou que execute a mesma instrução novamente.

</details>

##Modulo VGA

<details>
<sumary><h2>Modulo VGA</h2></sumary>

O modulo VGA desenvolvido para ser utilizado durante a terceira fase que está disponivel na pasta *modulo_vga* consegue desenhar até 512 cores em uma grade de 320x240 pixeis
Para sua utilização é necessario apenas a realização de sua instanciação e a correta alocação de pios para o modulo, obedecendo o tamanho de cada barramento e a disposição deles.


</details>
</details>
