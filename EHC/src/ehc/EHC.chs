%%[0
%include lhs2TeX.fmt
%include afp.fmt
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 module Main
%%]

%%[1 import(System.Console.GetOpt, System.IO, System.Exit, System.Process, System.Environment)
%%]
%%[99 import(System.Directory)
%%]
%%[1.fastseq import(qualified UHC.Util.FastSeq as Seq)
%%]
%%[1 import(qualified {%{EH}Config} as Cfg)
%%]
%%[50 import(qualified {%{EH}SourceCodeSig} as Sig)
%%]
%%[1 import({%{EH}EHC.Common})
%%]
%%[8 import({%{EH}EHC.Environment})
%%]

%%[8 -1.fastseq
%%]

-- HS semantics
%%[1.HSSem import(qualified {%{EH}HS.MainAG} as HSSem)
%%]
-- EH semantics
%%[1.EHSem import(qualified {%{EH}EH.MainAG} as EHSem)
%%]

-- parsing later put in {%{EH}EHC.CompilePhase.Parsers}
%%[1.scannercommon import({%{EH}Scanner.Common})
%%]
%%[1.parsinglib import(UU.Parsing, UU.Parsing.Offside)
%%]
%%[1.parse.EHPrs.HSPrs import(qualified {%{EH}EH.Parser} as EHPrs, qualified {%{EH}HS.Parser} as HSPrs)
%%]

%%[8 -(1.scannercommon 1.parsinglib 1.parse.EHPrs.HSPrs 1.EHSem 1.HSSem)
%%]

-- compiler driver modules
%%[8 import({%{EH}EHC.CompileUnit},{%{EH}EHC.CompileRun})
%%]
%%[8 import({%{EH}EHC.InitialSetup})
%%]
%%[8 import({%{EH}EHC.CompilePhase.TopLevelPhases})
%%]
%%[50 import({%{EH}EHC.CompilePhase.Module})
%%]

-- general imports
%%[8 import(qualified Debug.Trace)
%%]
%%[8 import(qualified Data.Map as Map, qualified Data.Set as Set)
%%]
%%[8 import(Control.Monad.State)
%%]

-- module
%%[50 import({%{EH}Module.ImportExport}(modBuiltin), {%{EH}Module.ImportExport})
%%]

-- packages
%%[99 import({%{EH}Base.PackageDatabase},{%{EH}Base.Parser2})
%%]

