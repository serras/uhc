%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile XXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 haddock
Top level combinations, stratified into 6 levels,
where higher numbered levels use lower numbered levels.

Levels:
1: processing building blocks
2: ehc compilation phases, including progress messages, stopping when asked for
3: ehc grouping of compilation phases for a single module
4: single module compilation
5: full program phases
6: full program compilation

Naming convention for functions:
level 1    : with prefix 'cpProcess'
level 2..6 : with prefix 'cpEhc'
%%]

%%[8 module {%{EH}EHC.CompilePhase.TopLevelPhases}
%%]

-- general imports
%%[8 import(qualified Data.Map as Map,qualified Data.Set as Set)
%%]
%%[8 import(qualified UHC.Util.FastSeq as Seq)
%%]
%%[8 import(Control.Monad.State)
%%]
%%[8 import(qualified {%{EH}Config} as Cfg)
%%]

-- trace, debug
%%[8 import(System.IO.Unsafe, Debug.Trace)
%%]

%%[8 import({%{EH}Base.Optimize})
%%]
%%[(8 codegen) import({%{EH}Base.Target})
%%]

%%[8 import({%{EH}EHC.Common})
%%]
%%[8 import({%{EH}EHC.CompileUnit})
%%]
%%[8 import({%{EH}EHC.CompileRun})
%%]
%%[50 import({%{EH}EHC.CompileGroup})
%%]

%%[8 import({%{EH}EHC.CompilePhase.Parsers})
%%]
%%[8 import({%{EH}EHC.CompilePhase.Translations})
%%]
%%[8 import({%{EH}EHC.CompilePhase.Output})
%%]
%%[(8 codegen) import({%{EH}EHC.CompilePhase.Transformations})
%%]
%%[(8 grin) import({%{EH}EHC.CompilePhase.TransformGrin})
%%]
%%[8 import({%{EH}EHC.CompilePhase.Semantics})
%%]
%%[8 import({%{EH}EHC.CompilePhase.FlowBetweenPhase})
%%]
%%[8 import({%{EH}EHC.CompilePhase.CompileC})
%%]
%%[(8 codegen llvm) import({%{EH}EHC.CompilePhase.CompileLLVM})
%%]
%%[(8 codegen java) import({%{EH}EHC.CompilePhase.CompileJVM})
%%]
%%[(8 codegen javascript) import({%{EH}EHC.CompilePhase.CompileJavaScript})
%%]
%%[99 import({%{EH}Base.PackageDatabase})
%%]
%%[(99 codegen) import({%{EH}EHC.CompilePhase.Link})
%%]
%%[50 import({%{EH}EHC.CompilePhase.Module},{%{EH}Module.ImportExport})
%%]
%%[99 import({%{EH}Base.Pragma})
%%]
%%[99 import({%{EH}EHC.CompilePhase.Cleanup})
%%]

-- Language syntax: Core
%%[(50 codegen) import(qualified {%{EH}Core} as Core(cModMerge))
%%]
%%[(50 codegen) import(qualified {%{EH}Core.Merge} as CMerge (cModMerge))
%%]
%%[(50 codegen corein) import(qualified {%{EH}Core.Check} as Core2ChkSem)
%%]
-- CoreRun
%%[(8 corerun) import({%{EH}EHC.CompilePhase.Run})
%%]
-- Language syntax: TyCore
%%[(8 codegen tycore) import(qualified {%{EH}TyCore.Full2} as C)
%%]
-- Language syntax: Grin
%%[(50 codegen grin) import(qualified {%{EH}GrinCode} as Grin(grModMerge))
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per full program compile actions: level 6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(50 codegen grin) haddock
Top level entry point into compilation by the compiler driver, apart from import analysis, wich is assumed to be done.
%%]

%%[(50 codegen)
-- | top lever driver for after all per-module work has been done, and whole program stuff like combining/linking can start
cpEhcFullProgLinkAllModules :: [HsName] -> EHCompilePhase ()
cpEhcFullProgLinkAllModules modNmL
 = do { cr <- get
      ; let (mainModNmL,impModNmL) = splitMain cr modNmL
            (_,opts) = crBaseInfo' cr   -- '
      ; when (not $ null modNmL)
             (cpMsg (head modNmL) VerboseDebug ("Main mod split: " ++ show mainModNmL ++ ": " ++ show impModNmL))
      ; case (mainModNmL, ehcOptLinkingStyle opts) of
          ([mainModNm], LinkingStyle_Exec)
                -> case () of
                     () | ehcOptOptimizationScope opts >= OptimizationScope_WholeCore
                            -> cpSeq (  hpt
%%[[(99 grin)
                                     ++ [ cpProcessAfterGrin mainModNm
                                        , cpCleanupGrin [mainModNm]
                                        ]
%%]]
                                     ++ exec
                                     )
                        | targetDoesHPTAnalysis (ehcOptTarget opts)
                            -> cpSeq $ hpt ++ exec
                        | otherwise
                            -> cpSeq exec
                        where exec = [ cpEhcExecutablePerModule FinalCompile_Exec impModNmL mainModNm ]
                              hpt  = [ cpEhcFullProgPostModulePhases opts modNmL (impModNmL,mainModNm)
                                     , cpEhcCorePerModulePart2 mainModNm
                                     ]
          ([mainModNm], _)
                -> return ()
                   -- cpSetLimitErrs 1 "compilation run" [rngLift emptyRange Err_MayNotHaveMain mainModNm]
          ([], LinkingStyle_Exec)
                -> cpSetLimitErrs 1 "compilation run" [rngLift emptyRange Err_MustHaveMain]
          ([], LinkingStyle_None)
                -> return ()
%%[[99
          ([], LinkingStyle_Pkg)
                -> do let cfgwr o = liftIO $ pkgWritePkgOptionAsCfg o fp
                            where (fp,_) = mkInOrOutputFPathDirFor OutputFor_Pkg opts l l ""
                                  l = mkFPath ""
                      case ehcOptPkgOpt opts of
                        Just (pkgopt@(PkgOption {pkgoptName=pkg})) -> do
                          cfgwr pkgopt
                          case () of
                            () | targetAllowsOLinking (ehcOptTarget opts) -> do
                                   cpLinkO impModNmL pkg
%%[[(99 jazy)       
                               | targetAllowsJarLinking (ehcOptTarget opts) -> do
                                   cpLinkJar Nothing impModNmL (JarMk_Pkg pkg)
%%]]       
                            _ -> return ()
                        _ -> return ()
%%]]   
      }
  where splitMain cr = partition (\n -> ecuHasMain $ crCU n cr)
%%]

