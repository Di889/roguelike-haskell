module Main where

main :: IO ()
main = do
  putStrLn "Hello, Haskell!"

-- ############ SECAO DE DADOS ##############

data Efeito = Curar Int | FugaGarantida deriving (Show)

data Item = Item
  { nomeItem :: String
  , efeito :: Efeito
  } deriving (Show)

data Player = Player
  { nome  :: String
  , health :: Int
  , xp    :: Int
  , itens :: [Item]
  } deriving (Show)

data Inimigo = Inimigo
  { hp :: Int
  , ataque :: Int
  , bloqueio :: Int -- TODO: deprecated, nao implementado, ainda, pois aumentaria a complexidade, a ver
  , atkpattern :: String
  } deriving (Show)

data GameState = GameState
  { jogador :: Player
  , inimigo :: Maybe Inimigo
  , andaratual :: Int
  , salaatual :: Int
  } deriving (Show)

data Acao = Explorar Int Int | Atacar | Defender | Fugir Int | UsarItem Item deriving(Show)

-- Itens concretos

pocao :: Item
pocao = Item {nomeItem = "Pocao", efeito = (Curar 20)}

escapeScroll :: Item
escapeScroll = Item {nomeItem = "escapeScroll", efeito = FugaGarantida}

-- ############### SECAO DE FUNÇÕES PURAS ###################

aplicarEfeito :: Efeito -> Player -> Player
aplicarEfeito (Curar qtd) player = player {health = (health player) + qtd}
aplicarEfeito FugaGarantida player = player

-- calcula nivel pelo xp, 10 xp = 1 lvl
calcNivel :: Int -> Int
calcNivel x = x `div` 10

-- calcula dano por nivel
calcDano :: Int -> Int
calcDano nivel = base + (nivel * bonus)
  where
   base = 5
   bonus = 3

-- rotaciona a string colocando o primeiro carac na ultima posição e o resto no começo
rotacionar :: String -> String
rotacionar []     = []
rotacionar (x:xs) = xs ++ [x]

gerarInimigo :: Int -> Inimigo
gerarInimigo andar = Inimigo
  { hp         = 10 + (andar * 5)
  , ataque     = 2  + (andar * 1)
  , bloqueio   = 0 -- a ver isso aq
  , atkpattern = "AAB"
  }

-- apenas rotaciona a string de atk Pattern do inimigo
avancarTurnoInimigo :: Inimigo -> Inimigo
avancarTurnoInimigo enemy = enemy {atkpattern = rotacionar (atkpattern enemy)}

adicionarItem :: Item -> [Item] -> [Item]
adicionarItem item itens =
  let numItens = length itens
      slotsItem = 3
  in if numItens < slotsItem
        then item : itens -- adicionamos no comeco da lista
        else itens -- nao mexe pois esta cheio

gerarItem :: Int -> Item
gerarItem num = case num of
  1 -> pocao
  _ -> escapeScroll


resolverTurno :: GameState -> GameState
resolverTurno state = case inimigo state of
    Nothing -> state
    Just enemy ->
      let acao = head (atkpattern enemy)
          healthAtacado = health (jogador state) - ataque enemy
          buffDano = 1
      in if acao == 'A'
          -- é um ataque, inimigo ataca o jogador, rotaciona o pattern
          then state { jogador = (jogador state) {health = healthAtacado}, inimigo = Just enemy {atkpattern = rotacionar (atkpattern enemy) }}
          -- não é ataque, então buffa o dano e rotaciona o pattern
          else state { inimigo = Just enemy {ataque = ataque enemy + buffDano, atkpattern = rotacionar (atkpattern enemy)}}

avancarSala :: GameState -> GameState
avancarSala state
  | (salaatual state) >= 5 = state {salaatual = 1, andaratual = (andaratual state) + 1}
  | otherwise = state {salaatual = (salaatual state) + 1}

aplicarAcao :: GameState -> Acao -> GameState
aplicarAcao state (Fugir fugirChance) = case fugirChance of
  0 -> state -- nao escapou, tirou 0
  _ -> (avancarSala state) {inimigo = Nothing} -- escapou, tirou 1
aplicarAcao state Atacar = case inimigo state of
  Nothing  -> state
  Just ini ->
    let dano         = calcDano (calcNivel (xp (jogador state)))
        novoHp       = hp ini - dano
        jogadorComXp = (jogador state) { xp = xp (jogador state) + 10 }
    in if novoHp <= 0
         then state { inimigo = Nothing, jogador = jogadorComXp }
         else state { inimigo = Just ini { hp = novoHp } }


aplicarAcao state Defender = state -- deprecated, TODO: pra funcionar deve ter um turn manager que permite acao de player e inimigo, e ele tira a defesa no comeco do turno
aplicarAcao state (Explorar roomNum itemRoll) =
  let novoState = avancarSala state -- avancamos a sala e agora decidimos oq tera nela, com base no rng q o scotty gera
      curaFogueira = (Curar 20)
      p = (jogador novoState)
  in case roomNum of
    0 -> novoState -- sala vazia
    1 -> novoState {inimigo = Just (gerarInimigo (andaratual novoState))} -- inimigo
    2 -> novoState {jogador = aplicarEfeito curaFogueira p} -- fogueira, cura o jogador
    _ -> novoState {jogador = p {itens = adicionarItem (gerarItem itemRoll) (itens p)}} -- adicionamos um item pro jogador, se tiver espaco
aplicarAcao state (UsarItem item) = case efeito item of
  FugaGarantida -> (avancarSala state) {inimigo = Nothing}
  _ ->
    let p = jogador state
        playerCurado = aplicarEfeito (efeito item) p
        novosItens = filter (\i -> nomeItem i /= nomeItem item) (itens playerCurado)
    in state { jogador = playerCurado { itens = novosItens } }


-- RNGS, serao gerados pelo scotty:
-- itemRoll, um num de 1 a 2
-- roomNum, um num de 0 a 4
-- fugirChance, um num de 0 a 1
-- p1 = Player {nome = "fulano", health = 30, xp = 20, itens = [pocao, escapeScroll]}
-- i1 = Inimigo {hp = 50, ataque = 2, bloqueio = 3, atkpattern = "ABA"}
-- g1 = GameState {jogador = p1, inimigo = Nothing, andaratual = 1, salaatual = 1}
-- g2 = GameState {jogador = p1, inimigo = Just i1, andaratual = 1, salaatual = 1}

-- atk pattern do inimigo exemplo : "AAB" cada caractere é uma ação, A = ataca, B = defende e aumenta seu dano ex:(+1 de dano de ataque)