# Backend Web com Haskell+Scotty


- Estrutura e conteúdo do README:


3. Processo de desenvolvimento: comentários pessoais sobre o desenvolvimento, com evidências de compreensão, incluindo versões com erros e tentativas de solução
4. Orientações para execução: instalação de dependências, etc.
5. Resultado final: demonstrar execução em GIF animado ou vídeo curto (máximo 60s)
6. Referências e créditos (incluindo alguns prompts, se aplicável)

## 1. Identificação

- Nome: Diógenes Potrich Steca
- Curso: Sistemas de Informação

---

## 2. Tema/objetivo

->Descreva o tema/objetivo do trabalho, conforme a proposta validada.

->Explique qual é a lógica principal do serviço e como o trabalho aplica programação funcional.
    
O objetivo deste trabalho é desenvolver uma aplicação de backend web em Haskell utilizando o framework Scotty, focando na implementação da lógica de um jogo simples no estilo roguelike por turnos. O sistema permite que o jogador execute ações como explorar salas, enfrentar inimigos, utilizar itens e fugir de combates, sendo que cada ação muda o estado do jogo
A lógica principal do trabalho é que o jogo pode ser representado como uma sequencia de transformações de estado. Nesse caso, o estado do jogo é representado por uma estrutura imutável `GameState`, que contem informações core sobre o estado do jogo, tais como: informações sobre o jogador, sobre o inimigo(se tiver) e sobre progressão de salas e andares. A cada ação que o jogador realiza, uma função recebe o estado do jogo e retorna um novo estado atualizado, não modificando os dados existentes.
O trabalho aplica programação funcional pois estrutura toda a lógica atraves de funções puras, como `aplicarAcao`, `resolverTurno` e `aplicarEfeito`,
essas funções são sem efeitos colaterais, ou seja, produzem sempre o mesmo resultado dada uma mesma entrada, o que facilita a previsibilidade e os testes em cima da aplicação
Ainda, é utilizado tipos algebricos, como pra representar diferentes Açoes `Acao` e efeitos de itens `Efeito`, ajudando na escalabilidade do projeto e organização, Também usamos recursos do haskell que congruem com a logica do jogo, um exemplo é o Maybe usado pois a presença de um inimigo no jogo não é garantida todo o tempo
Não obstante, separamos a lógica pura(core) da camada de efeitos(não confundir com os efeitos de itens). Funções que dependem de RNG(por ex, itens e salas), não são tratadas na camada de lógica pura, mas sim em uma camada externa(Scotty). Isso ajuda a alinhar com os principios de programação funcional e a logica se tornar mais "tidy", deterministica. 
Por fim, como proposto e aconselhado pela professora, o trabalho é versionado sendo implementado de forma incremental, iniciando pela implementação do nucleo lógico do jogo e, posteriormente, integrando essa lógica com a API web por meio do framework Scotty. Funcionalidades adicionais que tendem a aumentar a complexidade de forma não-linear serão/foram avaliadas conforme o tempo restante da entrega 
---

## 3. Processo de desenvolvimento

Comente o processo de desenvolvimento do trabalho, com evidências de compreensão e de construção incremental.

Procure incluir, quando aplicável:

- como a ideia inicial evoluiu
- decisões tomadas ao longo do desenvolvimento
- erros encontrados
- dificuldades específicas enfrentadas
- tentativas de solução
- mudanças de rumo
- comentários pessoais sobre o que você compreendeu no processo e sobre questões que ainda persistem
- como você separou a lógica do serviço da parte ligada ao Scotty
- quais funções puras e estruturas de dados foram importantes no trabalho
- quais aspectos de programação funcional apareceram no desenvolvimento

Este não é um espaço para escrever algo como "foi difícil mas superei as dificuldades". O objetivo é mostrar sinais reais de desenvolvimento, reflexão, aprendizado e resolução de problemas.