%%[50 export(cpEhcCheckAbsenceOfMutRecModules)
cpEhcCheckAbsenceOfMutRecModules :: EHCompilePhase ()
cpEhcCheckAbsenceOfMutRecModules
 = do { cr <- get
      ; let mutRecL = filter (\ml -> length ml > 1) $ crCompileOrder cr
      ; when (not $ null mutRecL)
             (cpSetLimitErrs 1 "compilation run" [rngLift emptyRange Err_MutRecModules mutRecL]
             )
      }
%%]

%%[5050 export(cpEhcFetchAllMissingModulesForLinking)
-- | Fetch all necessary modules, but just the minimal info
cpEhcFetchAllMissingModulesForLinking :: EHCompilePhase ()
cpEhcFetchAllMissingModulesForLinking
 = do { cr <- get
      ; let modNmLL = crCompileOrder cr
            modNmL = map head modNmLL
            otherUsedModNmS = Set.unions [ ecuTransClosedUsedModMp me | m <- modNmL, let me = crCU m cr ] `Set.difference` Set.fromList modNmL
      ; return ()
      }
%%]

%%[50 export(cpEhcFullProgCompileAllModules)
cpEhcFullProgCompileAllModules :: EHCompilePhase ()
cpEhcFullProgCompileAllModules
 = do { cr <- get
      ; let modNmLL = crCompileOrder cr
            modNmL = map head modNmLL
      ; cpSeq (   []
%%[[99
               ++ (let modNmL2 = filter (\m -> let (ecu,_,_,_) = crBaseInfo m cr in not $ filelocIsPkg $ ecuFileLocation ecu) modNmL
                       nrMods = length modNmL2
                   in  zipWith (\m i -> cpUpdCU m (ecuStoreSeqNr (EHCCompileSeqNr i nrMods)) ) modNmL2 [1..nrMods]
                  )
%%]]
               ++ [cpEhcFullProgModuleCompileN modNmL]
%%[[(50 codegen grin)
               ++ [cpEhcFullProgLinkAllModules modNmL]
%%]]
              )
      }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per full program compile actions: level 5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(50 codegen grin) haddock
Post per module phases, as part of a full program compilation.
Post processing involves the following:
1. if doing full program analysis, merge the already compiled Core/Grin representations, and do the same work as for 1 module but now for the merged Core/Grin
2. compile+link everything together
%%]

%%[(50 codegen)
cpEhcFullProgPostModulePhases :: EHCOpts -> [HsName] -> ([HsName],HsName) -> EHCompilePhase ()
cpEhcFullProgPostModulePhases opts modNmL modSpl
  | ehcOptOptimizationScope opts >= OptimizationScope_WholeCore = cpEhcCoreFullProgPostModulePhases opts modNmL modSpl
%%[[(50 grin)
  | otherwise                                                   = cpEhcGrinFullProgPostModulePhases opts modNmL modSpl
%%][50
  | otherwise                                                   = return ()
%%]]
%%]

%%[(50 codegen grin)
cpEhcGrinFullProgPostModulePhases :: EHCOpts -> [HsName] -> ([HsName],HsName) -> EHCompilePhase ()
cpEhcGrinFullProgPostModulePhases opts modNmL (impModNmL,mainModNm)
  = cpSeq ([ cpSeq [cpEnsureGrin m | m <- modNmL]
           , mergeIntoOneBigGrin
%%[[(99 grin)
           , cpCleanupGrin impModNmL -- clean up unused Grin (moved here from cpCleanupCU)
%%]]
           ]
           ++ (if ehcOptDumpGrinStages opts then [void $ cpOutputGrin False "-fullgrin" mainModNm] else [])
           ++ [ cpMsg mainModNm VerboseDebug ("Full Grin generated, from: " ++ show impModNmL)
              ]
          )
  where mergeIntoOneBigGrin
          = do { cr <- get
               ; cpUpdCU mainModNm (ecuStoreGrin (Grin.grModMerge [ panicJust "cpEhcGrinFullProgPostModulePhases.mergeIntoOneBigGrin" $ ecuMbGrin $ crCU m cr
                                                                  | m <- modNmL
                                                                  ]
                                   )             )
               }

cpEnsureGrin :: HsName -> EHCompilePhase ()
cpEnsureGrin nm
-- read Grin, or, if not available, read and process Core
  = do { cpGetPrevGrin nm
       ; cr <- get
       ; when (isNothing $ ecuMbGrin $ crCU nm cr)
         $ do { cpGetPrevCore nm ; cpProcessCoreFold nm ; cpProcessCoreRest nm }
       }
%%]

%%[(50 codegen)
cpEhcCoreFullProgPostModulePhases :: EHCOpts -> [HsName] -> ([HsName],HsName) -> EHCompilePhase ()
cpEhcCoreFullProgPostModulePhases opts modNmL (impModNmL,mainModNm)
  = cpSeq ([ cpSeq [cpGetPrevCore m | m <- modNmL]
           , mergeIntoOneBigCore
           , cpTransformCore OptimizationScope_WholeCore mainModNm
           , cpFlowHILamMp mainModNm
           , cpProcessCoreFold mainModNm -- redo folding for replaced main module
           ]
           -- ++ (if ehcOptDumpCoreStages opts then [void $ cpOutputCore CPOutputCoreHow_Text "" "full.core" mainModNm] else [])
           ++ [ cpMsg mainModNm VerboseDebug ("Full Core generated, from: " ++ show impModNmL)
              ]
          )
  where mergeIntoOneBigCore
          = do { cr <- get
               ; cpUpdCU mainModNm 
                 $ ecuStoreCore 
                 $ CMerge.cModMerge (mOf mainModNm cr, [ mOf m cr | m <- impModNmL ])
%%[[99
               ; cpCleanupCore impModNmL -- clean up Core and CoreSem (it can still be read through cr in the next statement)
%%]]
               }
          where mOf m cr = panicJust "cpEhcCoreFullProgPostModulePhases.mergeIntoOneBigCore" $ ecuMbCore $ crCU m cr
%%]

%%[50 haddock
Per module compilation of (import) ordered sequence of module, as part of a full program compilation
%%]

%%[50
cpEhcFullProgModuleCompileN :: [HsName] -> EHCompilePhase ()
cpEhcFullProgModuleCompileN modNmL
  = cpSeq (merge (map cpEhcFullProgModuleCompile1    modNmL)
                 (map cpEhcFullProgBetweenModuleFlow modNmL)
          )
  where merge (c1:cs1) (c2:cs2) = c1 : c2 : merge cs1 cs2
        merge []       cs       = cs
        merge cs       []       = cs
%%]

