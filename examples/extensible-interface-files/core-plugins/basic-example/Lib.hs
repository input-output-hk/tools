{-# OPTIONS_GHC -fplugin Example #-}

module Lib where

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

xs :: [()]
xs = ():xs

g :: Int -> Bool
g 0 = True
g _ = False

