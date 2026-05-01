{-# LANGUAGE OverloadedStrings #-}

module Main where

import Game.Types
import Game.Logic

import Web.Scotty
import System.Random (randomRIO)
import Control.Monad.IO.Class (liftIO)

main :: IO ()
main = scotty 3000 $ do

  -- cria uma nova partida e retorna o gamestate zeradinho
  -- POST /nova-partida/:nome
  post "/nova-partida/:nome" $ do
    nome <- pathParam "nome"
    json (novaPartida nome)

  -- recebe o gamestate + acao do cliente, aplica a acao, resolve o turno do inimigo e então retorna o novo gamestate
  -- POST /acao
  -- Body (JSON): { "gameState": <GameState>, "acaoCliente": <AcaoCliente> }
  post "/acao" $ do
    req <- jsonData :: ActionM AcaoClienteRequest
    let gs = gameState req
    novoEstado <- liftIO $ processarAcao gs (acaoCliente req)
    json novoEstado

  -- pra teste
  get "/" $ text "api - ok"


-- converte AcaoCliente p/ Acao e gera os RNGs necessarios
-- aplica a acao e resolve o turno do inimigo
processarAcao :: GameState -> AcaoCliente -> IO GameState
processarAcao gs ExplorarC = do
  roomNum  <- randomRIO (0, 3) :: IO Int  -- 0=vazio 1=inimigo 2=fogueira 3=item
  itemRoll <- randomRIO (1, 2) :: IO Int  -- 1=pocao 2=escapeScroll
  let estadoAposAcao = aplicarAcao gs (Explorar roomNum itemRoll)
  return $ resolverTurno estadoAposAcao

processarAcao gs AtacarC = do
  let estadoAposAcao = aplicarAcao gs Atacar
  return $ resolverTurno estadoAposAcao

processarAcao gs DefenderC = do
  let estadoAposAcao = aplicarAcao gs Defender
  return $ resolverTurno estadoAposAcao

processarAcao gs FugirC = do
  fugirChance <- randomRIO (0, 1) :: IO Int  -- 0=falhou 1=escapou
  let estadoAposAcao = aplicarAcao gs (Fugir fugirChance)
  return $ resolverTurno estadoAposAcao

processarAcao gs (UsarItemC item) = do
  let estadoAposAcao = aplicarAcao gs (UsarItem item)
  return $ resolverTurno estadoAposAcao