{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
module Game.Types where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)


data Efeito = Curar Int | FugaGarantida deriving (Show, Generic, ToJSON, FromJSON)

data Item = Item
  { nomeItem :: String
  , efeito :: Efeito
  } deriving (Show, Generic, ToJSON, FromJSON)

data Player = Player
  { nome  :: String
  , health :: Int
  , xp    :: Int
  , itens :: [Item]
  , defesa :: Int
  } deriving (Show, Generic, ToJSON, FromJSON)

data Inimigo = Inimigo
  { hp :: Int
  , ataque :: Int
  , atkpattern :: String
  } deriving (Show, Generic, ToJSON, FromJSON)

data GameState = GameState
  { jogador :: Player
  , inimigo :: Maybe Inimigo
  , andaratual :: Int
  , salaatual :: Int
  } deriving (Show, Generic, ToJSON, FromJSON)

data Acao = Explorar Int Int | Atacar | Defender | Fugir Int | UsarItem Item deriving (Show, Generic, ToJSON, FromJSON)

data AcaoRequest = AcaoRequest
  { state :: GameState
  , acao  :: Acao
  } deriving (Show, Generic, ToJSON, FromJSON)


-- tipo que o cliente envia sem os RNGs
-- o server gera os rng e converte para Acao
data AcaoCliente
  = ExplorarC         -- servidor gera roomNum e itemRoll
  | AtacarC
  | DefenderC
  | FugirC            -- servidor gera fugirChance
  | UsarItemC Item
  deriving (Show, Generic, ToJSON, FromJSON)

data AcaoClienteRequest = AcaoClienteRequest
  { gameState  :: GameState
  , acaoCliente :: AcaoCliente
  } deriving (Show, Generic, ToJSON, FromJSON)