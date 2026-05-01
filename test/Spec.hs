module Main where

import Test.HUnit
import Game.Types
import Game.Logic

-- 1. calculo de dano
testCalcDano :: Test
testCalcDano = TestCase $ do
    assertEqual "Dano no nivel 0 (base 5 + 0*3)" 5 (calcDano 0)
    assertEqual "Dano no nivel 2 (base 5 + 2*3)" 11 (calcDano 2)

-- 2. efeito de cura
testAplicarCura :: Test
testAplicarCura = TestCase $ do
    let player = Player { nome = "teste", health = 10, xp = 0, itens = [], defesa = 0 }
    let playerCurado = aplicarEfeito (Curar 20) player
    assertEqual "O jogador deve ficar com 30 de vida" 30 (health playerCurado)

-- 3. Testando o avanço de sala
testAvancarSala :: Test
testAvancarSala = TestCase $ do
    let player = Player "Teste" 30 0 [] 0
    -- testa avanco normal (sala 1 -> 2)
    let gs = GameState player Nothing 1 1
    assertEqual "Deve avancar para sala 2" 2 (salaatual (avancarSala gs))

    -- testa transicao de andar (sala 5 -> andar 2, sala 1)
    let stateFimAndar = GameState player Nothing 1 5
    let stateNovoAndar = avancarSala stateFimAndar
    assertEqual "Deve resetar sala para 1" 1 (salaatual stateNovoAndar)
    assertEqual "Deve avancar para andar 2" 2 (andaratual stateNovoAndar)


testAplicarAcaoDefender :: Test
testAplicarAcaoDefender = TestCase $ do
    let player = Player "Teste" 30 0 [] 0
    let gs = GameState player Nothing 1 1
    let stateDefendendo = aplicarAcao gs Defender

    assertEqual "A defesa do jogador deve ir para 5" 5 (defesa (jogador stateDefendendo))

testResolverTurnoAtaque :: Test
testResolverTurnoAtaque = TestCase $ do
    let player = Player "Teste" 30 0 [] 0
    let enemy = Inimigo { hp = 10, ataque = 2, atkpattern = "AAB" }
    let gs = GameState player (Just enemy) 1 1
    let stateAposTurno = resolverTurno gs

    assertEqual "Vida do player deve diminuir para 28" 28 (health (jogador stateAposTurno))

    case inimigo stateAposTurno of
        Just iniAtualizado ->
            assertEqual "O pattern do inimigo deve rotacionar para 'ABA'" "ABA" (atkpattern iniAtualizado)
        Nothing ->
            assertFailure "Comportamento inesperado"

testsList :: Test
testsList = TestList [testCalcDano, testAplicarCura, testAvancarSala, testAplicarAcaoDefender, testResolverTurnoAtaque]

main :: IO ()
main = do
    _ <- runTestTT testsList
    return ()