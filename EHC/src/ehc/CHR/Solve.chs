%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHR solver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Derived from work by Gerrit vd Geest, but greatly adapted to use more efficient searching.

Assumptions (to be documented further)
- The key [Trie.TrieKey Key] used to lookup a constraint in a CHR should be distinguishing enough to be used for the prevention
  of the application of a propagation rule for a 2nd time.

%%[9 module {%{EH}CHR.Solve} import({%{EH}CHR},{%{EH}CHR.Constraint},{%{EH}CHR.Key})
%%]

%%[9 import({%{EH}Base.Common},{%{EH}Base.Trie} as Trie)
%%]

%%[9 import(qualified Data.Set as Set,qualified Data.Map as Map,Data.List as List,Data.Maybe)
%%]

%%[9 import(EH.Util.Pretty as Pretty)
%%]

%%[99 import({%{EH}Base.ForceEval})
%%]

-- For debug
%%[9 import(EH.Util.Utils)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CHR store, with fast search
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9 export(CHRStore,emptyCHRStore)
type CHRKey = [Trie.TrieKey Key]
type UsedByKey = (CHRKey,Int)

data StoredCHR p i g s
  = StoredCHR
      { storedChr       :: !(CHR (Constraint p i) g s)   	-- the CHR
      , storedKeyedInx  :: !Int                          	-- index of constraint for which is keyed into store
      , storedKeys      :: ![Maybe CHRKey]               	-- keys of all constraints; at storedKeyedInx: Nothing
      , storedIdent     :: !UsedByKey                    	-- the identification of a CHR, used for propagation rules (see remark at begin)
      }

storedSimpSz :: StoredCHR p i g s -> Int
storedSimpSz = chrSimpSz . storedChr

data CHRStore pred info guard subst
  = CHRStore
      { chrstoreTrie    :: Trie.Trie Key [StoredCHR pred info guard subst]
      }

mkCHRStore trie = CHRStore trie

emptyCHRStore :: CHRStore pred info guard subst
emptyCHRStore = mkCHRStore Trie.empty
%%]

%%[9
cmbStoredCHRs :: [StoredCHR p i g s] -> [StoredCHR p i g s] -> [StoredCHR p i g s]
cmbStoredCHRs s1 s2
  = map (\s@(StoredCHR {storedIdent=(k,nr)}) -> s {storedIdent = (k,nr+l)}) s1 ++ s2
  where l = length s2
%%]

%%[9
instance Show (StoredCHR p i g s) where
  show _ = "StoredCHR"

ppStoredCHR :: (PP p, PP i, PP g) => StoredCHR p i g s -> PP_Doc
ppStoredCHR c@(StoredCHR {storedIdent=(idKey,idSeqNr)})
  = storedChr c
    >-< indent 2
          (ppParensCommas
            [ pp $ storedKeyedInx c
            , pp $ storedSimpSz c
            , "keys" >#< (ppBracketsCommas $ map (maybe (pp "?") ppTrieKey) $ storedKeys c)
            , "ident" >#< ppParensCommas [ppTrieKey idKey,pp idSeqNr]
            ])

instance (PP p, PP i, PP g) => PP (StoredCHR p i g s) where
  pp = ppStoredCHR
%%]

