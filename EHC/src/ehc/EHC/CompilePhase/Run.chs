%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile: running
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 corerun) module {%{EH}EHC.CompilePhase.Run}
%%]

%%[(8 corerun) import({%{EH}EHC.Common})
%%]
%%[(8 corerun) import({%{EH}EHC.CompileUnit})
%%]
%%[(8 corerun) import({%{EH}EHC.CompileRun})
%%]

%%[(8 corerun) import(Data.Maybe)
%%]
%%[(8 corerun) import(Control.Monad.State)
%%]

-- CoreRun
%%[(8 corerun) import({%{EH}Core.ToCoreRun})
%%]
%%[(8888 corerun) import({%{EH}CoreRun.Pretty})
%%]

-- Running CoreRun
%%[(8 corerun) import({%{EH}CoreRun.Run}, {%{EH}CoreRun.Run.Val})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run Core
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 corerun) export(cpRunCoreRun)
-- | Run CoreRun.
-- TBD: fix dependence on whole program linked
cpRunCoreRun :: HsName -> EHCompilePhase ()
cpRunCoreRun modNm = do
    cr <- get
    let (ecu,_,opts,_) = crBaseInfo modNm cr
        mbCore = ecuMbCore ecu
    cpMsg modNm VerboseNormal "Run Core"
    when (isJust mbCore) $ do
      let mod = cmod2CoreRun $ fromJust mbCore
      res <- liftIO $ runCoreRun opts [] mod $ cmodRun mod
      either (\e -> cpSetLimitErrsWhen 1 "Core running" [e]) (liftIO . putStrLn . show . pp) res
%%]


