module Main where

import Lib

main :: IO ()
main = do

  -- Simpler examples
  print (t x y)
  print (mapMyData fn_md md1)
  print (sumMyData md1)

  -- This example both tests the inliner's ability to correctly inline composed
  -- functions and compares this being done within an expression with it being
  -- done in a top-level binding.
  print (sumMyData (mapMyData fn_md md1))
  print (sumMapMyData md1)

t :: Int -> Int -> Bool
t a b = g (f a + b)

md1 :: MyData Int Int
md1 = Pair
        (Pair (Leaf 1 2)
              (Leaf 3 4))
        (Pair (Something 5 (Leaf 6 7))
              (Leaf 8 9))

md2 :: MyData () ()
md2 = Leaf () ()

md3 :: MyData () ()
md3 = Something 0 md2

-- This structure is infinite on the last field, so we want to make sure that
-- the inlining takes that into account and only inlines the first field.
-- We should consider that Plutus will need to know about the infinite recursion
-- when the AST is produced, so it's important that we can detect where this
-- reference happens.
md4 :: MyData () ()
md4 = Pair md3 md4

fn_md :: Int -> Int -> (Bool, Int)
fn_md x y = (x == y, x + y)

sumMapMyData :: MyData Int Int -> Int
sumMapMyData x = sumMyData (mapMyData fn_md x)
