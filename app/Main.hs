{-# LANGUAGE OverloadedStrings #-}

module Main where

import Game.Types
import Game.Logic
import Game.Database

import Web.Scotty
import System.Random (randomRIO)

main :: IO ()
main = do
  -- iniciamos o db antes de subir o server web
  initDB

  scotty 3000 $ do

    -- rotas do frontend
    get "/" $ file "public/index.html"

    get "/style.css" $ do
      setHeader "Content-Type" "text/css"
      file "public/style.css"

    get "/app.js" $ do
      setHeader "Content-Type" "application/javascript"
      file "public/app.js"

    -- GET /leaderboard
    get "/leaderboard" $ do
      pontuacoes <- liftIO getLeaderboard
      json pontuacoes

    -- cria uma nova partida e retorna o gamestate zeradinho
    -- POST /nova-partida/:nome
    post "/nova-partida/:nome" $ do
      nomeReq <- pathParam "nome"
      json (novaPartida nomeReq)

    -- recebe o gamestate + acao do cliente, aplica a acao, resolve o turno do inimigo e então retorna o novo gamestate
    -- POST /acao
    -- Body (JSON): { "gameState": <GameState>, "acaoCliente": <AcaoCliente> }
    post "/acao" $ do
      req <- jsonData :: ActionM AcaoClienteRequest
      let gs = gameState req
      novoEstado <- liftIO $ processarAcao gs (acaoCliente req)

      -- checamos se o jogador morreu pra salvar no db
      let p = jogador novoEstado
      if (health p) <= 0
        then liftIO $ salvarScore (nome p) (andaratual novoEstado)
        else return ()

      json novoEstado


-- converte AcaoCliente p/ Acao e gera os RNGs necessarios
-- aplica a acao e resolve o turno do inimigo
processarAcao :: GameState -> AcaoCliente -> IO GameState
processarAcao gs ExplorarC = do
  roomRoll <- randomRIO (1, 10) :: IO Int
  let roomNum
        | roomRoll <= 5 = 1 -- 50% de ser inimigo
        | roomRoll <= 7 = 3 -- 20% de ser item
        | roomRoll == 8 = 2 -- 10% de ser fogueira
        | otherwise     = 0 -- 20% de ser sala vazia

  itemRoll <- randomRIO (1, 2) :: IO Int
  let estadoAposAcao = aplicarAcao gs (Explorar roomNum itemRoll)
  return estadoAposAcao

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