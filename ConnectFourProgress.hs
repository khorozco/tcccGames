module ConnectFour where

import Data.List (transpose, intersperse)
import Data.Foldable (asum)
import Data.Char (digitToInt)

-- initial board creation
startMessage :: IO ()
startMessage = putStr $ unlines ["\n",
                                "\t Let's begin!"]

-- called in main, where x is the size of the board
startBoard :: Int -> Board
startBoard x = replicate x (replicate (x-1) Empty)

-- datatype for gameboard squares
data Square = X
            | O
            | Empty
    deriving (Eq)

instance Show Square where
    show X     = " X "
    show O     = " O "
    show Empty = "   "

-- the gameboard
type Board = [[Square]]

-- shows board
displayBoard :: Board -> String
displayBoard xs = unlines
             . surround vertex . map (concat . surround line . map show) $ reverse (transpose xs)
    where line = "|"
          vertex = "+---+---+---+---+---+---+---+"

-- surrounds every element of ys between x values
surround :: a -> [a] -> [a]
surround x ys = x : intersperse x ys ++ [x]
-- returns [x,ys[1],x,ys[2],x,ys[3]]

-- players
data Players = PlayerX | PlayerO deriving (Eq)

instance Show Players where
    show PlayerX = "Player X"
    show PlayerO = "Player O"

toPlayers :: Square -> Players
toPlayers X = PlayerX
toPlayers O = PlayerO

fromPlayers :: Players -> Square
fromPlayers PlayerX = X
fromPlayers PlayerO = O

switchPlayers :: Players -> Players
switchPlayers PlayerX = PlayerO
switchPlayers PlayerO = PlayerX

-- checks all (or should check all) winning patterns/possibilities
checkWinner :: Board -> Maybe Square
--checkWinner ys = fourInARow (concat ys)
--checkWinner ys = asum (map fourInARow (diag ++ rev ++ cols))  -- deleted ++ys
-- ys = board
checkWinner ys = fourInARow (cols ++ diag ++ rev ++ (concat ys)) -- split lists by cols, diag, rev
    where cols = concat (transpose ys)
          diag = zipWith (!!) ys           [0..5]
          rev  = zipWith (!!) (reverse ys) [0..5]

-- should eliminate game ending upon appearance of empty board (but did not)
--allFilled :: [Square] -> Bool
--allFilled (w:x:y:z:zs) = if (w /= Empty && x /= Empty && y /= Empty && z /= Empty) then True
--                                                                        else False

-- sees if there is a pattern of four in a row
fourInARow :: [Square] -> Maybe Square
fourInARow (x:xs) = if (xs == []) then Nothing
                    else if ((x == (head xs)) && ((head xs) == (head (tail xs))) && ((head (tail xs)) == (head (tail (tail xs)))) && x /= Empty && (head xs) /= Empty && (head (tail xs)) /= Empty && (head (tail (tail xs))) /= Empty) then Just (x)
                    else fourInARow xs

-- gets coordinates for all squares in the board
getCoordinates :: Int -> Board -> (Int, Int)
getCoordinates n = divMod (n) . length

-- inserts into the correct square based on column capacity
fillSquare :: Board -> Int -> Square -> Board
fillSquare b@(x:xs) col currentplayer = if col == 0
                                        then (findRow currentplayer (b !! col)) : xs
                                        else x : fillSquare xs (col-1) currentplayer

-- helper function: inserts into first open row of a column
findRow :: Square -> [Square] -> [Square]
findRow p (r:rs) 
    | (r == Empty)         = p:rs
    | (r == (last (r:rs))) = r:rs
    | otherwise            = r:findRow p rs

-- checks if move is valid
checkOpenSquare :: Board -> String -> Either String Int
checkOpenSquare xs s = case reads s of

    [(colNumber, _)] -> check colNumber
    _                -> Left "Error: Please enter an integer"

    where check colNumber
            | colNumber <= 0 || colNumber > (length xs)
                    = Left "Please enter integer in range"
            | (xs !! (colNumber-1) !! 5) /= Empty
                    = Left "Column already filled"
            | otherwise
                    = Right row

            where (row, col) = getCoordinates (colNumber-1) xs

-- plays game, asks for input
askInput :: Players -> Board -> IO ()
askInput p board = do

    putStrLn $ displayBoard board
    putStr "  1   2   3   4   5   6   7  \n \n"
    putStrLn $ show p ++ ", make your move"

    putStr $ "(Enter number 1-" ++ show (length board) ++ "): \n"
    colNumber <- getLine
    putStr "\n"

    case checkOpenSquare board colNumber of

        Left s  -> putStrLn ("Invalid input: " ++ s) >> gameStep p board

        Right n -> let cell = fromPlayers p
                       next = switchPlayers p
--                       (row, col) = getCoordinates colNumber board
                       col = digitToInt (head colNumber) - 1

                   in gameStep next (fillSquare board col cell)
                   -- check what switching row/col here doeshh

-- end of game
gameStep :: Players -> Board -> IO ()
gameStep p board = case checkWinner board of

    Just winner -> do

        putStrLn $ displayBoard board
        putStr "  1   2   3   4   5   6   7  \n \n"
        putStrLn $ "\t" ++ show winner ++ " wins! \n"

    Nothing -> do
        if gameOver board
            then do
                putStrLn $ displayBoard board
                putStr "  1   2   3   4   5   6   7  \n \n"
                putStrLn "\t It's a draw! \n"
        else askInput p board

gameOver :: Board -> Bool
gameOver = all (notElem Empty)

-- length of board
boardSize :: Int
boardSize = 7

main :: IO ()
main = do
    startMessage
    gameStep PlayerX (startBoard boardSize)