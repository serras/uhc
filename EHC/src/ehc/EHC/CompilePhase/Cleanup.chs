%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile XXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Cleanup between phases

%%[99 module {%{EH}EHC.CompilePhase.Cleanup}
%%]

%%[99 import({%{EH}Base.Optimize})
%%]

-- general imports
%%[99 import({%{EH}EHC.Common})
%%]
%%[99 import({%{EH}EHC.CompileUnit})
%%]
%%[99 import({%{EH}EHC.CompileRun})
%%]

%%[99 import(Control.Monad.State)
%%]

-- HI syntax and semantics
%%[9999 import(qualified {%{EH}HI} as HI)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: cleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(cpCleanupHSMod,cpCleanupHS,cpCleanupFoldEH,cpCleanupEH)
cpCleanupHSMod :: HsName -> EHCompilePhase ()
cpCleanupHSMod modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbHSSemMod     	  = Nothing
               }
      )

cpCleanupHS :: HsName -> EHCompilePhase ()
cpCleanupHS modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbHS              = Nothing
               , ecuMbHSSem           = Nothing
               }
      )

cpCleanupFoldEH :: HsName -> EHCompilePhase ()
cpCleanupFoldEH modNm 
  = cpUpdCU modNm
      (\e -> e { ecuMbEH              = Nothing
               }
      )

cpCleanupEH :: HsName -> EHCompilePhase ()
cpCleanupEH modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbEHSem           = Nothing
               }
      )
%%]

%%[(99 codegen) export(cpCleanupCore)
cpCleanupCore :: [HsName] -> EHCompilePhase ()
cpCleanupCore modNmL
  = cpSeq [cl m | m <- modNmL]
  where cl m = cpUpdCU m
                  (\e -> e { ecuMbCore            = Nothing
%%[[(99 tycore)
                           , ecuMbTyCore          = Nothing
%%]]
%%[[(99 core)
                           , ecuMbCoreSem         = Nothing
%%]]
%%[[(99 corein)
                           , ecuMbCoreSemMod      = Nothing
%%]]
                           }
                  )
%%]

%%[(99 codegen cmm) export(cpCleanupCmm)
cpCleanupCmm :: HsName -> EHCompilePhase ()
cpCleanupCmm modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbCmm               = Nothing
               }
      )
%%]

%%[(99 codegen grin) export(cpCleanupGrin,cpCleanupFoldBytecode,cpCleanupBytecode)
cpCleanupGrin :: [HsName] -> EHCompilePhase ()
cpCleanupGrin modNmL
  = cpSeq [cl m | m <- modNmL]
  where cl m = cpUpdCU m
                  (\e -> e { ecuMbGrin            = Nothing
                           }
                  )

cpCleanupFoldBytecode :: HsName -> EHCompilePhase ()
cpCleanupFoldBytecode modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbBytecode          = Nothing
               }
      )

cpCleanupBytecode :: HsName -> EHCompilePhase ()
cpCleanupBytecode modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbBytecodeSem       = Nothing
               }
      )
%%]

%%[99 export(cpCleanupCU,cpCleanupFlow)
cpCleanupCU :: HsName -> EHCompilePhase ()
cpCleanupCU modNm
  = do { cpUpdCU modNm
           (\e -> e { ecuHIInfo            = {- HI.hiiRetainAfterCleanup -} (ecuHIInfo e)
                    , ecuMbOptim           = Nothing
                    }
           )
%%[[(99 codegen grin)
       -- Only cleanup Grin when we don't need to merge it.
       -- TODO think about this a bit longer.
       ; cr <- get
       ; let (_,opts) = crBaseInfo' cr
       ; when (ehcOptOptimizationScope opts < OptimizationScope_WholeGrin) $ cpCleanupGrin [modNm]
%%]]
       }

cpCleanupFlow :: HsName -> EHCompilePhase ()
cpCleanupFlow modNm
  = cpUpdCU modNm
      (\e -> e { ecuMbHSSemMod        = Nothing
               -- , ecuMbPrevHI          = Nothing
               -- , ecuMbPrevHISem       = Nothing
               -- , ecuMbPrevHIInfo      = Nothing
               }
      )
%%]

