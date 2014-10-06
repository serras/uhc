%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile Unit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

An EHC compile unit maintains info for one unit of compilation, a Haskell (HS) module, an EH file.

%%[8 module {%{EH}EHC.CompileUnit}
%%]

-- general imports
%%[8 import(qualified Data.Map as Map,qualified Data.Set as Set)
%%]
%%[8 import({%{EH}EHC.Common})
%%]

-- Language syntax: HS, EH
%%[8 import(qualified {%{EH}HS} as HS, qualified {%{EH}EH} as EH)
%%]
-- Language syntax: Core, TyCore, Grin, ...
%%[(8 codegen) import( qualified {%{EH}Core} as Core)
%%]
%%[(8 codegen tycore) import(qualified {%{EH}TyCore} as C)
%%]
%%[(8 codegen grin) import(qualified {%{EH}GrinCode} as Grin, qualified {%{EH}GrinByteCode} as Bytecode)
%%]
%%[(8 jazy) hs import(qualified {%{EH}JVMClass} as Jvm)
%%]
%%[(8 javascript) hs import(qualified {%{EH}JavaScript} as JS)
%%]
%%[(8 codegen cmm) hs import(qualified {%{EH}Cmm} as Cmm)
%%]
-- Language semantics: HS, EH
%%[8 import(qualified {%{EH}EH.MainAG} as EHSem, qualified {%{EH}HS.MainAG} as HSSem)
%%]
-- Language semantics: Core
%%[(8 core) import(qualified {%{EH}Core.ToGrin} as Core2GrSem)
%%]
%%[(8 codegen corein) import(qualified {%{EH}Core.Check} as Core2ChkSem)
%%]

-- HI Syntax and semantics, HS module semantics
%%[50 import(qualified {%{EH}HI} as HI)
%%]
%%[50 import(qualified {%{EH}HS.ModImpExp} as HSSemMod)
%%]
-- module admin
%%[50 import({%{EH}Module.ImportExport}, {%{EH}CodeGen.ImportUsedModules})
%%]

-- timestamps
%%[5050 import(Data.Time, System.Directory)
%%]

%%[50 import(UHC.Util.Time, System.Directory)
%%]
-- | a for now alias for old-time ClockTime
type ClockTime = UTCTime

diffClockTimes = diffUTCTime

noTimeDiff :: NominalDiffTime
noTimeDiff = toEnum 0

getClockTime :: IO ClockTime
getClockTime = getCurrentTime

-- Force evaluation for IO
%%[9999 import({%{EH}Base.ForceEval})
%%]
%%[(9999 codegen) import({%{EH}Core.Trf.ForceEval})
%%]
%%[(9999 codegen grin) import({%{EH}GrinCode.Trf.ForceEval}, {%{EH}GrinByteCode.Trf.ForceEval})
%%]

-- pragma, target
%%[99 hs import(qualified {%{EH}Base.Pragma} as Pragma, {%{EH}Base.Target})
%%]

