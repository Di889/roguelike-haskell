## 1. Identificação

- Nome: Diógenes Potrich Steca
- Curso: Sistemas de Informação

---

## 2. Tema/objetivo

O objetivo deste trabalho é desenvolver uma aplicação de backend web em Haskell utilizando o framework Scotty, focando na implementação da lógica de um jogo simples no estilo roguelike por turnos. O sistema permite que o jogador execute ações como explorar salas, enfrentar inimigos, utilizar itens e fugir de combates, sendo que cada ação muda o estado do jogo.

A lógica principal do trabalho é que o jogo pode ser representado como uma sequencia de transformações de estado. Nesse caso, o estado do jogo é representado por uma estrutura imutável `GameState`, que contem informações core sobre o estado do jogo, tais como: informações sobre o jogador, sobre o inimigo(se tiver) e sobre progressão de salas e andares. A cada ação que o jogador realiza, uma função recebe o estado do jogo e retorna um novo estado atualizado, não modificando os dados existentes.

O trabalho aplica programação funcional pois estrutura toda a lógica atraves de funções puras, como `aplicarAcao`, `resolverTurno` e `aplicarEfeito`, essas funções são sem efeitos colaterais, ou seja, produzem sempre o mesmo resultado dada uma mesma entrada, o que facilita a previsibilidade e os testes em cima da aplicação.

Ainda, é utilizado tipos algebricos, como pra representar diferentes Açoes `Acao` e efeitos de itens `Efeito`, ajudando na escalabilidade do projeto e organização, Também usamos recursos do haskell que congruem com a logica do jogo, um exemplo é o Maybe usado pois a presença de um inimigo no jogo não é garantida todo o tempo.

Não obstante, pra desacoplar aplicação, separamos a lógica pura(core) da camada de efeitos(não confundir com os efeitos de itens). Funções que dependem de RNG(por ex, itens e salas), não são tratadas na camada de lógica pura, mas sim em uma camada externa(Scotty). Isso ajuda a alinhar com os principios de programação funcional e a logica se tornar mais "tidy", deterministica. 

Por fim, como proposto e aconselhado pela professora, o trabalho é versionado sendo implementado de forma incremental, iniciando pela implementação do nucleo lógico do jogo e, posteriormente, integrando essa lógica com a API web por meio do framework Scotty. Funcionalidades adicionais que tendem a aumentar a complexidade de forma não-linear serão/foram avaliadas conforme o tempo restante da entrega.


---

## 3. Processo de desenvolvimento

- **Sobre a ideia inicial**
a ideia principal basicamente se concretizou, o projeto está como eu o imaginei, confesso que pensei que fosse mais facil e ate cogitei coisas que dariam scope creep como equipamentos diversificados e inimigos mais diversos, talvez uma progressão melhor. Porém, ainda assim fiquei satisfeito com o resultado

-**Modelagem do estado com Maybe inimigo**
Durante a modelagem inicial do estado do jogo e da lógica principal, esbarrei em um problema que era sobre como representar um inimigo, já que desde a ideia principal era poder ter salas com e sem inimigos, ou seja, o jogador nem sempre tem uma ameaça direta.

Após pesquisar formas de implementar o requerido com recursos do haskell, encontrei o tipo `Maybe` que preenche essa lacuna com as duas possibilidades, não tendo com "Nothing" e tendo com "Just inimigo".

- **Seperação do RNG da lógica pura**
uma decisão que tomei foi não incluir geração de valores aleatórios juntamente da lógica principal e das funções principais do jogo. Em vez disso, esses valores são recebidos como parametros pelas funções, onde será responsabilidade de uma camada externa(Scotty) de gerar esses valores.
- 
Essa abordagem mantém as funções puras e determínisticas, o que facilita testes, debugging e melhora a compreensão do comportamento do sistema.

- **Dificuldade com where em expressões case**
Durante a implementação, acabei por usar `where` dentro de uma expressão `case`, o que resultou em erro de compilação.
- 
Após pesquisas e uma sessão de tira-duvidas com a ajuda do Claude, percebi que o `where` está associado com definições de equações e funções e, portanto, não pode ser usado diretamente com `case`. Pra resolver isso, utilizei a estrutura `let` e `in`, que permite definir variaveis locais dentro de expressões.

Isso contribuiu pra um maior entendimento da linguagem Haskell como um todo pra mim e distinções e esclarecimentos entre conceitos importantes presentes em outras linguagens.

- **Campos duplicados em `Inimigo` e `Player`**
No meio do desenvolvimento, acabei me deparando com um problema pois em teoria ambos o player e o inimigo desejam ter uma variavel vida em seus estados, acabei encarando as seções de data como objetos são retratados em outras linguagens e pensei nao haver problema em repetir nomes se em diferentes datas, o que me gerou um problema de compilação, com pesquisa percebi que o Haskell trata como funções e então duas funções nao podem ter o mesmo nome, resolvi isso de uma forma preguiçosa com um tendo "hp" e outro "health".

- **Sobre o Scotty e a execução do servidor web**
Inicialmente, tentei executar o projeto usando o cabal no windows(win 10). Porém, enfrentei um monte de dificuldades pois não funcionava de jeito nenhum, tentei desativar antivirus, pesquisar problemas, desativar firewall, criar um novo projeto cabal, entre outras alternativas. 

foi quando achei em um forum falando sobre o WSL usando o Ubuntu, foi quando resolvi tentar essa alternativa e enfim consegui fazer o Scotty funcionar.

---

## 4. Testes

Utilizei a biblioteca HUnit pra estruturar e realizar os testes unitários. O foco foi em, justamente, validar as funções puras isolando-as da camade web(Scotty) e de efeitos colaterais, como o RNG e o banco de dados.

