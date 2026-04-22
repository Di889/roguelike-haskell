module Main where

main :: IO ()
main = do
  putStrLn "Hello, Haskell!"

data Item = Potion | Shield deriving (Show)

data Player = Player
  { nome  :: String
  , xp    :: Int
  , itens :: [Item]
  } deriving (Show)

data Inimigo = Inimigo
  { hp :: Int
  , ataque :: Int
  , bloqueio :: Int
  , atkpattern :: String
  } deriving (Show)

data GameState = GameState
  { jogador :: Player
  , inimigo :: Maybe Inimigo
  , andaratual :: Int
  , salaatual :: Int
  } deriving (Show)

data Acao = Explorar | Atacar | Defender | Fugir | UsarItem Item deriving(Show)

-- calcula nivel pelo xp, 10 xp = 1 lvl
calcNivel :: Int -> Int
calcNivel x = x `div` 10

-- calcula dano por nivel
calcDano :: Int -> Int
calcDano nivel = base + (nivel * bonus)
  where
   base = 5
   bonus = 3


aplicarAcao :: GameState -> Acao -> GameState
aplicarAcao state Fugir = state {inimigo = Nothing, salaatual = salaatual state + 1}
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
aplicarAcao state (UsarItem _) = state

-- p1 = Player {nome = "fulano", xp = 20, itens = [Potion, Shield]}
-- i1 = Inimigo {hp = 50, ataque = 2, bloqueio = 3, atkpattern = "012"}
-- g1 = GameState {jogador = p1, inimigo = Nothing, andaratual = 1, salaatual = 1}
-- g2 = GameState {jogador = p1, inimigo = Just i1, andaratual = 1, salaatual = 1}