%%[9 export(chrStoreFromElems,chrStoreUnion,chrStoreUnions,chrStoreSingletonElem)
chrStoreFromElems :: Keyable p => [CHR (Constraint p i) g s] -> CHRStore p i g s
chrStoreFromElems chrs
  = mkCHRStore
    $ Trie.fromListByKeyWith cmbStoredCHRs
        [ (k,[StoredCHR chr i ks' (concat ks,0)])
        | chr <- chrs
        , let cs = chrHead chr
              simpSz = chrSimpSz chr
              ks = map toKey cs
        , (c,k,i) <- zip3 cs ks [0..]
        , let (ks1,(_:ks2)) = splitAt i ks
              ks' = map Just ks1 ++ [Nothing] ++ map Just ks2
        ]

chrStoreSingletonElem :: Keyable p => CHR (Constraint p i) g s -> CHRStore p i g s
chrStoreSingletonElem x = chrStoreFromElems [x]

chrStoreUnion :: CHRStore p i g s -> CHRStore p i g s -> CHRStore p i g s
chrStoreUnion cs1 cs2 = mkCHRStore $ Trie.unionWith cmbStoredCHRs (chrstoreTrie cs1) (chrstoreTrie cs2)

chrStoreUnions :: [CHRStore p i g s] -> CHRStore p i g s
chrStoreUnions []  = emptyCHRStore
chrStoreUnions [s] = s
chrStoreUnions ss  = foldr1 chrStoreUnion ss
%%]

%%[9 export(chrStoreToList,chrStoreElems)
chrStoreToList :: CHRStore p i g s -> [(CHRKey,[CHR (Constraint p i) g s])]
chrStoreToList cs
  = [ (k,chrs)
    | (k,e) <- Trie.toListByKey $ chrstoreTrie cs
    , let chrs = [chr | (StoredCHR {storedChr = chr, storedKeyedInx = 0}) <- e]
    , not $ Prelude.null chrs
    ]

chrStoreElems :: CHRStore p i g s -> [CHR (Constraint p i) g s]
chrStoreElems = concatMap snd . chrStoreToList
%%]

%%[9 export(ppCHRStore,ppCHRStore')
ppCHRStore :: (PP p,PP g,PP i) => CHRStore p i g s -> PP_Doc
ppCHRStore = ppCurlysCommasBlock . map (\(k,v) -> ppTrieKey k >-< indent 2 (":" >#< ppBracketsCommasV v)) . chrStoreToList

ppCHRStore' :: (PP p,PP g,PP i) => CHRStore p i g s -> PP_Doc
ppCHRStore' = ppCurlysCommasBlock . map (\(k,v) -> ppTrieKey k >-< indent 2 (":" >#< ppBracketsCommasV v)) . Trie.toListByKey . chrstoreTrie
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Solver worklist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9
type WorkKey = CHRKey
-- type WorkUsedInMap = Map.Map CHRKey (Set.Set UsedByKey)
type WorkUsedInMap = Map.Map (Set.Set CHRKey) (Set.Set UsedByKey)

data Work p i
  = Work
      { workCnstr   :: !(Constraint p i)           -- the constraint to be reduced
      -- , workUsedIn  :: Set.Set WorkKey          -- marked with the propagation rules already applied to it
      }

data WorkList p i
  = WorkList
      { wlTrie      :: !(Trie.Trie Key (Work p i))
      , wlDoneSet   :: !(Set.Set WorkKey)                  -- accumulative store of all keys added, set semantics, thereby avoiding double entry
      , wlQueue     :: ![WorkKey]
      , wlScanned   :: ![WorkKey]                        -- tried but could not solve, so retry when other succeeds
      , wlUsedIn    :: !WorkUsedInMap                    -- which work items are used in which propagation constraints
      }

emptyWorkList = WorkList Trie.empty Set.empty [] {- Set.empty -} [] Map.empty
%%]

%%[9
wlUsedInUnion :: WorkUsedInMap -> WorkUsedInMap -> WorkUsedInMap
wlUsedInUnion = Map.unionWith Set.union
%%]

%%[9
instance Show (Work p i) where
  show _ = "SolveWork"

instance (PP p,PP i) => PP (Work p i) where
  pp w = pp $ workCnstr w

ppUsedByKey :: UsedByKey -> PP_Doc
ppUsedByKey (k,i) = ppTrieKey k >|< "/" >|< i
%%]

%%[9
mkWorkList :: Keyable p => [Constraint p i] -> WorkList p i
mkWorkList = flip wlInsert emptyWorkList

wlToList :: {- (PP p, PP i) => -} WorkList p i -> [Constraint p i]
wlToList wl = map workCnstr $ Trie.elems $ wlTrie wl

wlCnstrToIns :: Keyable p => WorkList p i -> [Constraint p i] -> AssocL WorkKey (Constraint p i)
wlCnstrToIns wl@(WorkList {wlDoneSet = ds}) inscs
  = [(toKey c,c) | c <- inscs, let k = toKey c, not (k `Set.member` ds)]

wlDeleteByKeyAndInsert' :: [WorkKey] -> AssocL WorkKey (Constraint p i) -> WorkList p i -> WorkList p i
wlDeleteByKeyAndInsert' delkeys inskeycs wl@(WorkList {wlQueue = wlq, wlTrie = wlt, wlDoneSet = ds})
  = wl { wlQueue   = Map.keys inswork ++ (wlq \\ delkeys)
       , wlTrie    = instrie `Trie.union` Trie.deleteListByKey delkeys wlt
       , wlDoneSet = Map.keysSet inswork `Set.union` ds
       }
  where inswork = Map.fromList [ (k,Work c) | (k,c) <- inskeycs ]
        instrie = Trie.fromListPartialByKeyWith TrieLookup_Normal const $ Map.toList inswork

wlDeleteByKeyAndInsert :: Keyable p => [WorkKey] -> [Constraint p i] -> WorkList p i -> WorkList p i
wlDeleteByKeyAndInsert delkeys inscs wl
  = wlDeleteByKeyAndInsert' delkeys (wlCnstrToIns wl inscs) wl

wlInsert :: Keyable p => [Constraint p i] -> WorkList p i -> WorkList p i
wlInsert = wlDeleteByKeyAndInsert []
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Solver trace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9 export(SolveStep(..),SolveTrace)
data SolveStep p i g s
  = SolveStep
      { stepChr     	:: CHR (Constraint p i) g s
      , stepSubst   	:: s
      , stepNewTodo 	:: [Constraint p i]
      , stepNewDone 	:: [Constraint p i]
      }
  | SolveStats
      { stepStats    	:: Map.Map String PP_Doc
      }
  | SolveDbg
      { stepPP      	:: PP_Doc
      }

type SolveTrace p i g s = [SolveStep p i g s]
%%]

%%[9
type SolveCount a b = Map.Map a (Map.Map b Int)

scntUnion :: (Ord a,Ord b) => SolveCount a b -> SolveCount a b -> SolveCount a b
scntUnion = Map.unionWith (Map.unionWith (+))

scntInc :: (Ord a,Ord b) => a -> b -> SolveCount a b -> SolveCount a b
scntInc a b c1
  = Map.singleton a (Map.singleton b 1) `scntUnion` c1
%%]

%%[9
-- type SolveMatchCache p i g s = Map.Map CHRKey [((StoredCHR p i g s,([WorkKey],[Work p i])),s)]
type SolveMatchCache p i g s = Map.Map WorkKey [((StoredCHR p i g s,([WorkKey],[Work p i])),s)]
%%]

%%[9 export(SolveState,emptySolveState)
data SolveState p i g s
  = SolveState
      { stWorkList      :: !(WorkList p i)
      , stDoneCnstrSet  :: !(Set.Set (Constraint p i))
      , stTrace         :: SolveTrace p i g s
      , stCountCnstr	:: SolveCount WorkKey String
      , stMatchCache	:: !(SolveMatchCache p i g s)
      }

stDoneCnstrs :: SolveState p i g s -> [Constraint p i]
stDoneCnstrs = Set.toList . stDoneCnstrSet

emptySolveState :: SolveState p i g s
emptySolveState = SolveState emptyWorkList Set.empty [] Map.empty Map.empty
%%]

%%[9 export(solveStateResetDone)
solveStateResetDone :: SolveState p i g s -> SolveState p i g s
solveStateResetDone s = s {stDoneCnstrSet = Set.empty}
%%]

%%[9
instance Show (SolveStep p i g s) where
  show _ = "SolveStep"

instance (PP p, PP i, PP g) => PP (SolveStep p i g s) where
  pp (SolveStep   step _ todo done) = "STEP" >#< (step >-< "new todo:" >#< ppBracketsCommas todo >-< "new done:" >#< ppBracketsCommas done)
  pp (SolveStats  stats           ) = "STATS"  >#< (ppAssocLV (Map.toList stats))
  pp (SolveDbg    p               ) = "DBG"  >#< p
%%]

%%[9 export(chrSolveStateDoneConstraints,chrSolveStateTrace)
chrSolveStateDoneConstraints :: SolveState p i g s -> [Constraint p i]
chrSolveStateDoneConstraints = stDoneCnstrs

chrSolveStateTrace :: SolveState p i g s -> SolveTrace p i g s
chrSolveStateTrace = stTrace
%%]

%%[9 export(ppSolveTrace)
ppSolveTrace :: (PP s, PP p, PP i, PP g) => SolveTrace p i g s -> PP_Doc
ppSolveTrace tr = ppBracketsCommasV [ pp st | st <- tr ]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Solver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9 export(chrSolve,chrSolve',chrSolve'')
chrSolve
  :: ( CHRMatchable env p s, CHRCheckable env g s
     , CHRSubstitutable s tvar s, CHRSubstitutable g tvar s, CHRSubstitutable i tvar s, CHRSubstitutable p tvar s
     , CHREmptySubstitution s
     , Ord (Constraint p i)
     , PP g, PP i, PP p -- for debugging
     ) => env -> CHRStore p i g s -> [Constraint p i] -> [Constraint p i]
chrSolve env chrStore cnstrs
  = work ++ done
  where (work,done,_) = chrSolve' env chrStore cnstrs

chrSolve'
  :: ( CHRMatchable env p s, CHRCheckable env g s
     , CHRSubstitutable s tvar s, CHRSubstitutable g tvar s, CHRSubstitutable i tvar s, CHRSubstitutable p tvar s
     , CHREmptySubstitution s
     , Ord (Constraint p i)
     , PP g, PP i, PP p -- for debugging
     ) => env -> CHRStore p i g s -> [Constraint p i] -> ([Constraint p i],[Constraint p i],SolveTrace p i g s)
chrSolve' env chrStore cnstrs
  = (wlToList (stWorkList finalState), stDoneCnstrs finalState, stTrace finalState)
  where finalState = chrSolve'' env chrStore cnstrs emptySolveState

chrSolve''
  :: ( CHRMatchable env p s, CHRCheckable env g s
     , CHRSubstitutable s tvar s, CHRSubstitutable g tvar s, CHRSubstitutable i tvar s, CHRSubstitutable p tvar s
     , CHREmptySubstitution s
     , Ord (Constraint p i)
     , PP g, PP i, PP p -- for debugging
     ) => env -> CHRStore p i g s -> [Constraint p i] -> SolveState p i g s -> SolveState p i g s
chrSolve'' env chrStore cnstrs prevState
  = postState {stMatchCache = Map.empty}
  where postState
          = addStats Map.empty [("workMatches",ppAssocLV [(k,pp (fromJust l)) | (k,c) <- Map.toList $ stCountCnstr st, let l = Map.lookup "workMatched" c, isJust l])] st
          where st = iter $ initState prevState
        iter st@(SolveState {stWorkList = wl@(WorkList {wlQueue = (workHd:workTl)})})
          = case matches of
              (_:_)
                -> expandMatch
                       (addStats Map.empty
                            [ ("(0) yes work", pp workHd)
                            ] stmatch)
                       matches
                where expandMatch st@(SolveState {stWorkList = wl})
                                  ( ( ( schr@(StoredCHR {storedIdent = chrId, storedChr = chr@(CHR {chrBody = b, chrSimpSz = simpSz})})
                                      , (keys,works)
                                      )
                                    , subst
                                    ) : tlMatch
                                  )
                        = expandMatch (addStats Map.empty [ ("chr",pp chr')
                                                          , ("leftover sz", pp (length tlMatchY))
                                                          , ("filtered out sz", pp (length tlMatchN))
                                                          , ("new done sz", pp (length bDone))
                                                          , ("new todo sz", pp (length bTodo))
                                                          , ("wl queue sz", pp (length (wlQueue wl')))
                                                          , ("wl usedin sz", pp (Map.size (wlUsedIn wl')))
                                                          , ("done sz", pp (Set.size (stDoneCnstrSet st')))
                                                          ]
                                                st')
                                      tlMatchY
                        where (tlMatchY,tlMatchN) = partition (\(r@(_,(ks,_)),_) -> not (any (`elem` keysSimp) ks || isUsedByPropPart (wlUsedIn wl') r)) tlMatch
                              (keysSimp,keysProp) = splitAt simpSz keys
                              usedIn              = Map.singleton (Set.fromList keysProp) (Set.singleton chrId)
                              (bTodo,bDone)       = splitDone $ map (chrAppSubst subst) b
                              bTodo'              = wlCnstrToIns wl bTodo
                              wl' = wlDeleteByKeyAndInsert' keysSimp bTodo'
                                    $ wl { wlUsedIn  = usedIn `wlUsedInUnion` wlUsedIn wl
                                         , wlScanned = []
                                         , wlQueue   = wlQueue wl ++ wlScanned wl
                                         }
                              chr'= subst `chrAppSubst` chr
                              st' = st { stWorkList     = wl'
%%[[9
                                       , stTrace        = SolveStep chr' subst (assocLElts bTodo') bDone : {- SolveDbg (ppwork >-< ppdbg) : -} stTrace st
%%][100
%%]]
                                       , stDoneCnstrSet = Set.unions [Set.fromList bDone, Set.fromList $ map workCnstr $ take simpSz works, stDoneCnstrSet st]
                                       , stMatchCache   = if List.null bTodo' then stMatchCache st else Map.empty
                                       }
%%[[9
                              ppwork = "workkey" >#< ppTrieKey workHd >#< ":" >#< (ppBracketsCommas (map ppTrieKey workTl) >-< ppBracketsCommas (map ppTrieKey $ wlScanned wl))
                                         >-< "workkeys" >#< ppBracketsCommas (map ppTrieKey keys)
                                         >-< "worktrie" >#< wlTrie wl
                                         >-< "schr" >#< schr
                                         >-< "usedin" >#< (ppBracketsCommasV $ map (\(k,s) -> ppKs k >#< ppBracketsCommas (map ppUsedByKey $ Set.toList s)) $ Map.toList $ wlUsedIn wl)
                                         >-< "usedin'" >#< (ppBracketsCommasV $ map (\(k,s) -> ppKs k >#< ppBracketsCommas (map ppUsedByKey $ Set.toList s)) $ Map.toList $ wlUsedIn wl')
                                     where ppKs ks = ppBracketsCommas $ map ppTrieKey $ Set.toList ks
%%][100
%%]]
                      expandMatch st _ 
                        = iter st
                      
              _ -> iter (addStats Map.empty
                             [ ("no match work", pp workHd)
                             ] st')
                where wl' = wl { wlScanned = workHd : wlScanned wl, wlQueue = workTl }
                      st' = stmatch { stWorkList = wl', stTrace = {- SolveDbg (ppdbg) : -} stTrace stmatch }
          where (matches,ppdbg,stats) = workMatches st
                stmatch = addStats stats [("(a) workHd", pp workHd), ("(b) matches", ppBracketsCommasV [ s `chrAppSubst` storedChr schr | ((schr,_),s) <- matches ])]
                            (st { stCountCnstr = scntInc workHd "workMatched" $ stCountCnstr st
                                , stMatchCache = Map.insert workHd [] (stMatchCache st)
                                })
        iter st
          = st
        mkStats  stats new    = stats `Map.union` Map.fromList (assocLMapKey showPP new)
%%[[9
        addStats stats new st = st { stTrace = SolveStats (mkStats stats new) : stTrace st }
%%][100
        addStats _     _   st = st
%%]]
        workMatches st@(SolveState {stWorkList = WorkList {wlQueue = (workHd:_), wlTrie = wlTrie, wlUsedIn = wlUsedIn}})
          | isJust mbInCache  = ( fromJust mbInCache, Pretty.empty, mkStats Map.empty [("in cache sz",pp (length (fromJust mbInCache))),("cache sz",pp (Map.size (stMatchCache st)))] )
          | otherwise         = ( r5
%%[[9
                                , pp2 >-< pp2b >-< pp2c >-< pp3
                                , mkStats Map.empty [("(1) lookup sz",pp (length r2)), ("(2) cand sz",pp (length r3)), ("(3) unused cand sz",pp (length r4)), ("(4) final cand sz",pp (length r5))]
%%][100
                                , Pretty.empty
                                , Map.empty
%%]]
                                )
          where -- cache result
                mbInCache = Map.lookup workHd (stMatchCache st)
                -- results
                r2 = concat $ lookupResultToList $ lookupPartialByKey TrieLookup_Partial workHd $ chrstoreTrie chrStore
                r3 = concatMap (\c -> zip (repeat c) (map unzip $ combineToDistinguishedElts $ candidate c)) $ r2
                r4 = filter (not . isUsedByPropPart wlUsedIn) r3
                r5 = mapMaybe (\r@(chr,kw@(_,works)) -> fmap (\s -> (r,s)) $ match chr (map workCnstr works)) r4
%%[[9
                pp2  = "lookups"    >#< ("for" >#< ppTrieKey workHd >-< ppBracketsCommasV r2)
                pp2b = "cand1"      >#< (ppBracketsCommasV $ map (ppBracketsCommasV . map (ppBracketsCommasV . map (\(k,w) -> ppTrieKey k >#< w)) . candidate) r2)
                pp2c = "cand2"      >#< (ppBracketsCommasV $ map (ppBracketsCommasV . map (ppBracketsCommasV) . combineToDistinguishedElts . candidate) r2)
                pp3  = "candidates" >#< (ppBracketsCommasV $ map (\(chr,(ks,ws)) -> "chr" >#< chr >-< "keys" >#< ppBracketsCommas (map ppTrieKey ks) >-< "works" >#< ppBracketsCommasV ws) $ r3)
%%][100
%%]]
                -- util functions
                candidate (StoredCHR {storedIdent = chrId, storedKeys = ks, storedChr = chr@(CHR {chrSimpSz = simpSz})})
                  = cand lkup sks ++ cand (\h k -> lkup h k) pks
                  where (sks,pks)   = splitAt simpSz ks
                        lkup how k  = lookupResultToList $ lookupPartialByKey' (,) how k wlTrie
                        cand lkup   = map (maybe (lkup TrieLookup_Normal workHd) (lkup TrieLookup_StopAtPartial))
                match chr cnstrs
                  = foldl cmb (Just chrEmptySubst) $ matches chr cnstrs ++ checks chr
                  where matches (StoredCHR {storedChr = CHR {chrHead = hc}}) cnstrs
                          = zipWith mt hc cnstrs
                          where mt cFr cTo subst = chrMatchTo env subst cFr cTo
                        checks (StoredCHR {storedChr = CHR {chrGuard = gd}})
                          = map chk gd
                          where chk g subst = chrCheck env subst g
                        cmb (Just s) next = fmap (`chrAppSubst` s) $ next s
                        cmb _        _    = Nothing
        isUsedByPropPart wlUsedIn (chr,(keys,_))
          = fnd $ drop (storedSimpSz chr) keys
          where fnd k = maybe False (storedIdent chr `Set.member`) $ Map.lookup (Set.fromList k) wlUsedIn
        initState st = st { stWorkList = wlInsert wlnew $ stWorkList st, stDoneCnstrSet = Set.unions [Set.fromList done, stDoneCnstrSet st] }
                     where (wlnew,done) = splitDone cnstrs
        splitDone  = partition cnstrRequiresSolve
%%]
        isUsedByPropPart wlUsedIn (chr,(keys,_))
          = all fnd $ drop (storedSimpSz chr) keys
          where fnd k = maybe False (storedIdent chr `Set.member`) $ Map.lookup k wlUsedIn

                -> iter {- $ trp "YY" ("chr" >#< schr >-< ppwork) $ -} st'
                r4 = foldr first Nothing $ r3
                -- r5 = foldr first Nothing r4
                -> iter $ trp "PICK" (schr >-< "HD:" >#< ppTrieKey workHd >-< "TL:" >#< ppBracketsCommas (map ppTrieKey workTl) >-< "KEYS:" >#< ppBracketsCommas (map ppTrieKey keys) >-< "WORKS:" >#< ppBracketsCommasV works) $ st'
              _ -> iter $ trp "NOT MATCHED" (ppTrieKey workHd) $ st'
                  = (\v -> trp "ZZ" ("workHd" >#< ppBracketsCommas workHd >#< "ks" >#< (ppBracketsCommas $ map (fmap ppBracketsCommas) ks) >#< (ppBracketsCommasV $ map (map (\(a,b) -> ppParensCommas [ppBracketsCommas a,pp b])) $ v)) v)
            -- $ filter (not . isUsedByPropPart)
            -- $ (\v -> trp "XX" (ppBracketsCommasV v) v)

                isUsedByPropPart (chr,(keys,_))
                  = any fnd $ drop (storedSimpSz chr) keys
                  where fnd k = maybe False (storedIdent chr `Set.member`) $ Map.lookup k wlUsedIn

                first (chr,kw@(_,works)) cont
                  = case match chr (map workCnstr works) of
                      r@(Just s) -> Just (chr,kw,s)
                      _          -> cont

                match chr cnstrs
                  = foldl cmb (Just chrEmptySubst) $ matches chr cnstrs ++ checks chr
                  where matches (StoredCHR {storedChr = CHR {chrHead = hc}}) cnstrs
                          = zipWith mt hc cnstrs
                          where mt cFr cTo subst = chrMatchTo env subst (subst `chrAppSubst` cFr) cTo
                        checks (StoredCHR {storedChr = CHR {chrGuard = gd}})
                          = map chk gd
                          where chk g subst = chrCheck subst (subst `chrAppSubst` g)
                        cmb (Just s) next = fmap (`chrAppSubst` s) $ next s
                        cmb _        _    = Nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ForceEval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99
instance ForceEval (CHR (Constraint p i) g s) => ForceEval (StoredCHR p i g s) where
  forceEval x@(StoredCHR c i ks id) | forceEval c `seq` forceEval ks `seq` forceEval id `seq` True = x
%%[[101
  fevCount (StoredCHR c i ks id) = cm1 "StoredCHR" `cmUnion` fevCount c `cmUnion` fevCount i `cmUnion` fevCount ks `cmUnion` fevCount id
%%]]

instance ForceEval (StoredCHR p i g s) => ForceEval (CHRStore p i g s) where
  forceEval x@(CHRStore t) | forceEval t `seq` True = x
%%[[101
  fevCount (CHRStore t) = cm1 "CHRStore" `cmUnion` fevCount t
%%]]
%%]