%%[50 haddock
Find out whether a compilation is needed, and if so, can be done.
%%]

%%[50 export(cpEhcFullProgModuleDetermineNeedsCompile)
cpEhcFullProgModuleDetermineNeedsCompile :: HsName -> EHCompilePhase ()
cpEhcFullProgModuleDetermineNeedsCompile modNm
  = do { cr <- get
       ; let (ecu,_,opts,_) = crBaseInfo modNm cr
             needsCompile = crModNeedsCompile modNm cr
             canCompile   = crModCanCompile modNm cr
       ; when (ehcOptVerbosity opts >= VerboseDebug)
              (lift $ putStrLn
                (  show modNm
                ++ ", src fpath: " ++ show (ecuSrcFilePath ecu)
                ++ ", fileloc: " ++ show (ecuFileLocation ecu)
                ++ ", needs compile: " ++ show needsCompile
                ++ ", can compile: " ++ show canCompile
                ++ ", can use HI instead of HS: " ++ show (ecuCanUseHIInsteadOfHS ecu)
                ++ ", has main: " ++ show (ecuHasMain ecu)
                ++ ", is main: " ++ show (ecuIsMainMod ecu)
                ++ ", is top: " ++ show (ecuIsTopMod ecu)
                ++ ", valid HI: " ++ show (ecuIsValidHIInfo ecu)
                ++ ", HS newer: " ++ show (ecuIsHSNewerThanHI ecu)
                ))
       ; cpUpdCU modNm (ecuSetNeedsCompile (needsCompile && canCompile))
       }
%%]

%%[50 haddock
Compilation of 1 module, as part of a full program compilation
%%]

%%[50
cpEhcFullProgModuleCompile1 :: HsName -> EHCompilePhase ()
cpEhcFullProgModuleCompile1 modNm
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr   -- '
       ; when (ehcOptVerbosity opts >= VerboseALot)
              (lift $ putStrLn ("====================== Compile1: " ++ show modNm ++ "======================"))
       ; cpEhcFullProgModuleDetermineNeedsCompile modNm
       ; cr <- get
       ; let (ecu,_,_,_) = crBaseInfo modNm cr
             targ = ecuFinalDestinationState ecu -- ECUS_Haskell $ if ecuNeedsCompile ecu then HSAllSem else HIAllSem
       ; cpEhcModuleCompile1 (Just targ) modNm
       ; cr <- get
       ; let (ecu,_,_,_) = crBaseInfo modNm cr
       -- ; return ()
       ; when (ecuHasMain ecu) (crSetAndCheckMain modNm)
       }
%%]

%%[50 haddock
Flow of info between modules, as part of a full program compilation
%%]

%%[50
cpEhcFullProgBetweenModuleFlow :: HsName -> EHCompilePhase ()
cpEhcFullProgBetweenModuleFlow modNm
  = do { cr <- get
       ; case ecuState $ crCU modNm cr of
           ECUS_Haskell HSAllSem -> return ()
           ECUS_Haskell HIAllSem -> cpFlowHISem modNm
           _                     -> return ()
%%[[99
       ; cpCleanupFlow modNm
%%]]
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per module compile actions: level 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8.cpEhcModuleCompile1.sig export(cpEhcModuleCompile1)
cpEhcModuleCompile1 :: HsName -> EHCompilePhase ()
cpEhcModuleCompile1 modNm
%%]
%%[50 -8.cpEhcModuleCompile1.sig export(cpEhcModuleCompile1)
cpEhcModuleCompile1 :: Maybe EHCompileUnitState -> HsName -> EHCompilePhase HsName
cpEhcModuleCompile1 targHSState modNm
%%]
%%[8
  = do { cr <- get
       ; let (ecu,_,opts,fp) = crBaseInfo modNm cr
%%[[8
             defaultResult = ()
%%][50
             defaultResult = modNm
%%]]
%%[[50
       ; when (ehcOptVerbosity opts >= VerboseALot)
              (lift $ putStrLn ("====================== Module: " ++ show modNm ++ " ======================"))
       ; when (ehcOptVerbosity opts >= VerboseDebug)
              (lift $ putStrLn ("State: in: " ++ show (ecuState ecu) ++ ", to: " ++ show targHSState))
%%]]
%%[[8
       ; case (ecuState ecu,panic "CompilePhase.TopLevelPhases.cpEhcModuleCompile1") of
%%][50
       ; case (ecuState ecu,targHSState) of
%%]]
%%]
%%[5050
           (ECUS_Haskell HIStart,Just (ECUS_Haskell HMOnlyMinimal))
             -- |    st == HIStart
             -> do { cpMsg modNm VerboseNormal ("Minimal of HM")
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Haskell HMOnlyMinimal))
                   ; return modNm
                   }
%%]
%%[50
           (ECUS_Haskell st,Just (ECUS_Haskell HSOnlyImports))
             |    st == HSStart
%%[[99
               || st == LHSStart
%%]]
             -> do { cpEhcHaskellModulePrepareSrc modNm
                   ; modNm2 <- cpEhcHaskellImport stnext
%%[[99
                                                  (pkgExposedPackages $ ehcOptPkgDb opts)
%%]]
                                                  modNm
                   ; cpEhcHaskellModulePrepareHS2 modNm2
                   ; cpMsg modNm2 VerboseNormal ("Imports of " ++ hsstateShowLit st ++ "Haskell")
                   ; when (ehcOptVerbosity opts >= VerboseDebug)
                          (do { cr <- get
                              ; let (ecu,_,opts,fp) = crBaseInfo modNm2 cr
                              ; lift $ putStrLn ("After HS import: nm=" ++ show modNm ++ ", newnm=" ++ show modNm2 ++ ", fp=" ++ show fp ++ ", imp=" ++ show (ecuImpNmS ecu))
                              })
                   ; cpUpdCU modNm2 (ecuStoreState (ECUS_Haskell stnext))
                   ; cpStopAt CompilePoint_Imports
                   ; return modNm2
                   }
             where stnext = hsstateNext st
           (ECUS_Haskell HIStart,Just (ECUS_Haskell HSOnlyImports))
             -> do { cpMsg modNm VerboseNormal ("Imports of HI")
                   ; cpEhcHaskellModulePrepareHI modNm
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Haskell (hsstateNext HIStart)))
                   ; when (ehcOptVerbosity opts >= VerboseDebug)
                          (do { cr <- get
                              ; let (ecu,_,opts,fp) = crBaseInfo modNm cr
                              ; lift $ putStrLn ("After HI import: nm=" ++ show modNm ++ ", fp=" ++ show fp ++ ", imp=" ++ show (ecuImpNmS ecu))
                              })
                   ; return defaultResult
                   }
           (ECUS_Haskell st,Just (ECUS_Haskell HSOnlyImports))
             |    st == HSOnlyImports
               || st == HIOnlyImports
