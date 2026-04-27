module Game.Types where


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