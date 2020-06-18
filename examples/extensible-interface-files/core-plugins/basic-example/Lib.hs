module Lib (f, xs, g, x, y, infinite, mapMyData, sumMyData, MyData(..)) where

-- Not exported, to test the serialised bindings
a, b :: Int
a = 0
b = a

x, y :: Int
x = 1
y = x + 2

f :: Int -> Int
f = plus 1
  where
    plus = (+)

-- Test for self-recursive bindings
xs :: [()]
xs = ():xs

-- Test for multiple-equation bindings
g :: Int -> Bool
g 0 = True
g _ = False

infinite :: a -> [a]
infinite x = x : infinite x

data MyData a b
   = Leaf a b
   | Something Int (MyData a b)
   | Pair (MyData a b) (MyData a b)
   deriving Show

mapMyData :: (a -> b -> (c, d)) -> MyData a b -> MyData c d
mapMyData fn (Leaf x y)      = uncurry Leaf (fn x y)
mapMyData fn (Something n x) = Something n (mapMyData fn x)
mapMyData fn (Pair x1 x2)    = Pair (mapMyData fn x1) (mapMyData fn x2)

sumMyData :: MyData a b -> Int
sumMyData Leaf{}          = 0
sumMyData (Something n x) = n + sumMyData x
sumMyData (Pair x1 x2)    = sumMyData x1 + sumMyData x2
