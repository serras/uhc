let  f1 :: (a->a) -> Int
     f2 = \h -> let  v1 = f3 h
                     v2 = h 3
                     v3 = h 'x'
                in   v2
     f3 = \j -> let  w1 = j 3
                     w2 = j 'x'
                     w3 = f2 j
                in   w1
in   3
