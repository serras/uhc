{- ----------------------------------------------------------------------------------------
   what    : IO
   expected: ok, copy output of file
   constraints: exclude-if-js
---------------------------------------------------------------------------------------- -}


module Main where

main :: IO ()
main
  = do h1 <- openFile "filesForIOTesting/file1" ReadMode
       l1 <- hGetLine h1
       l2 <- hGetLine h1
       hPutStrLn stdout l1
       hPutStrLn stdout l2
       hFlush stdout -- [@@@] bug with flushing stdout. remove after fix
       hClose h1