%%[[99
               || st == LHSOnlyImports
%%]]
             -> return defaultResult
           (ECUS_Haskell st,Just (ECUS_Haskell HSAllSem))
             |    st == HSOnlyImports
%%[[99
               || st == LHSOnlyImports
%%]]
             -> do { cpMsg modNm VerboseMinimal ("Compiling " ++ hsstateShowLit st ++ "Haskell")
                   ; cpEhcHaskellModuleAfterImport (ecuIsTopMod ecu) opts st
%%[[99
                                                   (pkgExposedPackages $ ehcOptPkgDb opts)
%%]]
                                                   modNm
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Haskell HSAllSem))
                   ; return defaultResult
                   }
           (ECUS_Haskell st,Just (ECUS_Haskell HIAllSem))
             |    st == HSOnlyImports
               || st == HIOnlyImports
%%[[99
               || st == LHSOnlyImports
%%]]
             -> do { cpMsg modNm VerboseNormal "Reading HI"
%%[[(50 codegen grin)
                   ; cpUpdateModOffMp [modNm]
%%]]
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Haskell HIAllSem))
                   ; return defaultResult
                   }
%%]]
%%]
%%[8
           (ECUS_Haskell HSStart,_)
             -> do { cpMsg modNm VerboseMinimal "Compiling Haskell"
                   ; cpEhcHaskellModulePrepare modNm
                   ; cpEhcHaskellParse
%%[[8
                                       False False
%%][99
                                       (ehcOptCPP opts) False
                                       (pkgExposedPackages $ ehcOptPkgDb opts)
%%]]
                                       modNm
                   ; cpEhcHaskellModuleCommonPhases True True opts modNm
%%[[(8 codegen)
                   ; when (ehcOptWholeProgHPTAnalysis opts)
                          (cpEhcCoreGrinPerModuleDoneFullProgAnalysis modNm)
%%]]
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Haskell HSAllSem))
                   ; return defaultResult
                   }
%%[[50
           (ECUS_Haskell st,Just (ECUS_Haskell HMOnlyMinimal))
             |    st == HIStart || st == HSStart -- st /= HMOnlyMinimal
             -> do { let mod = emptyMod' modNm
                   ; cpUpdCU modNm (ecuStoreMod mod)
                   -- ; cpCheckMods [modNm]
%%[[(50 codegen grin)
				   ; cpUpdateModOffMp [modNm]
%%]]
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Haskell HMOnlyMinimal))
                   ; return defaultResult
                   }
%%[[(50 corein)
           (ECUS_Core cst, Just (ECUS_Haskell HSOnlyImports))
             | cst == CRStartText || isBinary
             -> do { cpMsg modNm VerboseNormal $ "Reading Core (" ++ (if isBinary then "binary" else "textual") ++ ")"
                   -- 20140605 AD, code below is temporary, to cater for minimal and working infrastructure first...
                   ; cpEhcHaskellModulePrepareSrc modNm
                   ; modNm2 <- cpEhcCoreImport isBinary modNm
                   ; cpGetDummyCheckSrcMod modNm2		-- really dummy, should be based on actual import info to be extracted by cpEhcCoreImport
                   ; cpUpdCU modNm2 (ecuStoreState (ECUS_Core CROnlyImports))
                   ; return modNm2
                   }
             where isBinary = cst == CRStartBinary
           (ECUS_Core CROnlyImports,Just (ECUS_Core CRAllSem))
             -> do { cpMsg modNm VerboseMinimal "Compiling Core"
                   -- 20140605 AD, code below is temporary, to cater for minimal and working infrastructure first...
                   ; cpEhcCoreModuleAfterImport (ecuIsTopMod ecu) opts modNm
{-
                   ; cpProcessCoreModFold modNm
                   ; cpEhcCoreModuleCommonPhases True True True {- isMainMod isTopMod doMkExec -} opts modNm
-}
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Core CRAllSem))
                   ; return defaultResult
                   }
%%]]
           (_,Just (ECUS_Haskell HSOnlyImports))
             -> return defaultResult
%%]]
           (ECUS_Eh EHStart,_)
             -> do { cpMsg modNm VerboseMinimal "Compiling EH"
                   ; cpUpdOpts (\o -> o {ehcOptHsChecksInEH = True})
                   ; cpEhcEhParse modNm
%%[[50   
                   ; cpGetDummyCheckSrcMod modNm
%%]]   
                   ; cpEhcEhModuleCommonPhases True True True opts modNm
                   
%%[[(8 codegen)
                   ; when (ehcOptWholeProgHPTAnalysis opts)
                          (cpEhcCoreGrinPerModuleDoneFullProgAnalysis modNm)
%%]]   
                   ; cpUpdCU modNm (ecuStoreState (ECUS_Eh EHAllSem))
                   ; return defaultResult
                   }
%%[[(90 codegen)
           (ECUS_C CStart,_)
             | targetIsOnUnixAndOrC (ehcOptTarget opts)
             -> do { cpSeq [ cpMsg modNm VerboseMinimal "Compiling C"
                           , cpCompileWithGCC FinalCompile_Module [] modNm
                           , cpUpdCU modNm (ecuStoreState (ECUS_C CAllSem))
                           ]
                   ; return defaultResult
                   }
             | otherwise
             -> do { cpMsg modNm VerboseMinimal "Skipping C"
                   ; return defaultResult
                   }
           (ECUS_O OStart,_)
             | targetIsOnUnixAndOrC (ehcOptTarget opts)
             -> do { cpSeq [ cpMsg modNm VerboseMinimal "Passing through .o file"
                           -- , cpCompileWithGCC FinalCompile_Module [] modNm
                           , cpUpdCU modNm (ecuStoreState (ECUS_O OAllSem))
                           ]
                   ; return defaultResult
                   }
             | otherwise
             -> do { cpMsg modNm VerboseMinimal "Skipping .o file"
                   ; return defaultResult
                   }
%%]]
%%[[(8 codegen grin grinparser)
           (ECUS_Grin,_)
             -> do { cpMsg modNm VerboseMinimal "Compiling Grin"
                   ; cpParseGrin modNm
                   ; cpProcessGrin modNm
                   ; cpProcessAfterGrin modNm 
                   ; return defaultResult
                   }
                   
%%]]
           _ -> return defaultResult
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per module compile actions: level 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 haddock
EH common phases: analysis + core + grin
%%]