Se o desenvolvimento não conseguir atingir todos os objetivos e requisitos, essa seção é muito importante para mostrar o que você tentou.

AQUI COMEÇA, adicionar mais coisa conforme surge e depois uma olhada geral pra ver se nao faltou nada:

-> Sobre a ideia inicial : TODO, NO FIM DO PROJETO

->Modelagem do estado com Maybe inimigo
Durante a modelagem inicial do estado do jogo e da lógica principal, esbarrei em um problema que era sobre como representar um inimigo, já que desde a ideia principal era poder ter salas com e sem inimigos, ou seja, o jogador nem sempre tem uma ameaça direta, pra não complicar mais ainda a lógica e, por exemplo, ter que representar quando o jogador esta em combate ou não, ao pesquisar formas de implementar com recursos do haskell, encontrei o tipo `Maybe` que preenche essa lacuna com as duas possibilidades, não tendo com Nothing e tendo com Just inimigo

-> Remoção (Não definitiva) da ação Defender
Partindo da inspiração dos jogos Slay the Spire e Slay the Spire 2, A ação `Defender` era inerente ao desenvolvimento servindo pra mitigar dano recebido por um inimigo em um combate. Porém, ao avançar na implementação, percebi que sua inclusão aumentaria a complexidade do sistema, exigindo um controle mais elaborado de turnos. 
Como a ideia principal é concluir uma versão jogavel funcional, optei por retirar temporariamente do escopo essa ação e focar em outras partes, evitando complexidade desnecessaria nesse estágio do desenvolvimento.
A explicação técnica e uma implementação possível é que o comportamento que eu espero da defesa é que seja temporária, apenas por um turno, desse jeito, a cada inicio de turno, um `TurnManager` resetaria a defesa do Player/Inimigo, e deixaria eles prosseguirem com seus turnos.

-> Seperação do RNG da lógica pura
uma decisão que tomei foi não incluir geração de valores aleatórios juntamente da lógica principal e das funções principais do jogo. Em vez disso, esses valores são recebidos como parametros pelas funções, onde será responsabilidade de uma camada externa(Scotty) de gerar esses valores.
Essa abordagem mantém as funções puras e determínisticas, o que facilita testes, debugging e melhora a compreensão do comportamento do sistema.

-> Dificuldade com where em expressões case
Durante a implementação, acabei por usar `where` dentro de uma expressão `case`, o que resultou em erro de compilação.
Após uma reflexão, com a ajuda do Claude, percebi que o `where` está associado com definições de equações e funções e, portanto, não pode ser usado diretamente com `case`. Pra resolver isso, utilizei a estrutura `let` e `in`, que permite definir variaveis locais dentro de expressões.
Isso contribui pra um maior entendimento da linguagem Haskell como um todo e distinções e esclarecimentos entre conceitos importantes presentes em outras linguagens.

-> Campos duplicados em `Inimigo` e `Player`
No meio do desenvolvimento, acabei me deparando com um problema pois em teoria ambos o player e o inimigo desejam ter uma variavel vida em seus estados, acabei encarando as seções de data como objetos são retratados em outras linguagens e pensei nao haver problema em repetir nomes se em diferentes datas, o que me gerou um problema de compilação, com pesquisa percebi que o Haskell trata como funções e então duas funções nao podem ter o mesmo nome, resolvi isso de uma forma preguiçosa com um tendo "hp" e outro "health".




---

## 4. Testes

Descreva brevemente como você lidou com os testes unitários das funções que implementam a lógica do serviço, independentemente do Scotty.

Inclua, se necessário:

- quais funções puras foram testadas;
- como os testes foram organizados;
- se você usou HUnit ou outro modo simples de teste;
- exemplos curtos do que foi verificado.

Lembre que não se trata de testar se o serviço funciona pela web, mas sim de testar as funções puras que implementam a lógica.

---

## 5. Execução

Explique como executar o projeto, incluindo informações sobre dependências necessárias, comandos para compilar ou executar, etc.