-- debug
%%[99 import(UHC.Util.Debug)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Inter module optimisation info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Intermodule optimisation info.
Currently only for Grin meant to be compiled to GrinByteCode.
Absence of this info should not prevent correct compilation.

%%[50 export(Optim(..),defaultOptim)
data Optim
  = Optim
%%[[(50 grin)
      { optimGrInlMp          :: Grin.GrInlMp        -- inlining map, from name to GrExpr (grin expressions)
      }
%%]]

defaultOptim :: Optim
defaultOptim
  = Optim
%%[[(50 grin)
      Map.empty
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compilation sequence nr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

This is not a necessity, just a gimmick because GHC has it :-).
Ok, it is useful to see how much is done.

%%[99 export(EHCCompileSeqNr(..))
data EHCCompileSeqNr
  = EHCCompileSeqNr
      { ecseqnrThis     :: !Int
      , ecseqnrTotal    :: !Int
      }
  deriving (Eq,Ord)

zeroEHCCompileSeqNr :: EHCCompileSeqNr
zeroEHCCompileSeqNr = EHCCompileSeqNr 0 0

instance Show EHCCompileSeqNr where
  show (EHCCompileSeqNr this total)
    = "[" ++ replicate (length tot - length ths) ' ' ++ ths ++ "/" ++ tot ++ "]"
    where tot = show total
          ths = show this
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compilation unit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(EHCompileUnit(..))
data EHCompileUnit
  = EHCompileUnit
      { ecuSrcFilePath       :: !FPath
%%[[99
      , ecuMbCppFilePath     :: !(Maybe FPath)
%%]]
      , ecuFileLocation      :: !FileLoc
      , ecuGrpNm             :: !HsName
      , ecuModNm             :: !HsName
      , ecuMbHS              :: !(Maybe HS.AGItf)
      , ecuMbHSSem           :: !(Maybe HSSem.Syn_AGItf)
      , ecuMbEH              :: !(Maybe EH.AGItf)
      , ecuMbEHSem           :: !(Maybe EHSem.Syn_AGItf)
%%[[(8 codegen)
      , ecuMbCore            :: !(Maybe Core.CModule)
%%]]
%%[[(8 codegen core)
      , ecuMbCoreSem         :: !(Maybe Core2GrSem.Syn_CodeAGItf)
%%]]
%%[[(8 codegen corein)
      , ecuMbCoreSemMod      :: !(Maybe Core2ChkSem.Syn_CodeAGItf)
%%]]
%%[[(8 codegen tycore)
      , ecuMbTyCore          :: !(Maybe C.Module)
%%]]
%%[[(8 grin)
      , ecuMbGrin            :: !(Maybe Grin.GrModule)
      , ecuMbBytecode        :: !(Maybe Bytecode.Module)
      , ecuMbBytecodeSem     :: !(Maybe PP_Doc)
%%]]
%%[[(8 cmm)
      , ecuMbCmm             :: !(Maybe Cmm.Module)
%%]]
%%[[(8 jazy)
      , ecuMbJVMClassL       :: !(Maybe (HsName,[Jvm.Class]))
%%]]
%%[[(8 javascript)
      , ecuMbJavaScript      :: !(Maybe JS.JavaScriptModule)
%%]]
      , ecuState             :: !EHCompileUnitState
%%[[50
      , ecuImportUsedModules :: !ImportUsedModules                  -- imported modules info
      , ecuIsTopMod          :: !Bool                               -- module has been specified for compilation on commandline
      , ecuHasMain           :: !Bool                               -- has a def for 'main'?
      , ecuNeedsCompile      :: !Bool                               -- (re)compilation from .hs needed?
      , ecuMbSrcTime         :: !(Maybe ClockTime)                  -- timestamp of possibly absent source (hs, or other type) file
      , ecuMbHIInfoTime      :: !(Maybe ClockTime)                  -- timestamp of possibly previously generated hi file
%%[[(8 codegen)
      , ecuMbCoreTime        :: !(Maybe ClockTime)                  -- timestamp of possibly previously generated core file
%%]]
%%[[(8 codegen grin)
      , ecuMbGrinTime        :: !(Maybe ClockTime)                  -- timestamp of possibly previously generated grin file
%%]]
      , ecuMbHSSemMod        :: !(Maybe HSSemMod.Syn_AGItf)
      , ecuMod               :: !Mod                                -- import/export info of module
      , ecuMbPrevHIInfo      :: !(Maybe HI.HIInfo)                  -- possible HI info of previous run
      , ecuMbOptim           :: !(Maybe Optim)
      , ecuHIInfo            :: !HI.HIInfo                          -- HI info of module
      , ecuDirIsWritable     :: !Bool                               -- can be written in dir of module?
%%]]
%%[[99
      , ecuMbOpts            :: (Maybe EHCOpts)                     -- possibly per module adaption of options (caused by pragmas)
      , ecuTarget            :: Target                              -- target for which we compile
      , ecuPragmas           :: !(Set.Set Pragma.Pragma)            -- pragmas of module
      , ecuUsedNames         :: ModEntRelFilterMp                   -- map holding actually used names, to later filter cache of imported hi's to be included in this module's hi
      , ecuSeqNr             :: !EHCCompileSeqNr                    -- sequence nr of sorted compilation
%%]]
%%[[(99 codegen)
      , ecuGenCodeFiles      :: ![FPath]                            -- generated code files
%%]]
      }
%%]

%%[50 export(ecuHSDeclImpNmS, ecuHIDeclImpNmS, ecuHIUsedImpNmS)
ecuHSDeclImpNmS = iumHSDeclModules . ecuImportUsedModules
ecuHIDeclImpNmS = iumHIDeclModules . ecuImportUsedModules
ecuHIUsedImpNmS = iumHIUsedModules . ecuImportUsedModules
%%]

%%[8 export(ecuFilePath)
ecuFilePath :: EHCompileUnit -> FPath
ecuFilePath ecu
%%[[8
  = ecuSrcFilePath ecu
%%][99
  = maybe (ecuSrcFilePath ecu) id (ecuMbCppFilePath ecu)
%%]]
%%]

%%[50 export(ecuIsMainMod)
ecuIsMainMod :: EHCompileUnit -> Bool
ecuIsMainMod e = ecuIsTopMod e && ecuHasMain e
%%]

%%[99 export(ecuAnHIInfo)
-- | give the current value HIInfo, or the previous one
ecuAnHIInfo :: EHCompileUnit -> HI.HIInfo
ecuAnHIInfo e
  = case ecuMbPrevHIInfo e of
      Just pi | HI.hiiIsEmpty hii
        -> pi
      _ -> hii
  where hii = ecuHIInfo e
%%]

%%[8 export(emptyECU)
emptyECU :: EHCompileUnit
emptyECU
  = EHCompileUnit
      { ecuSrcFilePath       = emptyFPath
%%[[99
      , ecuMbCppFilePath     = Nothing
%%]]
      , ecuFileLocation      = emptyFileLoc
      , ecuGrpNm             = hsnUnknown
      , ecuModNm             = hsnUnknown
      , ecuMbHS              = Nothing
      , ecuMbHSSem           = Nothing
      , ecuMbEH              = Nothing
      , ecuMbEHSem           = Nothing
%%[[102
%%]]
%%[[(8 codegen)
      , ecuMbCore            = Nothing
%%]]
%%[[(8 codegen core)
      , ecuMbCoreSem         = Nothing
%%]]
%%[[(8 codegen corein)
      , ecuMbCoreSemMod      = Nothing
%%]]
%%[[(8 codegen tycore)
      , ecuMbTyCore          = Nothing
%%]]
%%[[(8 grin)
      , ecuMbGrin            = Nothing
      , ecuMbBytecode        = Nothing
      , ecuMbBytecodeSem     = Nothing
%%]]
%%[[(8 cmm)
      , ecuMbCmm             = Nothing
%%]]
%%[[(8 jazy)
      , ecuMbJVMClassL       = Nothing
%%]]
%%[[(8 javascript)
      , ecuMbJavaScript      = Nothing
%%]]
      , ecuState             = ECUS_Unknown
%%[[50
      , ecuImportUsedModules = emptyImportUsedModules
      , ecuIsTopMod          = False
      , ecuHasMain           = False
      , ecuNeedsCompile      = True
      , ecuMbSrcTime         = Nothing
      , ecuMbHIInfoTime      = Nothing
%%[[(50 codegen)
      , ecuMbCoreTime        = Nothing
%%]]
%%[[(50 codegen grin)
      , ecuMbGrinTime        = Nothing
%%]]
      , ecuMbHSSemMod        = Nothing
      , ecuMod               = emptyMod
      , ecuMbPrevHIInfo      = Nothing
      , ecuMbOptim           = Nothing
      , ecuHIInfo            = HI.emptyHIInfo
      , ecuDirIsWritable     = False
%%]]
%%[[99
      , ecuMbOpts            = Nothing
      , ecuTarget            = defaultTarget
      , ecuPragmas           = Set.empty
      , ecuUsedNames         = Map.empty
      , ecuSeqNr             = zeroEHCCompileSeqNr
%%]]
%%[[(99 codegen)
      , ecuGenCodeFiles      = []
%%]]
      }
%%]
      , ecuMbEHSem2          = Nothing

%%[50 export(ecuImpNmS,ecuImpNmL)
ecuImpNmS :: EHCompileUnit -> Set.Set HsName
ecuImpNmS ecu = -- (\v -> tr "XX" (pp $ Set.toList v) v) $
  Set.delete (ecuModNm ecu) $ Set.unions [ ecuHSDeclImpNmS ecu, ecuHIDeclImpNmS ecu, ecuHIUsedImpNmS ecu ] 

ecuImpNmL :: EHCompileUnit -> [HsName]
ecuImpNmL = Set.toList . ecuImpNmS -- ecu = (nub $ ecuHSDeclImpNmL ecu ++ ecuHIDeclImpNmL ecu ++ ecuHIUsedImpNmL ecu) \\ [ecuModNm ecu]
%%]

%%[50 export(ecuTransClosedUsedModMp, ecuTransClosedOrphanModS)
-- | The used modules, for linking, according to .hi info
ecuTransClosedUsedModMp :: EHCompileUnit -> HI.HIInfoUsedModMp
ecuTransClosedUsedModMp = HI.hiiTransClosedUsedModMp . ecuAnHIInfo

-- | The orphan modules, must be .hi read, according to .hi info
ecuTransClosedOrphanModS :: EHCompileUnit -> Set.Set HsName
ecuTransClosedOrphanModS = HI.hiiTransClosedOrphanModS . ecuAnHIInfo
%%]

%%[50 export(ecuIsOrphan)
-- | Is orphan, according to .hi info
ecuIsOrphan :: EHCompileUnit -> Bool
%%[[(50 hmtyinfer codegen)
ecuIsOrphan = isJust . HI.hiiMbOrphan . ecuAnHIInfo
%%][50
ecuIsOrphan = const False
%%]]
%%]

%%[5050 export(ecuIsFromCoreSrc)
-- | Is compilation from Core source
ecuIsFromCoreSrc :: EHCompileUnit -> Bool
ecuIsFromCoreSrc = ecuStateIsCore . ecuState
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% State of compilation unit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
instance CompileUnitState EHCompileUnitState where
  cusDefault      = ECUS_Eh EHStart
  cusUnk          = ECUS_Unknown
  cusIsUnk        = (==ECUS_Unknown)
%%]
%%[8.cusIsImpKnown
  cusIsImpKnown _ = True
%%]
%%[50 -8.cusIsImpKnown
  cusIsImpKnown s = case s of
                      ECUS_Haskell HSOnlyImports  -> True
                      ECUS_Haskell HIOnlyImports  -> True
                      ECUS_Haskell HMOnlyMinimal  -> True
%%[[99
                      ECUS_Haskell LHSOnlyImports -> True
%%]]
                      ECUS_Haskell HSAllSem       -> True
                      ECUS_Haskell HIAllSem       -> True
%%[[(50 corein)
                      ECUS_Core    CROnlyImports  -> True
%%]]
                      _                           -> False
%%]

%%[8
instance FileLocatable EHCompileUnit FileLoc where
  fileLocation   = ecuFileLocation
  noFileLocation = emptyFileLoc
%%]

%%[8
instance CompileUnit EHCompileUnit HsName FileLoc EHCompileUnitState where
  cuDefault         = emptyECU
  cuFPath           = ecuFilePath
  cuLocation        = fileLocation
  cuKey             = ecuModNm
  cuState           = ecuState
  cuUpdFPath        = ecuStoreSrcFilePath
  cuUpdLocation     = ecuStoreFileLocation
  cuUpdState        = ecuStoreState
  cuUpdKey   nm u   = u {ecuModNm = nm}
%%[[8
  cuImports         = const []
%%][50
  cuImports         = ecuImpNmL
%%]]
%%[[(99 codegen)
  cuParticipation u = if not (Set.null $ Set.filter (Pragma.pragmaIsExcludeTarget $ ecuTarget u) $ ecuPragmas u)
                      then [CompileParticipation_NoImport]
                      else []
%%][99
  cuParticipation u = []
%%]]

instance FPathError Err

instance CompileRunError Err () where
  crePPErrL                      = ppErrL
  creMkNotFoundErrL _ fp sp sufs = [rngLift emptyRange Err_FileNotFound fp sp sufs]
  creAreFatal                    = errLIsFatal

instance CompileModName HsName where
  mkCMNm = hsnFromString

instance Show EHCompileUnit where
  show _ = "EHCompileUnit"

instance PP EHCompileUnit where
  pp ecu
    = ecuModNm ecu >|<
%%[[50
      ":" >#< ppBracketsCommas (ecuImpNmL ecu) >|<
%%]]
      "," >#< show (ecuState ecu)
%%]

%%[8 export(ecuFinalDestinationState)
-- | The final state to be reached
ecuFinalDestinationState :: EHCompileUnit -> EHCompileUnitState
ecuFinalDestinationState ecu = ecuStateFinalDestination upd $ ecuState ecu
  where upd (ECUS_Haskell _)
          | ecuNeedsCompile ecu = ECUS_Haskell HSAllSem
          | otherwise           = ECUS_Haskell HIAllSem
        upd s                   = s
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Storing into an EHCompileUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(EcuUpdater,ecuStoreSrcFilePath,ecuStoreState,ecuStoreHS,ecuStoreEH,ecuStoreHSSem,ecuStoreEHSem)
type EcuUpdater a = a -> EHCompileUnit -> EHCompileUnit

ecuStoreSrcFilePath :: EcuUpdater FPath
ecuStoreSrcFilePath x ecu = ecu { ecuSrcFilePath = x }

ecuStoreFileLocation :: EcuUpdater FileLoc
ecuStoreFileLocation x ecu = ecu { ecuFileLocation = x }

ecuStoreState :: EcuUpdater EHCompileUnitState
ecuStoreState x ecu = ecu { ecuState = x }

ecuStoreHS :: EcuUpdater HS.AGItf
ecuStoreHS x ecu = ecu { ecuMbHS = Just x }

ecuStoreEH :: EcuUpdater EH.AGItf
ecuStoreEH x ecu = ecu { ecuMbEH = Just x }

ecuStoreHSSem :: EcuUpdater HSSem.Syn_AGItf
ecuStoreHSSem x ecu = ecu { ecuMbHSSem = Just x }

ecuStoreEHSem :: EcuUpdater EHSem.Syn_AGItf
ecuStoreEHSem x ecu = ecu { ecuMbEHSem = Just x }
%%]

%%[(8 codegen corein) export(ecuStoreCoreSemMod)
ecuStoreCoreSemMod :: EcuUpdater Core2ChkSem.Syn_CodeAGItf
ecuStoreCoreSemMod x ecu = ecu { ecuMbCoreSemMod = Just x }
%%]

%%[(8 codegen core) export(ecuStoreCoreSem)
ecuStoreCoreSem :: EcuUpdater Core2GrSem.Syn_CodeAGItf
ecuStoreCoreSem x ecu = ecu { ecuMbCoreSem = Just x }
%%]

%%[(8 codegen) export(ecuStoreCore)
ecuStoreCore :: EcuUpdater Core.CModule
%%[[8
ecuStoreCore x ecu = ecu { ecuMbCore = Just x }
%%][99
ecuStoreCore x ecu | x `seq` True = ecu { ecuMbCore = Just x }
%%][9999
ecuStoreCore x ecu | forceEval x `seq` True = ecu { ecuMbCore = Just x }
%%]]
%%]

%%[(8 codegen tycore) export(ecuStoreTyCore)
ecuStoreTyCore :: EcuUpdater C.Module
ecuStoreTyCore x ecu = ecu { ecuMbTyCore = Just x }
%%]

%%[(8 jazy) export(ecuStoreJVMClassL)
ecuStoreJVMClassL :: EcuUpdater (HsName,[Jvm.Class])
ecuStoreJVMClassL x ecu = ecu { ecuMbJVMClassL = Just x }
%%]

%%[(8 javascript) export(ecuStoreJavaScript)
ecuStoreJavaScript :: EcuUpdater (JS.JavaScriptModule)
ecuStoreJavaScript x ecu = ecu { ecuMbJavaScript = Just x }
%%]

ecuStoreJVMClassFPathL :: EcuUpdater [FPath]
ecuStoreJVMClassFPathL x ecu = ecu { ecuMbJVMClassL = Just (Right x) }

%%[(8 grin) export(ecuStoreGrin,ecuStoreBytecode,ecuStoreBytecodeSem)
ecuStoreGrin :: EcuUpdater Grin.GrModule
%%[[8
ecuStoreGrin x ecu = ecu { ecuMbGrin = Just x }
%%][99
ecuStoreGrin x ecu | x `seq` True = ecu { ecuMbGrin = Just x }
%%][9999
ecuStoreGrin x ecu | forceEval x `seq` True = ecu { ecuMbGrin = Just x }
%%]]

ecuStoreBytecode :: EcuUpdater Bytecode.Module
%%[[8
ecuStoreBytecode x ecu = ecu { ecuMbBytecode = Just x }
%%][99
ecuStoreBytecode x ecu | x `seq` True = ecu { ecuMbBytecode = Just x }
%%][9999
ecuStoreBytecode x ecu | forceEval x `seq` True = ecu { ecuMbBytecode = Just x }
%%]]

ecuStoreBytecodeSem :: EcuUpdater PP_Doc
ecuStoreBytecodeSem x ecu = ecu { ecuMbBytecodeSem = Just x }
%%]

%%[(8 codegen cmm) export(ecuStoreCmm)
ecuStoreCmm :: EcuUpdater Cmm.Module
ecuStoreCmm x ecu = ecu { ecuMbCmm = Just x }
%%]

%%[50 export(ecuStoreHSDeclImpS,ecuSetNeedsCompile,ecuStoreHIUsedImpS,ecuStoreHIInfoTime,ecuStoreSrcTime,ecuStoreHSSemMod,ecuStoreIntrodModS,ecuStoreHIDeclImpS,ecuStoreMod,ecuSetIsTopMod,ecuSetHasMain,ecuStoreOptim,ecuStoreHIInfo,ecuStorePrevHIInfo)
ecuStoreSrcTime :: EcuUpdater ClockTime
ecuStoreSrcTime x ecu = ecu { ecuMbSrcTime = Just x }

-- ecuStoreHITime :: EcuUpdater ClockTime
-- ecuStoreHITime x ecu = ecu { ecuMbHITime = Just x }

ecuStoreHIInfoTime :: EcuUpdater ClockTime
ecuStoreHIInfoTime x ecu = ecu { ecuMbHIInfoTime = Just x }

ecuStoreHSSemMod :: EcuUpdater HSSemMod.Syn_AGItf
ecuStoreHSSemMod x ecu = ecu { ecuMbHSSemMod = Just x }

ecuStoreHSDeclImpS :: EcuUpdater (Set.Set HsName)
ecuStoreHSDeclImpS x ecu = ecu { ecuImportUsedModules = ium {iumHSDeclModules = x} }
  where ium = ecuImportUsedModules ecu

ecuStoreHIDeclImpS :: EcuUpdater (Set.Set HsName)
ecuStoreHIDeclImpS x ecu = ecu { ecuImportUsedModules = ium {iumHIDeclModules = x} }
  where ium = ecuImportUsedModules ecu

ecuStoreHIUsedImpS :: EcuUpdater (Set.Set HsName)
ecuStoreHIUsedImpS x ecu = ecu { ecuImportUsedModules = ium {iumHIUsedModules = x} }
  where ium = ecuImportUsedModules ecu

ecuStoreIntrodModS :: EcuUpdater (Set.Set HsName)
ecuStoreIntrodModS x ecu = ecu { ecuImportUsedModules = ium {iumIntrodModules = x} }
  where ium = ecuImportUsedModules ecu

ecuStoreMod :: EcuUpdater Mod
ecuStoreMod x ecu = ecu { ecuMod = x }

ecuSetIsTopMod :: EcuUpdater Bool
ecuSetIsTopMod x ecu = ecu { ecuIsTopMod = x }

ecuSetHasMain :: EcuUpdater Bool
ecuSetHasMain x ecu = ecu { ecuHasMain = x }

ecuSetNeedsCompile :: EcuUpdater Bool
ecuSetNeedsCompile x ecu = ecu { ecuNeedsCompile = x }

-- ecuStorePrevHI :: EcuUpdater HI.AGItf
-- ecuStorePrevHI x ecu = ecu { ecuMbPrevHI = Just x }

-- ecuStorePrevHISem :: EcuUpdater HISem.Syn_AGItf
-- ecuStorePrevHISem x ecu = ecu { ecuMbPrevHISem = Just x }

ecuStorePrevHIInfo :: EcuUpdater HI.HIInfo
ecuStorePrevHIInfo x ecu = ecu { ecuMbPrevHIInfo = Just x }

ecuStoreOptim :: EcuUpdater Optim
ecuStoreOptim x ecu = ecu { ecuMbOptim = Just x }

ecuStoreHIInfo :: EcuUpdater HI.HIInfo
%%[[8
ecuStoreHIInfo x ecu = ecu { ecuHIInfo = x }
%%][99
ecuStoreHIInfo x ecu | x `seq` True = ecu { ecuHIInfo = x }
%%][9999
ecuStoreHIInfo x ecu | forceEval x `seq` True = ecu { ecuHIInfo = x }
%%]]
%%]

%%[(50 codegen) export(ecuStoreCoreTime)
ecuStoreCoreTime :: EcuUpdater ClockTime
ecuStoreCoreTime x ecu = ecu { ecuMbCoreTime = Just x }
%%]

%%[(50 codegen grin) export(ecuStoreGrinTime)
ecuStoreGrinTime :: EcuUpdater ClockTime
ecuStoreGrinTime x ecu = ecu { ecuMbGrinTime = Just x }
%%]

%%[50 export(ecuStoreDirIsWritable)
ecuStoreDirIsWritable :: EcuUpdater Bool
ecuStoreDirIsWritable x ecu = ecu { ecuDirIsWritable = x }
%%]

%%[99 export(ecuStoreOpts,ecuStorePragmas,ecuStoreUsedNames,ecuSetTarget)
ecuStoreOpts :: EcuUpdater EHCOpts
ecuStoreOpts x ecu = ecu { ecuMbOpts = Just x }

ecuSetTarget :: EcuUpdater Target
ecuSetTarget x ecu = ecu { ecuTarget = x }

ecuStorePragmas :: EcuUpdater (Set.Set Pragma.Pragma)
ecuStorePragmas x ecu = ecu { ecuPragmas = x }

ecuStoreUsedNames :: EcuUpdater ModEntRelFilterMp
ecuStoreUsedNames x ecu = ecu { ecuUsedNames = x }
%%]

%%[(99 codegen) export(ecuStoreGenCodeFiles)
ecuStoreGenCodeFiles :: EcuUpdater [FPath]
ecuStoreGenCodeFiles x ecu = ecu { ecuGenCodeFiles = x }
%%]

%%[99 export(ecuStoreCppFilePath,ecuStoreSeqNr)
ecuStoreSeqNr :: EcuUpdater EHCCompileSeqNr
ecuStoreSeqNr x ecu = ecu { ecuSeqNr = x }

ecuStoreCppFilePath :: EcuUpdater FPath
ecuStoreCppFilePath x ecu = ecu { ecuMbCppFilePath = Just x }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Predicates on EHCompileUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(ecuIsHSNewerThanHI)
-- | Is HS newer?
--   If no HS exists False is returned.
ecuIsHSNewerThanHI :: EHCompileUnit -> Bool
ecuIsHSNewerThanHI ecu
  = case (ecuMbSrcTime ecu,ecuMbHIInfoTime ecu) of
      (Just ths,Just thi) -> ths `diffClockTimes` thi > noTimeDiff 
      (Nothing ,Just thi) -> False
      _                   -> True
%%]

%%[5020 export(ecuIsValidHI)
ecuIsValidHI :: EHCompileUnit -> Bool
ecuIsValidHI ecu
  = case ecuMbPrevHISem ecu of
      Just s -> HISem.isValidVersion_Syn_AGItf s
      _      -> False
%%]

%%[50 export(ecuIsValidHIInfo)
ecuIsValidHIInfo :: EHCompileUnit -> Bool
ecuIsValidHIInfo ecu
  = case ecuMbPrevHIInfo ecu of
      Just i -> HI.hiiValidity i == HI.HIValidity_Ok
      _      -> False
%%]

%%[50 export(ecuCanUseHIInsteadOfHS)
-- | Can HI be used instead of HS?
--   This is purely based on HI being of the right version and HS not newer.
--   The need for recompilation considers dependencies on imports as well.
ecuCanUseHIInsteadOfHS :: EHCompileUnit -> Bool
ecuCanUseHIInsteadOfHS ecu
  = ecuIsValidHIInfo ecu && not (ecuIsHSNewerThanHI ecu)
%%]