%%[8
cpEhcCoreModuleCommonPhases :: Bool -> Bool -> Bool -> EHCOpts -> HsName -> EHCompilePhase ()
cpEhcCoreModuleCommonPhases isMainMod isTopMod doMkExec opts modNm
  = cpSeq ([ 
%%[[(8 codegen)
             cpEhcCorePerModulePart1 modNm
%%]]
           ]
%%[[(8 codegen grin)
           ++ (if ehcOptWholeProgHPTAnalysis opts
               then []
               else [cpEhcCoreGrinPerModuleDoneNoFullProgAnalysis opts isMainMod isTopMod doMkExec modNm]
              )
%%]]
          )
%%]

%%[8
cpEhcEhModuleCommonPhases :: Bool -> Bool -> Bool -> EHCOpts -> HsName -> EHCompilePhase ()
cpEhcEhModuleCommonPhases isMainMod isTopMod doMkExec opts modNm
  = cpSeq [ cpEhcEhAnalyseModuleDefs modNm
          , cpEhcCoreModuleCommonPhases isMainMod isTopMod doMkExec opts modNm
          ]
%%]

%%[8
-- | Common phases when starting with a Haskell module.
-- HS common phases: HS analysis + EH common
cpEhcHaskellModuleCommonPhases :: Bool -> Bool -> EHCOpts -> HsName -> EHCompilePhase ()
cpEhcHaskellModuleCommonPhases isTopMod doMkExec opts modNm
  = cpSeq [ cpEhcHaskellAnalyseModuleDefs modNm
          , do { cr <- get
               ; let (ecu,_,_,_) = crBaseInfo modNm cr
               ; cpEhcEhModuleCommonPhases
%%[[8
                   isTopMod
%%][50
                   (ecuIsMainMod ecu)
%%]]
                   isTopMod doMkExec opts modNm
               }
          ]       
%%]

%%[50
-- | All the work to be done after Haskell src imports have been read/analysed.
-- Post module import common phases: Parse + Module analysis + HS common
cpEhcHaskellModuleAfterImport
  :: Bool -> EHCOpts -> HSState
%%[[99
     -> [PkgModulePartition]
%%]]
     -> HsName -> EHCompilePhase ()
cpEhcHaskellModuleAfterImport
     isTopMod opts hsst
%%[[99
     pkgKeyDirL
%%]]
     modNm
  = cpSeq [ cpEhcHaskellParse False (hsstateIsLiteral hsst)
%%[[99
                              pkgKeyDirL
%%]]
                              modNm
          , cpEhcHaskellAnalyseModuleItf modNm
          , cpEhcHaskellModuleCommonPhases isTopMod False opts modNm
          , cpEhcHaskellModulePostlude modNm
          ]       
%%]

%%[(50 corein)
-- | All the work to be done after Core src/binary imports have been read/analysed
cpEhcCoreModuleAfterImport
  :: Bool -> EHCOpts
     -> HsName -> EHCompilePhase ()
cpEhcCoreModuleAfterImport
     isTopMod opts
     modNm
  = do { cr <- get
       ; let (ecu,_,_,_) = crBaseInfo modNm cr
       ; cpSeq
          [ cpEhcCoreAnalyseModuleItf modNm
          , cpProcessCoreModFold modNm
          , cpEhcCoreModuleCommonPhases (ecuIsMainMod ecu) isTopMod False opts modNm
{-
          , cpEhcHaskellModuleCommonPhases isTopMod False opts modNm
          , cpEhcHaskellModulePostlude modNm
-}
          ]  
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per module compile actions: level 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 haddock
Prepare module for compilation.
This should be the first step before compilation of a module and is meant to obtain cached info from a previous compilation.
%%]

%%[8.cpEhcHaskellModulePrepare
cpEhcHaskellModulePrepare :: HsName -> EHCompilePhase ()
cpEhcHaskellModulePrepare _ = return ()
%%]

We need to know meta info in a more staged manner.
To be able to cpp preprocess first we need to know whether a Haskell file exists.
(1) we get the timestamp, so we know the file exists, so we can preprocess.
(..) then happens other stuff, getting the real module name, getting the import list.
(2) only then we can get info about derived files because the location is based on the real module name.
    Previous info also has to be obtained again.

%%[50 -8.cpEhcHaskellModulePrepare
cpEhcHaskellModulePrepareSrc :: HsName -> EHCompilePhase ()
cpEhcHaskellModulePrepareSrc modNm
  = cpGetMetaInfo [GetMeta_Src,GetMeta_Dir] modNm

cpEhcHaskellModulePrepareHS2 :: HsName -> EHCompilePhase ()
cpEhcHaskellModulePrepareHS2 modNm
  = cpSeq [ cpGetMetaInfo
              [ GetMeta_Src, GetMeta_HI, GetMeta_Core
%%[[(50 grin)
              , GetMeta_Grin
%%]]
              , GetMeta_Dir
              ] modNm
          , cpGetPrevHI modNm
          -- , cpFoldHI modNm
          , cpFoldHIInfo modNm
          ]

cpEhcHaskellModulePrepareHI :: HsName -> EHCompilePhase ()
cpEhcHaskellModulePrepareHI modNm
  = cpSeq [ cpGetMetaInfo
              [ GetMeta_HI, GetMeta_Core
%%[[(50 grin)
              , GetMeta_Grin
%%]]
              ] modNm
          , cpGetPrevHI modNm
          -- , cpFoldHI modNm
          , cpFoldHIInfo modNm
          ]

cpEhcHaskellModulePrepare :: HsName -> EHCompilePhase ()
cpEhcHaskellModulePrepare modNm
  = cpSeq [ cpEhcHaskellModulePrepareSrc modNm
          , cpEhcHaskellModulePrepareHS2 modNm
          ]
%%]

%%[50
cpEhcHaskellModulePostlude :: HsName -> EHCompilePhase ()
cpEhcHaskellModulePostlude modNm
  = cpSeq [ cpOutputHI "hi" modNm
%%[[99
          , cpCleanupCU modNm
%%]]
          ]
%%]

%%[50
-- | Get import information from Haskell module source text.
cpEhcHaskellImport
  :: HSState
%%[[99
     -> [PkgModulePartition]
%%]]
     -> HsName -> EHCompilePhase HsName
cpEhcHaskellImport
     hsst
%%[[99
     pkgKeyDirL
%%]]
     modNm
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr
       
       -- 1st, parse
       ; cppAndParse modNm
%%[[99
           (ehcOptCPP opts)
%%]]
       ; cpStepUID
       
       -- and then get pragmas and imports
%%[[50
       ; foldAndImport modNm
%%][99
       ; modNm' <- foldAndImport modNm
       ; cr2 <- get
       ; let (ecu,_,opts2,_) = crBaseInfo modNm' cr2
       
       -- if we find out that CPP should have invoked or cmdline options (pragma OPTIONS_UHC) have been specified,
       --  we backtrack to the original runstate and redo the above with CPP
       ; if (not (ehcOptCPP opts2)						-- reinvoke if CPP has not been invoked before
             || ehcOptCmdLineOptsDoneViaPragma opts2	-- or options have been set via pragma
            )
            -- check whether the pragma has a cmdline option like effect
            && (not $ null $ filter pragmaInvolvesCmdLine $ Set.toList $ ecuPragmas ecu) -- Set.member Pragma_CPP (ecuPragmas ecu)
         then do { put cr
                 ; when (isJust $ ecuMbOpts ecu)
                        (cpUpdCU modNm (ecuStoreOpts opts2))
                 ; cppAndParse modNm (ehcOptCPP opts || Set.member Pragma_CPP (ecuPragmas ecu))
                 ; cpStepUID
                 ; foldAndImport modNm
                 }
         else return modNm'
%%]]
       }
  where cppAndParse modNm
%%[[50
          = cpSeq [ cpParseHsImport modNm
                  ]
%%][99
          doCPP
          = cpSeq [ when doCPP (cpPreprocessWithCPP pkgKeyDirL modNm)
                  , cpParseHsImport (hsstateIsLiteral hsst) modNm
                  ]
%%]]
        foldAndImport modNm
          = do { cpFoldHsMod modNm
               ; cpGetHsModnameAndImports modNm
               }
%%]

