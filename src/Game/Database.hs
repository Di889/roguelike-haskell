{-# LANGUAGE OverloadedStrings #-}

module Game.Database where

import Database.SQLite.Simple

dbName :: String
dbName = "roguelike.db"

initDB :: IO ()
initDB = do
    conn <- open dbName
    execute_ conn "CREATE TABLE IF NOT EXISTS leaderboard (nome TEXT, andar INTEGER)"
    close conn

salvarScore :: String -> Int -> IO ()
salvarScore nomeJogador andarAlcancado = do
    conn <- open dbName
    execute conn "INSERT INTO leaderboard (nome, andar) VALUES (?, ?)" (nomeJogador, andarAlcancado)
    close conn

-- pega os 10 melhores scores ordenados por andar do maior para o menor
-- retorna uma lista de tuplas com o formato: (Nome, Andar)
getLeaderboard :: IO [(String, Int)]
getLeaderboard = do
    conn <- open dbName
    pontuacoes <- query_ conn "SELECT nome, andar FROM leaderboard ORDER BY andar DESC LIMIT 10" :: IO [(String, Int)]
    close conn
    return pontuacoes