# Spring-Weight-Simulator
Trabalho final de Física Experimental - Eletromagnetismo.

Equipe: Gabriel Alves, João Francisco, Rafael Adolfo e Victor Ramos

Essa aplicação em formato de jogo na linguagem de computação Lua tem como objetivo simular um ambiente virtual para a realização do experimento de Cálculo da Força Elástica em um sistema Massa-Mola com a aplicação da Lei de Hooke. Para executar esse simulador é necessário fazer o download da pasta desse repositório, instalar o Love2D e a Lua na máquina. A atual versão do código possui limitações gráficas de execução, nas simulações de molas em paralelo e molas em série, que serão posteriormente corrigidas para melhor funcionamento e visualização do sistema. O funcionamento interno dos cálculos matemáticos para aplicação da Lei de Hooke não funciona perfeitamente. Depois de todas as instalações feitas, abra a pasta do repositório no Visual Studio Code, crie um arquivo `settings.json` em uma pasta .vscode, e insira o caminho de onde foi instalado o Love na máquina. Após isso, vá até o arquivo `main.lua` e aperte o comando Alt-L para execução do código. Utilize um mouse para navegar no jogo, para conseguir utilizar o sistema interativo de movimentação e posicionamento de caixas e molas.

# Documentação do Código `main.lua`

## 1. Visão Geral
O código implementa uma simulação física interativa utilizando o framework Love2D. O objetivo principal é simular o comportamento de molas, massas e forças elásticas, com funcionalidades para criar, conectar e excluir molas e caixas.

Principais recursos:
- Criação dinâmica de molas e caixas.
- Conexão de molas ao teto, caixas e entre si.
- Cálculo de forças elásticas e constantes equivalentes.
- Interface gráfica com botões e campos de entrada.

## 2. Estrutura do Código

### Bibliotecas Utilizadas
- `lume`: Utilizada para manipulação de tabelas e outras utilidades.
- `suit`: Biblioteca para a interface gráfica (botões, campos de entrada, etc.).

### Variáveis Globais Principais
- `world`: Mundo físico simulado.
- `boxes`: Lista de caixas criadas.
- `springs`: Lista de molas criadas.
- `ceilingSnapOccupancy`: Controle de pontos de conexão no teto.
- `inputWidth`, `inputHeight`, `inputMass`, `inputSpringK`: Inputs para entrada de parâmetros pelo usuário.

### Áreas da Interface
- `simAreaWidth`: Área para simulação.
- `uiAreaWidth`: Área para interface de usuário.

## 3. Fluxo de Execução

1. **Inicialização (`love.load`)**
   - Configura a janela.
   - Cria o mundo físico com gravidade.
   - Cria o chão e o teto.

2. **Atualização (`love.update`)**
   - Atualiza o mundo físico.
   - Gerencia interações com a interface gráfica.
   - Recalcula forças das molas.

3. **Desenho (`love.draw`)**
   - Desenha o chão, teto, molas, caixas e interface gráfica.

4. **Entrada de Dados (`love.mousepressed`, `love.mousereleased`)**
   - Gerencia cliques para selecionar e conectar molas.

## 4. Funções Principais

### `createbox(width, height, mass)`
Cria uma caixa dinâmica no mundo com as dimensões e massa especificadas.

### `createSpring(kValue)`
Cria uma mola com constante elástica especificada.

### `deleteAllSprings()`
Exclui todas as molas da simulação.

### `calculateSpringForce(spring)`
Calcula a força elástica da mola com base na massa conectada.

### `attachSpringToBox(spring, box)`
Conecta a extremidade inferior de uma mola a uma caixa.

### `attachSpringToSpring(spring, otherSpring)`
Conecta a extremidade inferior de uma mola à extremidade superior de outra.

### `getNearestCeilingSnappingPoint(mouseX, mouseY)`
Encontra o ponto de conexão mais próximo no teto.

### `destroybox(boxID)`
Remove a caixa especificada e desconecta quaisquer molas associadas.

## 5. Interface Gráfica

A interface gráfica (SUIT) oferece os seguintes controles:
- **Criar Caixa**: Insere uma nova caixa com as dimensões e massa fornecidas.
- **Criar Mola**: Insere uma nova mola com a constante elástica fornecida.
- **Excluir molas**: Remove todas as molas.
- **Excluir Caixa**: Remove a primeira caixa da lista.

## 6. Interações e Conexões

- Clique esquerdo: Seleciona molas e caixas.
- Clique direito: Conecta extremidades de molas ao teto, caixas ou outras molas.

## 7. Cálculo de Forças

As forças elásticas são calculadas usando a fórmula:

\[ F = k \times \Delta x \]

Onde:
- `k` = constante elástica da mola.
- `Δx` = deformação da mola em metros.

### Casos Especiais
- **Molas em paralelo**: Soma das constantes elásticas.
- **Molas em série**: Inverso da soma dos inversos das constantes.

## 8. Dicas de Uso

1. Inicie criando uma caixa e uma mola.
2. Arraste a mola até o teto e, em seguida, conecte à caixa.
3. Utilize o botão "Excluir molas" para reiniciar a simulação.
4. Observe as informações exibidas na interface lateral direita.

## 9. Possíveis Melhorias Futuras

- Adicionar persistência dos dados.
- Melhorar a estabilidade das conexões.
- Otimizar o cálculo das forças para grandes números de molas.
- Permitir que o usuário faça mais de um tipo de simulação ao mesmo tempo.