%%[8
-- | Parse a Haskell module
cpEhcHaskellParse
  :: Bool -> Bool
%%[[99
     -> [PkgModulePartition]
%%]]
     -> HsName -> EHCompilePhase ()
cpEhcHaskellParse
     doCPP litmode
%%[[99
     pkgKeyDirL
%%]]
     modNm
  = cpSeq (
%%[[8
             [ cpParseHs modNm ]
%%][99
             (if doCPP then [cpPreprocessWithCPP pkgKeyDirL modNm] else [])
          ++ [ cpParseHs litmode modNm ]
%%]]
          ++ [ cpMsg modNm VerboseALot "Parsing done"
             , cpStopAt CompilePoint_Parse
             ]
          )
%%]

%%[8
cpEhcEhParse :: HsName -> EHCompilePhase ()
cpEhcEhParse modNm
  = cpSeq [ cpParseEH modNm
          , cpStopAt CompilePoint_Parse
          ]
%%]

%%[(8 corein)
cpEhcCoreParse :: HsName -> EHCompilePhase ()
cpEhcCoreParse modNm
  = cpSeq [ cpParseCoreWithFPath Nothing modNm
          , cpStopAt CompilePoint_Parse
          ]
%%]

%%[50
-- | Analyse a Haskell src module for
--     (1) module information (import, export, etc),
cpEhcHaskellAnalyseModuleItf :: HsName -> EHCompilePhase ()
cpEhcHaskellAnalyseModuleItf modNm
  = cpSeq [ cpStepUID, cpFoldHsMod modNm, cpGetHsMod modNm
          , cpCheckMods [modNm]
%%[[(50 codegen grin)
          , cpUpdateModOffMp [modNm]
%%]]
%%[[99
          , cpCleanupHSMod modNm
%%]]
          ]
%%]

%%[(50 corein)
-- | Analyse a Core text/binary src module for
--     (1) module information (import, export, etc),
cpEhcCoreAnalyseModuleItf :: HsName -> EHCompilePhase ()
cpEhcCoreAnalyseModuleItf modNm
  = cpSeq [ cpCheckMods [modNm]
%%[[(50 codegen grin)
          , cpUpdateModOffMp [modNm]
%%]]
%%[[99
          -- , cpCleanupHSMod modNm
%%]]
          ]
%%]

%%[8
-- | Analyse a Haskell src module for
--     (2) names + dependencies
cpEhcHaskellAnalyseModuleDefs :: HsName -> EHCompilePhase ()
cpEhcHaskellAnalyseModuleDefs modNm
  = cpSeq [ cpStepUID
          , cpProcessHs modNm
          , cpMsg modNm VerboseALot "Name+dependency analysis done"
          , cpStopAt CompilePoint_AnalHS
          ]
%%]

%%[8
-- | Analyse a Haskell src module for
--     (3) types
cpEhcEhAnalyseModuleDefs :: HsName -> EHCompilePhase ()
cpEhcEhAnalyseModuleDefs modNm
  = cpSeq [ cpStepUID, cpProcessEH modNm
          , cpMsg modNm VerboseALot "Type analysis done"
          , cpStopAt CompilePoint_AnalEH
          ]
%%]

%%[(8 codegen)
-- | Part 1 Core processing, on a per module basis, part1 is done always
cpEhcCorePerModulePart1 :: HsName -> EHCompilePhase ()
cpEhcCorePerModulePart1 modNm
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
%%[[8
             earlyMerge = False
%%][50
             earlyMerge = ehcOptOptimizationScope opts >= OptimizationScope_WholeCore
%%]]
       ; cpSeq
           (  [ cpStepUID ]
%%[[(8 tycore)
           ++ (if ehcOptTyCore opts
               then [ cpProcessTyCoreBasic modNm
                    , cpMsg modNm VerboseALot "TyCore (basic) done"
                    , cpTranslateTyCore2Core modNm
                    , cpStepUID
                    ]
               else []
              )
%%]]
           ++ [ cpProcessCoreBasic modNm
              , cpMsg modNm VerboseALot "Core (basic) done"
              , when (not earlyMerge) $ cpProcessCoreRest modNm
              , cpStopAt CompilePoint_Core
              ]
           )
       }
%%]

%%[(50 codegen corein)
-- | Get import information from Core module source text.
cpEhcCoreImport
  :: Bool -> HsName -> EHCompilePhase HsName
cpEhcCoreImport
     isBinary modNm
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr
       
       ; if isBinary
         then -- cpDecodeCore (Just Cfg.suffixDotlessInputOutputBinaryCore) modNm
              cpDecodeCore Nothing modNm
         else cpParseCoreWithFPath Nothing modNm
       ; cpFoldCoreMod modNm
       ; cpGetCoreModnameAndImports modNm
       }