---

## 6. Deploy

Link do serviço publicado: <complete aqui>

Descreva de forma breve como você realizou o deploy a partir da base e das orientações fornecidas. Caso não tenha conseguido, explique o que tentou.

---

## 7. Resultado final

Apresente o resultado final do trabalho, na forma de GIF animado ou vídeo curto (máximo 60s)

Você também pode acrescentar uma breve explicação sobre o que está sendo demonstrado.

---

## 8. Uso de IA

### 8.1 Ferramentas de IA utilizadas

Liste as principais ferramentas de IA utilizadas, com suas versões/modelos/planos. Por exemplo, ChatGPT Free com GPT-5.2 Thinking, GitHub Copilot com Gemini 2.0 Flash, Antigravity com Claude Sonnet 4.6 (Thinking), etc.
Claude - Sonnet 4.6 Thinking (Anthropic - Free): Utilizado como ferramenta de apoio ao desenvolvimento em estilo de pair programming, como se fosse um dev senior auxiliando-me, Ajudando na decomposição e resoluções de problemas, organização incremental, uso de boas práticas e reflexão sobre a lógica do sistema.
ChatGPT - GPT-5.x (OpenAI - Free): Utilizado pra esclarecimento de conceitos, revisão de decisões de design do projeto e apoio a escrita do README.     
---

### 8.2 Interações relevantes com IA

Inclua **de 3 a 5 interações relevantes** com ferramentas de IA.


#### Interação 1

- **Objetivo da consulta:**
- **Trecho do prompt ou resumo fiel:**
- **O que foi aproveitado:**
- **O que foi modificado ou descartado:**

#### Interação 2

- **Objetivo da consulta:**
- **Trecho do prompt ou resumo fiel:**
- **O que foi aproveitado:**
- **O que foi modificado ou descartado:**

#### Interação 3

- **Objetivo da consulta:**
- **Trecho do prompt ou resumo fiel:**
- **O que foi aproveitado:**
- **O que foi modificado ou descartado:**

#### Interação 4 (opcional)

- **Objetivo da consulta:**
- **Trecho do prompt ou resumo fiel:**
- **O que foi aproveitado:**
- **O que foi modificado ou descartado:**

#### Interação 5 (opcional)

- **Objetivo da consulta:**
- **Trecho do prompt ou resumo fiel:**
- **O que foi aproveitado:**
- **O que foi modificado ou descartado:**

---

### 8.3 Exemplo de erro, limitação ou sugestão inadequada da IA

Descreva **ao menos um caso** em que a IA:

- errou
- foi incompleta
- sugeriu algo inadequado ou incompreensível
- produziu código que precisou de correção relevante

Explique brevemente o que aconteceu e como você percebeu ou corrigiu o problema.

---

### 8.4 Comentário pessoal sobre o processo envolvendo IA

Escreva um breve comentário pessoal sobre o processo envolvendo IA.

Você pode comentar, por exemplo:

- algo que passou a compreender melhor
- uma dificuldade que conseguiu superar
- uma limitação que ainda sente
- como o uso de IA ajudou ou atrapalhou em certos momentos.

---

## 9. Referências e créditos

Liste referências e créditos de forma detalhada, com título e URL, incluindo, quando aplicável:


- sites consultados
- documentações
- materiais de aula
- colegas
- trechos de código adaptados
- imagens, vídeos

Exemplo:

- Documentação do Scotty: ...
- Documentação do Render: ...
- Material de aula da disciplina: ...
- Vídeo sobre Scotty: ...

Slay the Spire 2. Disponível em: (https://store.steampowered.com/app/2868840/Slay_the_Spire_2/)
Utilizado como referência de inspiração para a estrutura de progressão por turnos e modelagem do estado do jogo.

Fórum Zvon - Haskell
http://www.zvon.org/other/haskell/Outputprelude/div_f.html
Usado pra compreender funções utilizadas da biblioteca Prelude.
