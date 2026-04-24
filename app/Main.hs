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

data Acao = Explorar | Atacar | Defender | Fugir | UsarItem Item deriving(Show)

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

-- apenas rotaciona a string de atk Pattern do inimigo
avancarTurnoInimigo :: Inimigo -> Inimigo
avancarTurnoInimigo enemy = enemy {atkpattern = rotacionar (atkpattern enemy)}

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

aplicarAcao :: GameState -> Acao -> GameState
aplicarAcao state Fugir = state {inimigo = Nothing, salaatual = salaatual state + 1} -- TODO: falta um rand pra ver se vai conseguir escapar ainda
aplicarAcao state Atacar = case inimigo state of
  Nothing  -> state
  Just ini ->
    let dano         = calcDano (calcNivel (xp (jogador state)))
        novoHp       = hp ini - dano
        jogadorComXp = (jogador state) { xp = xp (jogador state) + 10 }
    in if novoHp <= 0
         then state { inimigo = Nothing, jogador = jogadorComXp }
         else state { inimigo = Just ini { hp = novoHp } }


aplicarAcao state Defender = state
aplicarAcao state Explorar = state
aplicarAcao state (UsarItem item) = case efeito item of
  Curar qtd ->
    let p          = (jogador state)
        novoHealth = health p + qtd
        novosItens = filter (\i -> nomeItem i /= nomeItem item) (itens p)
        novoPlayer = p { health = novoHealth, itens = novosItens }
    in state { jogador = novoPlayer }
  FugaGarantida -> state {inimigo = Nothing, salaatual = (salaatual state) + 1}


-- p1 = Player {nome = "fulano", health = 30, xp = 20, itens = [pocao, escapeScroll]}
-- i1 = Inimigo {hp = 50, ataque = 2, bloqueio = 3, atkpattern = "ABA"}
-- g1 = GameState {jogador = p1, inimigo = Nothing, andaratual = 1, salaatual = 1}
-- g2 = GameState {jogador = p1, inimigo = Just i1, andaratual = 1, salaatual = 1}

-- atk pattern do inimigo exemplo : "AAB" cada caractere é uma ação, A = ataca, B = defende e aumenta seu dano ex:(+1 de dano de ataque)