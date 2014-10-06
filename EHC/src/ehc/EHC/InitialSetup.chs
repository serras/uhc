%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile XXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Initial values

%%[8 module {%{EH}EHC.InitialSetup}
%%]

-- general imports
%%[8 import(qualified Data.Map as Map)
%%]

%%[8 import({%{EH}EHC.Common})
%%]

-- HS semantics
%%[8 import(qualified {%{EH}HS.MainAG} as HSSem)
%%]
-- EH semantics
%%[8 import(qualified {%{EH}EH.MainAG} as EHSem)
%%]
-- Core semantics
%%[(8 core) import(qualified {%{EH}Core.ToGrin} as Core2GrSem)
%%]
-- HI semantics
%%[5020 import(qualified {%{EH}HI.MainAG} as HISem)
%%]
-- module
%%[50 import(qualified {%{EH}HS.ModImpExp} as HSSemMod)
%%]

%%[(50 codegen) hs import({%{EH}CodeGen.ImportUsedModules})
%%]
-- LamMp, SysF
%%[(8 codegen) import({%{EH}LamInfo})
%%]

%%[9 import(qualified {%{EH}Gam.ClGam} as Pr(initClGam))
%%]

-- CHR solver
%%[(50 hmtyinfer) import({%{EH}Pred.ToCHR}(initScopedPredStore))
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Initial values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(initialHSSem)
initialHSSem :: EHCOpts -> HSSem.Inh_AGItf
initialHSSem opts
  = HSSem.Inh_AGItf
      { HSSem.opts_Inh_AGItf            = opts
      , HSSem.idGam_Inh_AGItf           = HSSem.tyGam2IdDefOccGam initTyGam
                                            `gamUnion` HSSem.kiGam2IdDefOccGam initKiGam
%%[[9
                                            `gamUnion` HSSem.clGam2IdDefOccGam Pr.initClGam
%%]]
      , HSSem.gUniq_Inh_AGItf           = uidStart
%%[[50
      , HSSem.isTopMod_Inh_AGItf        = False
      , HSSem.moduleNm_Inh_AGItf        = hsnUnknown
      , HSSem.modInScope_Inh_AGItf      = Map.empty
      , HSSem.modEntToOrig_Inh_AGItf    = Map.empty
      , HSSem.fixityGam_Inh_AGItf       = initFixityGam
      , HSSem.topInstanceNmL_Inh_AGItf  = []
%%]]
      }
%%]

%%[8 export(initialEHSem)
initialEHSem :: EHCOpts -> FPath -> EHSem.Inh_AGItf
initialEHSem opts fp
  = EHSem.Inh_AGItf
      { EHSem.moduleNm_Inh_AGItf        = mkHNm (fpathBase fp)
      , EHSem.gUniq_Inh_AGItf           = uidStart
      , EHSem.opts_Inh_AGItf            = opts
%%[[50
      , EHSem.isMainMod_Inh_AGItf       = False
      , EHSem.idQualGam_Inh_AGItf       = emptyGam
%%]]
%%[[(50 hmtyinfer)
      , EHSem.valGam_Inh_AGItf          = emptyGam
      , EHSem.dataGam_Inh_AGItf         = emptyGam
      , EHSem.tyGam_Inh_AGItf           = initTyGam
      , EHSem.tyKiGam_Inh_AGItf         = initTyKiGam
      , EHSem.polGam_Inh_AGItf          = initPolGam
      , EHSem.kiGam_Inh_AGItf           = initKiGam
      , EHSem.clGam_Inh_AGItf           = Pr.initClGam
      , EHSem.clDfGam_Inh_AGItf         = emptyGam
      , EHSem.chrStore_Inh_AGItf        = initScopedPredStore
%%]]
      }
%%]

%%[(8 codegen) export(initialCore2GrSem)
initialCore2GrSem :: EHCOpts -> Core2GrSem.Inh_CodeAGItf
initialCore2GrSem opts
  = Core2GrSem.Inh_CodeAGItf
      { Core2GrSem.gUniq_Inh_CodeAGItf           	= uidStart
      , Core2GrSem.dataGam_Inh_CodeAGItf         	= emptyGam
      , Core2GrSem.opts_Inh_CodeAGItf            	= opts
      , Core2GrSem.lamMp_Inh_CodeAGItf           	= initLamMp
%%[[50
      , Core2GrSem.importUsedModules_Inh_CodeAGItf	= emptyImportUsedModules
%%]]
      }
%%]

%%[50 export(initialHSSemMod)
initialHSSemMod :: EHCOpts -> HSSemMod.Inh_AGItf
initialHSSemMod opts
  = HSSemMod.Inh_AGItf
      { HSSemMod.gUniq_Inh_AGItf       = uidStart
      , HSSemMod.moduleNm_Inh_AGItf    = hsnUnknown
      , HSSemMod.opts_Inh_AGItf        = opts
      }
%%]

%%[5020 export(initialHISem)
initialHISem :: EHCOpts -> HISem.Inh_AGItf
initialHISem opts
  = HISem.Inh_AGItf
      { HISem.opts_Inh_AGItf            = opts
      }
%%]