%%]

%%[(50 codegen corein)
-- | Analyse a Core src module
cpEhcCoreAnalyseModule :: HsName -> EHCompilePhase ()
cpEhcCoreAnalyseModule modNm
  = do { cr <- get
       ; cpUpdateModOffMp [modNm]
       ; let (ecu,_,opts,_) = crBaseInfo modNm cr
             coreSem = panicJust "cpEhcCoreAnalyseModule" $ ecuMbCoreSemMod ecu
             errs = Seq.toList $ Core2ChkSem.errs_Syn_CodeAGItf coreSem
       ; cpSetLimitErrsWhen 5 "Core analysis" errs
       }
%%]

%%[(8 codegen)
-- | Part 2 Core processing, part2 is done either for per individual module compilation or after full program analysis
cpEhcCorePerModulePart2 :: HsName -> EHCompilePhase ()
cpEhcCorePerModulePart2 modNm
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
%%[[8
             earlyMerge = False
%%][50
             earlyMerge = ehcOptOptimizationScope opts >= OptimizationScope_WholeCore
%%]]
       ; cpSeq [ when earlyMerge $ cpProcessCoreRest modNm
%%[[(8 grin)
               , when (ehcOptIsViaGrin opts) (cpProcessGrin modNm)
%%]]
               ]
       }
%%]

%%[(8 codegen grin)
-- | Core+grin processing, on a per module basis, may only be done when no full program analysis is done
cpEhcCoreGrinPerModuleDoneNoFullProgAnalysis :: EHCOpts -> Bool -> Bool -> Bool -> HsName -> EHCompilePhase ()
cpEhcCoreGrinPerModuleDoneNoFullProgAnalysis opts isMainMod isTopMod doMkExec modNm
  = cpSeq (  [ cpEhcCorePerModulePart2 modNm
%%[[50
             , cpMsg modNm VerboseDebug "cpFlowOptim"
             , cpFlowOptim modNm
%%]]
%%[[(99 grin)
             , cpCleanupGrin [modNm]
             , cpProcessAfterGrin modNm
%%]]
             ]
          ++ (if not isMainMod || doMkExec
              then let how = if doMkExec then FinalCompile_Exec else FinalCompile_Module
                   in  [cpEhcExecutablePerModule how [] modNm]
              else []
             )
          ++ [ cpMsg modNm VerboseALot ("Core" ++ (if ehcOptIsViaGrin opts then "+Grin" else "") ++ " done")
             , cpMsg modNm VerboseDebug ("isMainMod: " ++ show isMainMod)
             ]
          )
%%]

%%[(8 codegen)
-- | Core+grin processing, on a per module basis, may only be done when full program analysis is done
cpEhcCoreGrinPerModuleDoneFullProgAnalysis :: HsName -> EHCompilePhase ()
cpEhcCoreGrinPerModuleDoneFullProgAnalysis modNm
  = cpSeq (  [ cpEhcCorePerModulePart2 modNm
             , cpEhcExecutablePerModule FinalCompile_Exec [] modNm
             , cpMsg modNm VerboseALot "Full Program Analysis (Core+Grin) done"
             ]
          )
%%]

%%[(8 codegen)
-- | Make final executable code, either still partly or fully (i.e. also linking)
cpEhcExecutablePerModule :: FinalCompileHow -> [HsName] -> HsName -> EHCompilePhase ()
cpEhcExecutablePerModule how impModNmL modNm
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq $
              [ cpCompileWithGCC how impModNmL modNm ]
%%[[(8 llvm)
           ++ [ cpCompileWithLLVM modNm ]
%%]]
%%[[(8 jazy)
           ++ [ cpCompileJazyJVM how impModNmL modNm ]
%%]]
%%[[(8 javascript)
           ++ [ when (ehcOptJavaScriptViaCMM opts) $ cpTransformJavaScript OptimizationScope_PerModule modNm
              , cpCompileJavaScript how impModNmL modNm
              ]
%%]]
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per module compile actions: level 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
cpProcessHs :: HsName -> EHCompilePhase ()
cpProcessHs modNm 
  = cpSeq [ cpFoldHs modNm
%%[[50
          , cpFlowHsSem1 modNm
%%]]
          , cpTranslateHs2EH modNm
%%[[99
          , cpCleanupHS modNm
%%]]
          ]
%%]

%%[8
cpProcessEH :: HsName -> EHCompilePhase ()
cpProcessEH modNm
  = do { cr <- get
       ; let (_,_,opts,fp) = crBaseInfo modNm cr
%%[[99
       {-
             optsTr = opts { ehcOptTrace = \s x -> unsafePerformIO (do { s <- execStateT (do { cpMsg modNm VerboseALot ("EH>: " ++ s) 
                                                                                             ; x `seq` cpMsg modNm VerboseALot ("EH<: " ++ s) 
                                                                                             }) cr 
                                                                       ; return x
                                                                       }) }
             -- optsTr = opts { ehcOptTrace = \s x -> unsafePerformIO (do { putCompileMsg VerboseALot (ehcOptVerbosity opts) ("EH: " ++ s) Nothing modNm fp ; return x }) }
             -- optsTr = opts { ehcOptTrace = \s x -> unsafePerformIO (do { putStrLn ("EH: " ++ s) ; return x }) }
             -- optsTr = opts { ehcOptTrace = trace }
       -- ; cpUpdStateInfo (\crsi -> crsi {crsiOpts = optsTr})
       ; cpUpdCU modNm (ecuStoreOpts optsTr)
       -}
%%]]
       ; cpSeq [ cpFoldEH modNm
%%[[99
               , cpCleanupFoldEH modNm
%%]]
               , cpFlowEHSem1 modNm
               , cpTranslateEH2Output modNm
%%[[(8 codegen)
               ,
%%[[(8 tycore)
                 if ehcOptTyCore optsTr
                 then cpTranslateEH2TyCore modNm
                 else 
%%]]
                      cpTranslateEH2Core modNm
%%]]
%%[[99
               , cpCleanupEH modNm
%%]]
               ]
       }
%%]

%%[(8 codegen tycore)
-- | TBD: finish it, only a sketch now
cpProcessTyCoreBasic :: HsName -> EHCompilePhase ()
cpProcessTyCoreBasic modNm 
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
             check m  = do { cr <- get
                           ; let (ecu,_,opts,_) = crBaseInfo m cr
                                 cMod   = panicJust "cpProcessTyCoreBasic" $ ecuMbTyCore ecu
                                 errs   = C.tcCheck opts C.emptyCheckEnv cMod
                           ; cpSetLimitErrsWhen 500 "Check TyCore" errs
                           }
       ; cpSeq [ cpTransformTyCore modNm
               , when (ehcOptTyCore opts)
                      (do { cpOutputTyCore "tycore" modNm
                          ; check modNm
                          })
               ]
        }
