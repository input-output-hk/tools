{-# OPTIONS_GHC -fplugin Example #-}

module Main where

import Lib

main :: IO ()
main = print $ t x y

t :: Int -> Int -> Bool
t a b = g (f a + b)