-- Misc
%%[8 import({%{EH}Base.Target}, {%{EH}Base.Optimize}(allOptimizeMp))
%%]
%%[(102 codegen) import({%{EH}Core.Trf.Strip})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Main, compiling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1.main
main :: IO ()
main
  =  do  {  args      <- getArgs
         ;  progName  <- getProgName
%%[[99
         ;  curDir  <- getCurrentDirectory
%%]]
         ;  let  opts1          = defaultEHCOpts
%%[[8
                                    { ehcOptEnvironment     = defaultEHCEnvironment
%%[[99
                                    , ehcProgName           = p
                                    , ehcCurDir             = curDir
%%]]
                                    }
%%]]
%%[[99
                                where p = mkFPath progName
%%][101
                                where p = mkFPath "uhc"     -- hardbaked name
%%]]
                 oo@(o,n,errs)  = ehcCmdLineOptsApply args opts1
                 opts2          = maybe opts1 id o
%%[[(8 codegen)
         ;  case opts2 of
              o | isNotOk (ehcOptMbTarget       o) -> err $ "non existent target `"        ++ fromNotOk (ehcOptMbTarget       o) ++ "'"
                | isNotOk (ehcOptMbTargetFlavor o) -> err $ "non existent target flavor `" ++ fromNotOk (ehcOptMbTargetFlavor o) ++ "'"
                where err x
                        = do { hPutStrLn stderr ("option error: " ++ x)
                             ; exitFailure
                             }
              _ -> return ()
%%]]
%%[[1
         ;  let opts3 = opts2
%%][99
         ;  userDir <- ehcenvDir (envkey opts2)
         ;  let opts3 = opts2 { ehcOptUserDir = userDir
                              , ehcOptOutputDir =
                                  let outputDir = maybe "." id (ehcOptOutputDir opts2)
                                  in  case ehcOptPkgOpt opts2 of
                                        Just (PkgOption {pkgoptName=s})
                                          -> case parsePkgKey s of
                                               Just k  -> Just $
                                                          outputDir ++ "/" ++
                                                          mkInternalPkgFileBase k (Cfg.installVariant opts2)
                                                                                (ehcOptTarget opts2) (ehcOptTargetFlavor opts2)
                                               _       -> ehcOptOutputDir opts2
                                        _ -> ehcOptOutputDir opts2
                              }
%%]]
         ;  case ehcOptImmQuit opts3 of
              Just immq     -> handleImmQuitOption immq opts3
              _ | null errs ->
%%[[1
                               doCompileRun (if null n then "" else head n) opts3
%%][8
                               unless (null n) (doCompileRun n opts3)
%%][9999
                               do { mbEnv <- importEHCEnvironment (envkey opts3)
                                  ; let opts4 = opts3 -- maybe opts3 (\e -> opts3 {ehcOptEnvironment = e}) mbEnv
                                  -- ; putStrLn (show mbEnv)
                                  ; unless (null n) (doCompileRun n opts3)
                                  }
%%]]
                | otherwise -> do { putStr (head errs)
                                  ; exitFailure
                                  }
         }
%%[[99
  where envkey opts = mkEhcenvKey (Cfg.verFull Cfg.version) (fpathToStr $ ehcProgName opts) Cfg.ehcDefaultVariant
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Default EHC Environment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
defaultEHCEnvironment :: EHCEnvironment
defaultEHCEnvironment
  = EHCEnvironment Cfg.ehcDefaultVariant Cfg.ehcDefaultInplaceInstallDir
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Handling of immediate quit options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1
handleImmQuitOption :: ImmediateQuitOption -> EHCOpts -> IO ()
handleImmQuitOption immq opts
  = case immq of
      ImmediateQuitOption_Help
        -> do {
%%[[1
                progName  <- getProgName
%%][99
                let progName = fpathToStr (ehcProgName opts)
%%]]
              ; putStrLn (usageInfo (  "version: " ++ Cfg.verInfo Cfg.version ++ ", aspects: " ++ ehcOptAspects opts
                                    ++ "\n\nUsage: " ++ progName ++ " [options] [file[.eh|.hs] ...]\n\noptions:"
                                    )
                                    ehcCmdLineOpts)
%%[[(8 codegen)
              -- ; putStrLn ("Transformations:\n" ++ (unlines . map (\(n,t) -> "  " ++ n ++ ": " ++ t) $ cmdLineTrfs))
%%][100
%%]]
              }
        where
      ImmediateQuitOption_Version
        -> putStrLn $ Cfg.verInfo Cfg.version
%%[[50
                      ++ ", timestamp " ++ Sig.timestamp
%%]]
      ImmediateQuitOption_Meta_Variant
        -> putStrLn Cfg.ehcDefaultVariant
%%[[1
      ImmediateQuitOption_Meta_Targets
        -> putStr ""
      ImmediateQuitOption_Meta_TargetDefault
        -> putStr "no-target"
%%][(8 codegen)
      ImmediateQuitOption_Meta_Targets
        -> putStr showSupportedTargets
      ImmediateQuitOption_Meta_TargetDefault
        -> putStr (show defaultTarget)
      ImmediateQuitOption_Meta_Optimizations
        -> putStr (showStringMapKeys allOptimizeMp " ")
%%]]
%%[[99
      ImmediateQuitOption_VersionDotted
        -> putStrLn (Cfg.verFull Cfg.version)
      ImmediateQuitOption_VersionAsNumber
        -> putStrLn (Cfg.verAsNumber Cfg.version)
{-
      ImmediateQuitOption_Meta_ExportEnv mvEnvOpt
        -> exportEHCEnvironment
             (mkEhcenvKey (Cfg.verFull Cfg.version) (fpathToStr $ ehcProgName opts) Cfg.ehcDefaultVariant)
             (env {ehcenvInstallRoot = installRootDir, ehcenvVariant = variant})
        where env = ehcOptEnvironment opts
              (installRootDir,variant)
                = case fmap (wordsBy (`elem` ",;")) mvEnvOpt of
                    Just (d:v:_) -> (d,v)
                    Just (d:_)   -> (d,ehcenvVariant env)
                    _            -> (ehcenvInstallRoot env,ehcenvVariant env)
      ImmediateQuitOption_Meta_DirEnv
        -> do { d <- ehcenvDir (mkEhcenvKey (Cfg.verFull Cfg.version) (fpathToStr $ ehcProgName opts) Cfg.ehcDefaultVariant)
              ; putStrLn d
              }
-}
      ImmediateQuitOption_Meta_Pkgdir_System
        -> do { let d = Cfg.mkInstallPkgdirSystem opts
              ; putStrLn d
              }
      ImmediateQuitOption_Meta_Pkgdir_User
        -> do { let d = Cfg.mkInstallPkgdirUser opts
              ; putStrLn d
              }
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Suffix search path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Order is significant.

%%[8
type FileSuffMp = [(FileSuffix,EHCompileUnitState)]

mkFileSuffMpHs :: EHCOpts -> FileSuffMp
mkFileSuffMpHs opts
  = [ ( Just "hs"  , ECUS_Haskell HSStart )
%%[[99
    , ( Just "lhs" , ECUS_Haskell LHSStart )
%%]]
    , ( Just "eh"  , ECUS_Eh EHStart )
%%[[50
    , ( Just "hi"  , ECUS_Haskell HIStart )
%%]]
%%[[(8 grin)
    -- currently not supported
    -- , ( Just "grin", ECUS_Grin )
%%]]
%%[[(50 corein)
    , ( Just Cfg.suffixDotlessInputOutputTextualCore, ECUS_Core CRStartText   )
    , ( Just Cfg.suffixDotlessInputOutputBinaryCore , ECUS_Core CRStartBinary )
%%]]
%%[[(50 corebackend)
    , ( Just Cfg.suffixDotlessBinaryCore , ECUS_Core CRStartBinary )
%%]]
    ]
%%[[(90 codegen)
    ++ (if targetIsOnUnixAndOrC (ehcOptTarget opts)
        then [ ( Just "c"   , ECUS_C CStart )
             , ( Just "o"   , ECUS_O OStart )
             ]
        else []
       )
%%]]
%%]

%%[8
-- Suffix map for empty suffix, defaults to .hs
fileSuffMpHsNoSuff :: FileSuffMp
fileSuffMpHsNoSuff
  = [ ( Nothing  , ECUS_Haskell HSStart )
    ]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Show sizes, mem usage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(102 codegen)
showSizeCore :: Core.CModule -> String
showSizeCore x = fevShow "Core" x

%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: compilation of module(s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compiler driver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1.doCompile
doCompileRun :: String -> EHCOpts -> IO ()
doCompileRun filename opts
  =  do  {  (fn,fh) <-  if null filename
                        then  return ("<stdin>",stdin)
                        else  do  {  h <- openFile filename ReadMode
                                  ;  return (filename,h)
                                  }
         ;  let isHS = isSuffixOf ".hs" fn
         ;  when
              (ehcStopAtPoint opts >= CompilePoint_Parse)
              (do { tokens <- offsideScanHandle (if isHS then (hsScanOpts opts) else (ehScanOpts opts)) fn fh
                  ; resd <-
                      if isHS
                      then do { let steps = parseOffside (HSPrs.pAGItf opts) tokens
                              ; (resd,_) <- evalStepsIO show steps
                              ; if ehcStopAtPoint opts >= CompilePoint_AnalHS
                                then do { let res   = HSSem.sem_AGItf resd
                                              wrRes = HSSem.wrap_AGItf res
                                                        (HSSem.Inh_AGItf
                                                          { HSSem.opts_Inh_AGItf = opts
                                                          })
                                        ; putStrLn (disp (ppErrL $ Seq.toList $ HSSem.errSq_Syn_AGItf $ wrRes) 1000 "")
                                        ; when (ehcOptShowHS opts)
                                               (putStrLn (disp (HSSem.pp_Syn_AGItf wrRes) 1000 ""))
                                        ; return (HSSem.eh_Syn_AGItf wrRes)
                                        }
                                else return (panic "EHC.doCompileRun")
                              }
                      else do { let steps = parseOffside (EHPrs.pAGItf) tokens
                              ; (resd,_) <- evalStepsIO show steps
                              ; return resd
                              }
                  ; when
                      (ehcStopAtPoint opts >= CompilePoint_AnalEH)
                      (do { let res   = EHSem.sem_AGItf resd
                                wrRes = EHSem.wrap_AGItf res (EHSem.Inh_AGItf {EHSem.opts_Inh_AGItf = opts})
                          ; when (ehcOptShowEH opts)
                                 (putStrLn (disp (EHSem.pp_Syn_AGItf wrRes) 70 ""))
                          ; when (ehcOptShowAst opts)
                                 (putStrLn (disp (EHSem.ppAST_Syn_AGItf wrRes) 1000 ""))
%%[[(1 hmtyinfer)
                          ; when (ehcOptShowTopTyPP opts)
                                 (putStr (disp (EHSem.topTyPP_Syn_AGItf wrRes) 1000 ""))
%%]]
%%[[7_2
                          ; when (not (null filename) && ehcOptUniqueness opts)
                                 (writeFile (filename ++ ".html") (EHSem.ppHTML_Syn_AGItf wrRes))
%%]]
                          })
                  })
         }
%%]

%%[8.doCompile -1.doCompile
doCompilePrepare :: [String] -> EHCOpts -> IO (Maybe (EHCOpts,[FPath],[HsName],EHCompileRun))
doCompilePrepare fnL@(fn:_) opts
  = do { let fpL@(fp:_)             = map (mkTopLevelFPath "hs") fnL
             topModNmL@(topModNm:_) = map (mkHNm . fpathBase) fpL
%%[[99
             installRoot            = Cfg.installRoot    opts
             installVariant         = Cfg.installVariant opts
       -- ; userDir <- ehcenvDir (Cfg.verFull Cfg.version)
       -- ; let opts2 = opts -- {ehcOptUserDir = userDir}
       ; pkgDb1 <- pkgDbFromDirs opts
                    ({-
                        [ filePathCoalesceSeparator $ filePathUnPrefix
                          $ Cfg.mkDirbasedInstallPrefix (filelocDir d) Cfg.INST_LIB_PKG "" (show (ehcOptTarget opts)) ""
                        | d <- ehcOptPkgdirLocPath opts
                        ]
                     ++ [ filePathUnPrefix
                          $ Cfg.mkDirbasedTargetVariantPkgPrefix installRoot installVariant (show (ehcOptTarget opts)) ""
                        ]
                     -}
                     {-
                     -}
                        [ filePathUnPrefix d
                        | d <- nub $ ehcOptPkgdirLocPath opts ++ [Cfg.mkInstallPkgdirUser opts, Cfg.mkInstallPkgdirSystem opts]
                        ]
                    )
       ; let (pkgDb2,pkgErrs) = pkgDbSelectBySearchFilter (pkgSearchFilter Just PackageSearchFilter_ExposePkg (map tup123to1 $ pkgExposedPackages pkgDb1)
                                                           ++ sort (ehcOptPackageSearchFilter opts)
                                                          ) pkgDb1
             pkgDb3 = pkgDbFreeze pkgDb2
       -- ; putStrLn $ "db1 " ++ show pkgDb1
       -- ; putStrLn $ "db2 " ++ show pkgDb2
       -- ; putStrLn $ "db3 " ++ show pkgDb3
       -- ; putStrLn (show $ ehcOptPackageSearchFilter opts)
%%]]
%%[[99
       ; ehcioinfo <- newEHCIOInfo
%%]]
       ; let searchPath     = [emptyFileLoc]
                              ++ ehcOptImportFileLocPath opts
%%[[99
                              {-
                              ++ [ mkPkgFileLoc (p, Nothing) $ filePathUnPrefix
                                   $ Cfg.mkDirbasedLibVariantTargetPkgPrefix (filelocDir d) "" (show (ehcOptTarget opts)) p
                                 | d <- ehcOptLibFileLocPath opts
                                 , p <- ehcOptLibPackages opts
                                 ]
                              ++ [ mkPkgFileLoc p $ filePathUnPrefix
                                   $ Cfg.mkDirbasedTargetVariantPkgPrefix installRoot installVariant (show (ehcOptTarget opts)) p
                                 | p <- (   ehcOptLibPackages opts
                                         ++ (if ehcOptHideAllPackages opts then [] else Cfg.ehcAssumedPackages)
                                        )
                                 ]
                              -}
                              ++ [fileLocPkgDb]
%%]]
             opts3          = opts { ehcOptImportFileLocPath = searchPath
%%[[99
                                    , ehcOptPkgDb = pkgDb3
%%]]
                                    }
{- this does not work in ghc 6.8.2
             crsi           = emptyEHCompileRunStateInfo
                                { crsiOpts       =   opts3
                                , crsiHSInh      =   initialHSSem opts3
                                , crsiEHInh      =   initialEHSem opts3 fp
%%[[(8 codegen)
                                , crsiCoreInh    =   initialCore2GrSem opts3
%%]]
%%[[50
                                -- , crsiHIInh      =   initialHISem opts3
                                , crsiHSModInh   =   initialHSSemMod opts3
%%]]
                                }
-}
             crsi           =   (EHCompileRunStateInfo opts3
                                                       uidStart uidStart
                                                       (initialHSSem opts3) (initialEHSem opts3 fp)
%%[[(8 codegen)
                                                       (initialCore2GrSem opts3)
%%]]
%%[[50
                                                       Nothing
                                                       -- (initialHISem opts3)
                                                       (initialHSSemMod opts3)
                                                       Map.empty Map.empty defaultOptim
%%]]
%%[[(50 codegen)
                                                       Map.empty
%%]]
%%[[99
                                                       ehcioinfo []
%%]]
                                )
             initialState   = mkEmptyCompileRun topModNm crsi
       ; return $ Just (opts3,fpL,topModNmL,initialState)
       }

doCompileRun :: [String] -> EHCOpts -> IO ()
doCompileRun fnL@(fn:_) opts
  = do { mbPrep <- doCompilePrepare fnL opts
       ; if isJust mbPrep
         then do { let ( opts
                        , fpL@(fp:_)
                        , topModNmL@(topModNm:_)
                        , initialState
                        ) = fromJust mbPrep
                       searchPath = ehcOptImportFileLocPath opts
                       fileSuffMpHs = mkFileSuffMpHs opts
                 ; when (ehcOptVerbosity opts >= VerboseDebug)
                        (putStrLn $ "search path: " ++ show searchPath)
%%[[8
                 ; _ <- runStateT (compile opts fileSuffMpHs searchPath (Just fp) topModNm) initialState
%%][50
                 ; _ <- if False -- ehcOptPriv opts
                        then runStateT (compile2 opts fileSuffMpHs searchPath fpL topModNmL) initialState
                        else runStateT (compile opts fileSuffMpHs searchPath fpL topModNmL) initialState
%%]]
                 ; return ()
                 }
         else exitFailure
       }
%%[[8
  where compile :: EHCOpts -> FileSuffMp -> FileLocPath -> Maybe FPath -> HsName -> EHCompilePhase ()
        compile opts fileSuffMpHs searchPath mbFp nm
          = do { mbFoundFp <- cpFindFileForFPath fileSuffMpHs searchPath (Just nm) mbFp
               ; when (isJust mbFoundFp)
                      (cpEhcModuleCompile1 nm)
               }
%%][50
  where compile2 :: EHCOpts -> FileSuffMp -> FileLocPath -> [FPath] -> [HsName] -> EHCompilePhase ()
        compile2 opts fileSuffMpHs searchPath fpL topModNmL
          = do { 
               -- start with directly importing top modules, providing the filepath directly
                 topModNmL' <- toplayer fpL topModNmL
               ; cpPP "topModNmL'"
               ; oneModNmL <- onelayer
               ; cpPP "oneModNmL"
               ; return ()
               }
          where toplayer fpL topModNmL
                  = zipWithM (\fp topModNm -> imp1 opts fileSuffMpHs searchPath (ECUS_Haskell HSOnlyImports) (Just fp) Nothing topModNm) fpL topModNmL
                onelayer
                  = do { cr <- get
                       ; let modNmS = Map.keysSet $ crCUCache cr
                             ms = Set.unions
                                    [ case cuState e of
                                        -- ECUS_Haskell HIOnlyImports -> ecuTransClosedOrphanModS ecu
                                        _                         -> ecuImpNmS e
                                    | m <- Set.toList modNmS, let e = crCU m cr
                                    ]
                                  `Set.difference` modNmS
                       ; sequence -- or: cpSeq + return ()
                           [ do { i@(m',_) <- imp1 opts fileSuffMpHs searchPath (ECUS_Haskell HSOnlyImports) Nothing Nothing m
                                -- ; cpEhcFullProgModuleDetermineNeedsCompile m'
                                ; return i
                                }
                           | m <- Set.toList ms
                           ]
                       }
                
                -- dbg
                {-
                showCompileOrder
                  = do { cr <- get
                       ; lift $ putStrLn $ "compile order: " ++ show (crCompileOrder cr)
                       }
                -}
               
        compile :: EHCOpts -> FileSuffMp -> FileLocPath -> [FPath] -> [HsName] -> EHCompilePhase ()
        compile opts fileSuffMpHs searchPath fpL topModNmL
          = do { 
               -- check module import relationship for builtin module
                 cpCheckMods' (const emptyModMpInfo) [modBuiltin]
               
               -- start with directly importing top modules, providing the filepath directly
               ; topModNmL' <- zipWithM (\fp topModNm -> imp (ECUS_Haskell HSOnlyImports) (Just fp) Nothing topModNm) fpL topModNmL
               
               -- follow the import relation to chase modules which have to be analysed
               ; cpImportGatherFromModsWithImp
                   (if ehcOptPriv opts
                    then \ecu -> case ecuState ecu of
                                   -- ECUS_Haskell HIStart -> Set.toList $ ecuTransClosedOrphanModS ecu
                                   ECUS_Haskell HIOnlyImports -> [] -- Set.toList $ ecuTransClosedOrphanModS ecu
                                   _ -> ecuImpNmL ecu
                    else ecuImpNmL
                   )
                   (imp (ECUS_Haskell HSOnlyImports) Nothing) (map fst topModNmL')
               
               -- import orphans
               ; when (ehcOptPriv opts)
                      (do { 
                          -- import orphans
                            importAlso (ECUS_Haskell HSOnlyImports) ecuTransClosedOrphanModS
                          
                          -- import used remaining modules, but just minimally                          
                          ; importAlso (ECUS_Haskell HMOnlyMinimal) (Set.unions . Map.elems . ecuTransClosedUsedModMp)
                          })

               -- inhibit mutual recursiveness
               ; cpEhcCheckAbsenceOfMutRecModules
               
               -- and compile it all
               ; cpEhcFullProgCompileAllModules
%%[[100
               -- cleanup
               ; unless (ehcOptKeepIntermediateFiles opts) cpRmFilesToRm
%%]]
               }
          where -- abbrev for imp1
                imp = imp1 opts fileSuffMpHs searchPath
                
                -- import others, but then in a (slightly) different way
                importAlso :: EHCompileUnitState -> (EHCompileUnit -> Set.Set HsName) -> EHCompilePhase ()
                importAlso how getNms
                  = do { cr <- get
                       ; let allAnalysedModS = Map.keysSet $ crCUCache cr
                             allNewS         = Set.unions [ getNms $ crCU m cr | m <- Set.toList allAnalysedModS ] `Set.difference` allAnalysedModS
                       ; cpImportGatherFromModsWithImp
                           (const [])
                           (imp how Nothing) (Set.toList allNewS)
                       }

        imp1 :: EHCOpts -> FileSuffMp -> FileLocPath -> EHCompileUnitState -> Maybe FPath -> Maybe (HsName,(FPath,FileLoc)) -> HsName -> EHCompilePhase (HsName,Maybe (HsName,(FPath,FileLoc)))
        imp1 opts fileSuffMpHs searchPath desiredState mbFp mbPrev nm
          = do { let isTopModule = isJust mbFp
                     fileSuffMpHs' = (if isTopModule then fileSuffMpHsNoSuff else []) ++ fileSuffMpHs
%%[[50
               ; fpsFound <- cpFindFilesForFPath False fileSuffMpHs' searchPath (Just nm) mbFp
%%][99
               ; let searchPath' = adaptedSearchPath mbPrev
               ; fpsFound <- cpFindFilesForFPathInLocations (fileLocSearch opts) (\(x,_,_) -> x) False fileSuffMpHs' searchPath' (Just nm) mbFp
%%]]
               ; when (ehcOptVerbosity opts >= VerboseDebug)
                      (do { lift $ putStrLn $ show nm ++ ": " ++ show (fmap fpathToStr mbFp) ++ ": " ++ show (map fpathToStr fpsFound)
%%[[99
                          ; lift $ putStrLn $ "searchPath: " ++ show searchPath'
%%]]
                          })
               ; when isTopModule
                      (cpUpdCU nm (ecuSetIsTopMod True))
%%[[99
               ; cpUpdCU nm (ecuSetTarget (ehcOptTarget opts))
%%]]
               ; case fpsFound of
                   (fp:_)
                     -> do { nm' <- cpEhcModuleCompile1 (Just desiredState) nm
                           ; cr <- get
                           ; let (ecu,_,_,_) = crBaseInfo nm' cr
                           ; return (nm',Just (nm',(fp, ecuFileLocation ecu)))
                           }
                   _ -> return (nm,Nothing)
               }
%%[[99
          where -- strip tail part corresponding to module name, and use it to search as well
                adaptedSearchPath (Just (prevNm,(prevFp,prevLoc)))
                  = case (fpathMbDir (mkFPath prevNm), fpathMbDir prevFp, prevLoc) of
                      (_, _, p) | filelocIsPkg p
                        -> p : searchPath
                      (Just n, Just p, _)
                        -> mkDirFileLoc (filePathUnPrefix prefix) : searchPath
                        where (prefix,_) = splitAt (length p - length n) p
                      _ -> searchPath
                adaptedSearchPath _ = searchPath
%%]]
%%]]

%%]