As principais funções testadas foram as mais verbosas, incluindo: aplicarAcao, aplicarEfeito e resolverTurno. Foram simulados alguns GameStates pra simular a jogabilidade e testar os casos.

---

## 5. Execução

O projeto foi desenvolvido em cima do gerenciador de pacotes Cabal.

Pré-requisitos: 
é necessario ter instalado a Haskell Toolchain(GHCi e Cabal). Ainda, devido a questões de restrições de rede e firewall nativas do Windows, recomenda-se a execução do projeto em um ambiente Linux(ou via WSL no windows, ambiente que foi utilizado pra teste e desenvolvimento do projeto).

Passo a passo para execução local:

1. Clone o repositório e navegue até a pasta raiz do projeto.
2. Baixe as dependências e compile a aplicação executando: ```cabal build```
3. Para iniciar a API e o servidor web Scotty, utilize: ```cabal run```

Se os passos foram seguidos corretamente, o servidor estará rodando e para acessar a interface do jogo basta colocar no navegador o endereço: ```http://localhost:3000```

---

## 6. Deploy

Link do serviço publicado: <complete aqui>


---

## 7. Resultado final

Apresente o resultado final do trabalho, na forma de GIF animado ou vídeo curto (máximo 60s)

Você também pode acrescentar uma breve explicação sobre o que está sendo demonstrado.

---

## 8. Uso de IA

### 8.1 Ferramentas de IA utilizadas

Claude - Sonnet 4.6 Thinking (Anthropic - Free): Utilizado como ferramenta de apoio ao desenvolvimento em estilo de pair programming, como se fosse um dev senior auxiliando-me, Ajudando na decomposição e resoluções de problemas, organização incremental, uso de boas práticas e reflexão sobre a lógica do sistema.

Claude - Sonnet 4.6 Thinking (Anthropic - Free)/2: Utilizado para fazer e estruturar a lógica do front-end(Html, css e js). 

ChatGPT - GPT-5.x (OpenAI - Free): Utilizado pra esclarecimento de conceitos, revisão de decisões de design do projeto e apoio a escrita do README.     



---

### 8.2 Interações relevantes com IA


#### Interação 1

- **Objetivo da consulta: explorar alternativas sobre a implementação do padrão de ataque do inimigo
- **Trecho do prompt ou resumo fiel: "A = ataque, B = defesa e buff tipo aumenta +1 ou +2 de dano ou bloqueio pra punir se demorar dai tipo AAB, acho melhor entao acho que seria tipo no inimigo pois ja tem o pattern e talvez uma outra variavel turnoatual que so pega o primeiro character do atkpattern, mas e como fariamos pra progredir ?"
- **O que foi aproveitado: diante da minha ideia de guardar em uma string, a IA sugeriu que usassemos pattern matching pra rotacionar a string e pegarmos apenas a cabeça(head)
- **O que foi modificado ou descartado: não exatamente da resposta dele, mas que foi impactada: a minha ideia original de criar uma função separada "turnoAtual"

#### Interação 2

- **Objetivo da consulta: gerar um front-end pra aplicação web, pra melhor ilustrar o sistema e ajudar na interação 
- **Trecho do prompt ou resumo fiel: Gere um frontend completo (HTML, CSS estilo dungeon dark e JS vanilla) que consuma rotas fetch de uma API local (POST /acao, POST /nova-partida) enviando e recebendo um JSON com o estado do jogo para atualizar a tela
- **O que foi aproveitado: toda a estrutura e a lógica provida através de html, css e js
- **O que foi modificado ou descartado: ajustem no codigo de css pra ficar mais como eu desejava e no javascript pra funcionar com a lógica do backend

#### Interação 3

- **Objetivo da consulta: entender melhor sobre a keyword Maybe no haskell
- **Trecho do prompt ou resumo fiel: "ta mas apenas assim tipo com Maybe inimigo ele ja sabe que ou é um data Inimigo ou é nothing? ou precisa criar outra coisa que retorne ou Just Inimigo ou nothing tipo data inimigopossivel = Just Inimigo | Nothing?"
- **O que foi aproveitado: o explicação que ele deu, inclusive com a comparação com a estrutura Nullable<T> do C#
- **O que foi modificado ou descartado: nada

---

### 8.3 Exemplo de erro, limitação ou sugestão inadequada da IA

-> formato json do Aeson com tipos algébricos
após integrar a parte da aplicação web(Scotty) e as rotas, que iriam receber json a depender do seu funcionamento, como eu usei o Aeson pra estruturar o Json de forma automática sem parse manual, pedi então pra ia montar o json de teste e ela montou no formato padrão ex: {"acaoCliente": "ExplorarC"}.
isso acabou gerando um erro de parsing do haskell, pois como eu faço uso de um contrutor com parametros(UsarItemC Item), o Aeson acaba por usar uma estratégia chamada "Tagged Objects" que estrutura o tipo em "tag" e "content".
como a ia não tinha me avisado previamente, tive que tomar conhecimento dessa lógica e corrigir o json passado

-> lógica na verificação de ação do front-end
dado que o código do javascript chegou com algumas ressalvas, uma delas foi a verificação de ação pra mostrar na tela.
a ia não verificava a cabeça(head) do padrão de ataque do inimigo, mas sim usava algumas heuristicas falhas e simples demais, resolvi isso verificando a head da string do padrão de ataque do inimigo pra então resolver a lógica

---

### 8.4 Comentário pessoal sobre o processo envolvendo IA

com o uso da ia no projeto eu passei a compreender varios conceitos que ainda não tinha visto na linguagem e funções que não havia usado, achei produtivo mesmo usando mais como pair programming, isto é, sem pedir a solução de cara, de modo que estimulasse mais o pensamento lógico

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
