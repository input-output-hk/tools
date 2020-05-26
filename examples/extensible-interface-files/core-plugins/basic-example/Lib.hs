{-# OPTIONS_GHC -fwrite-core-field #-}

module Lib where


x, y :: Int
x = 1
y = x + 2

f = plus 1
  where
    plus = (+)

xs = ():xs

g :: Int -> Bool
g 0 = True
g _ = False