%%]

%%[(8 codegen)
-- unprocessed core -> folded core
cpProcessCoreBasic :: HsName -> EHCompilePhase ()
cpProcessCoreBasic modNm 
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq [ cpTransformCore OptimizationScope_PerModule modNm
%%[[50
               , cpFlowHILamMp modNm
%%]]
               -- , when (ehcOptEmitCore opts) (void $ cpOutputCore CPOutputCoreHow_Binary "" "core" modNm)
               , void $ cpOutputCore CPOutputCoreHow_Binary [] "" Cfg.suffixDotlessBinaryCore modNm
%%[[(8888 codegen java)
               , when (ehcOptEmitJava opts) (cpOutputJava         "java" modNm)
%%]]
               , cpProcessCoreFold modNm
               ]
        }
%%]

%%[(8 codegen)
-- unfolded core -> folded core
-- (called on merged core, and on core directly generated from cached grin)
cpProcessCoreFold :: HsName -> EHCompilePhase ()
cpProcessCoreFold modNm
  = cpSeq $
%%[[50
	  [ cpFlowCoreSemBeforeFold modNm ] ++
%%]]
      [ cpFoldCore2Grin modNm ]
%%[[50
	  ++ [ cpFlowCoreSemAfterFold modNm ]
%%]]
%%]

%%[(50 codegen corein)
cpProcessCoreModFold :: HsName -> EHCompilePhase ()
cpProcessCoreModFold modNm
  = cpSeq $
      [ cpEhcCoreAnalyseModule modNm
      , cpFlowCoreModSem modNm
      ]
%%]

%%[(8 codegen)
-- folded core -> grin, jazy, and the rest
cpProcessCoreRest :: HsName -> EHCompilePhase ()
cpProcessCoreRest modNm
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq (   []
%%[[(8 grin)
                ++ [ cpTranslateCore2Grin modNm ]
                ++ (if ehcOptIsViaGrin opts then [void $ cpOutputGrin True "" modNm] else [])
%%]]
%%[[(8 jazy)
                ++ [ cpTranslateCore2Jazy modNm ]
%%]]
%%[[(8 javascript)
                ++ (if ehcOptIsViaCoreJavaScript opts then [ cpTranslateCore2JavaScript modNm ] else [])
%%]]
%%[[(8 coreout)
                ++ (if CoreOpt_Dump `elem` ehcOptCoreOpts opts
                    then [void $ cpOutputCore CPOutputCoreHow_Text [] "" Cfg.suffixDotlessOutputTextualCore modNm]
                    else [])
                ++ (if CoreOpt_DumpBinary `elem` ehcOptCoreOpts opts
                    then [void $ cpOutputCore CPOutputCoreHow_Binary [] "" Cfg.suffixDotlessInputOutputBinaryCore modNm]
                    else [])
%%]]
%%[[(8 corerun)
                ++ (if CoreOpt_DumpRun `elem` ehcOptCoreOpts opts
                    then [void $ cpOutputCore CPOutputCoreHow_Run [] "" Cfg.suffixDotlessInputOutputCoreRun modNm]
                    else [])
                ++ (if CoreOpt_Run `elem` ehcOptCoreOpts opts		-- TBD: only when right backend? For now, just do it
                    then [cpRunCoreRun modNm]
                    else [])
%%]]
%%[[99
                ++ [ cpCleanupCore [modNm] ]
%%]]
               )
       }
          
%%]

%%[(8 codegen grin)
cpProcessGrin :: HsName -> EHCompilePhase ()
cpProcessGrin modNm 
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq (   (if ehcOptDumpGrinStages opts then [void $ cpOutputGrin False "-000-initial" modNm] else [])
                ++ [cpTransformGrin modNm]
                ++ (if ehcOptDumpGrinStages opts then [void $ cpOutputGrin False "-099-final" modNm]  else [])
%%[[(8 wholeprogAnal)
                ++ (if targetDoesHPTAnalysis (ehcOptTarget opts) then [cpTransformGrinHPTWholeProg modNm] else [])
%%]]
%%[[(8 cmm)
                ++ (if ehcOptIsViaCmm opts then [cpTranslateGrin2Cmm modNm] else [])
%%]]
                ++ (if ehcOptEmitBytecode opts then [cpTranslateGrin2Bytecode modNm] else [])
               )
       }
%%]

%%[(8 codegen grin)
cpProcessAfterGrin :: HsName -> EHCompilePhase ()
cpProcessAfterGrin modNm 
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq (  [ when (targetIsGrinBytecode (ehcOptTarget opts)) $
                      cpProcessBytecode modNm
%%[[(8 cmm)
                  , when (ehcOptIsViaCmm opts) $
                      cpProcessCmm modNm
%%]]
                  ]
          )
       }
%%]

%%[(8 codegen cmm)
cpProcessCmm :: HsName -> EHCompilePhase ()
cpProcessCmm modNm 
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq [ cpMsg modNm VerboseALot "Translate Cmm"
               -- , when (ehcOptDumpCmmStages opts) $ void $ cpOutputCmm False "-000-initial" modNm
               , cpTransformCmm OptimizationScope_PerModule modNm

%%[[(8 javascript)
               , when (ehcOptIsViaGrinCmmJavaScript opts) $ cpTranslateCmm2JavaScript modNm
%%]]
%%[[99
               , cpCleanupCmm modNm
%%]]
               ]
       }
%%]

%%[(8 codegen grin)
cpProcessBytecode :: HsName -> EHCompilePhase ()
cpProcessBytecode modNm 
  = do { cr <- get
       ; let (_,_,opts,_) = crBaseInfo modNm cr
       ; cpSeq [ cpMsg modNm VerboseALot "Translate ByteCode"
               , cpTranslateByteCode modNm
%%[[50
               , cpFlowHILamMp modNm
%%]]
%%[[99
               , cpCleanupFoldBytecode modNm
%%]]
               , when (ehcOptEmitBytecode opts)
                      (do { cpOutputByteCodeC "c" modNm
                          })
%%[[99
               , cpCleanupBytecode modNm
%%]]
%%[[(99 cmm)
               -- 20111220: temporary, until Cmm is in main path
               , cpCleanupCmm modNm
%%]]
               ]
       }

%%]

