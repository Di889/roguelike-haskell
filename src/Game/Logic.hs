module Game.Logic where

import Game.Types

pocao :: Item
pocao = Item {nomeItem = "Pocao", efeito = (Curar 20)}

escapeScroll :: Item
escapeScroll = Item {nomeItem = "escapeScroll", efeito = FugaGarantida}

aplicarEfeito :: Efeito -> Player -> Player
aplicarEfeito (Curar qtd) player = player {health = (health player) + qtd}
aplicarEfeito FugaGarantida player = player

calcNivel :: Int -> Int
calcNivel x = x `div` 10

calcDano :: Int -> Int
calcDano nivel = base + (nivel * bonus)
  where
   base = 5
   bonus = 3

rotacionar :: String -> String
rotacionar []     = []
rotacionar (x:xs) = xs ++ [x]

gerarInimigo :: Int -> Inimigo
gerarInimigo andar = Inimigo
  { hp         = 10 + (andar * 5)
  , ataque     = 2  + (andar * 1)
  , atkpattern = "AAB"
  }

avancarTurnoInimigo :: Inimigo -> Inimigo
avancarTurnoInimigo enemy = enemy {atkpattern = rotacionar (atkpattern enemy)}

adicionarItem :: Item -> [Item] -> [Item]
adicionarItem item lista =
  let numItens = length lista
      slotsItem = 3
  in if numItens < slotsItem
        then item : lista
        else lista

gerarItem :: Int -> Item
gerarItem num = case num of
  1 -> pocao
  _ -> escapeScroll

-- resolve o turno do inimigo
-- a defesa do jogador é aplicada no dano e depois sempre reseta
resolverTurno :: GameState -> GameState
resolverTurno gs =
  let playerSemDefesa = (jogador gs) { defesa = 0 }  -- reseta sempre
  in case inimigo gs of
    Nothing -> gs { jogador = playerSemDefesa }
    Just enemy ->
      let acaoInimigo = head (atkpattern enemy)
          danoFinal   = max 0 (ataque enemy - defesa (jogador gs))
          novoHealth  = health (jogador gs) - danoFinal
          buffDano    = 1
      in if acaoInimigo == 'A'
          -- inimigo ataca: aplica dano mitigado pela defesa e depois reseta defesa
          then gs
                { jogador = playerSemDefesa { health = novoHealth }
                , inimigo = Just enemy { atkpattern = rotacionar (atkpattern enemy) }
                }
          -- inimigo buffa: so rotaciona o pattern e reseta defesa do jogador
          else gs
                { jogador = playerSemDefesa
                , inimigo = Just enemy
                    { ataque     = ataque enemy + buffDano
                    , atkpattern = rotacionar (atkpattern enemy)
                    }
                }

avancarSala :: GameState -> GameState
avancarSala gs
  | (salaatual gs) >= 5 = gs {salaatual = 1, andaratual = (andaratual gs) + 1}
  | otherwise = gs {salaatual = (salaatual gs) + 1}

aplicarAcao :: GameState -> Acao -> GameState
aplicarAcao gs (Fugir fugirChance) = case fugirChance of
  0 -> gs
  _ -> (avancarSala gs) {inimigo = Nothing}
aplicarAcao gs Atacar = case inimigo gs of
  Nothing  -> gs
  Just ini ->
    let dano         = calcDano (calcNivel (xp (jogador gs)))
        novoHp       = hp ini - dano
        jogadorComXp = (jogador gs) { xp = xp (jogador gs) + 10 }
    in if novoHp <= 0
         then gs { inimigo = Nothing, jogador = jogadorComXp }
         else gs { inimigo = Just ini { hp = novoHp } }
aplicarAcao gs Defender = gs { jogador = (jogador gs) { defesa = 5 } }
aplicarAcao gs (Explorar roomNum itemRoll) =
  let novoState     = avancarSala gs
      curaFogueira  = Curar 20
      p             = jogador novoState
  in case roomNum of
    0 -> novoState
    1 -> novoState { inimigo = Just (gerarInimigo (andaratual novoState)) }
    2 -> novoState { jogador = aplicarEfeito curaFogueira p }
    _ -> novoState { jogador = p { itens = adicionarItem (gerarItem itemRoll) (itens p) } }
aplicarAcao gs (UsarItem item) = case efeito item of
  FugaGarantida -> (avancarSala gs) {inimigo = Nothing}
  _ ->
    let p           = jogador gs
        playerCurado = aplicarEfeito (efeito item) p
        novosItens  = filter (\i -> nomeItem i /= nomeItem item) (itens playerCurado)
    in gs { jogador = playerCurado { itens = novosItens } }

novaPartida :: String -> GameState
novaPartida nomeJogador =
  GameState
    { jogador = Player
        { nome   = nomeJogador
        , health = 30
        , xp     = 10
        , itens  = []
        , defesa = 0
        }
    , inimigo    = Nothing
    , andaratual = 1
    , salaatual  = 1
    }

-- RNGS, serao gerados pelo scotty:
-- itemRoll, um num de 1 a 2
-- roomNum, um num de 0 a 3
-- fugirChance, um num de 0 a 1
-- p1 = Player {nome = "fulano", health = 30, xp = 20, itens = [pocao, escapeScroll]}
-- i1 = Inimigo {hp = 50, ataque = 2, bloqueio = 3, atkpattern = "ABA"}
-- g1 = GameState {jogador = p1, inimigo = Nothing, andaratual = 1, salaatual = 1}
-- g2 = GameState {jogador = p1, inimigo = Just i1, andaratual = 1, salaatual = 1}

-- atk pattern do inimigo exemplo : "AAB" cada caractere é uma ação, A = ataca, B = defende e aumenta seu dano ex:(+1 de dano de ataque)