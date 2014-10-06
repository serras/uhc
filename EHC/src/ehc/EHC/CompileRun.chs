%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EHC Compile Run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

An EHC compile run maintains info for one compilation invocation

%%[8 module {%{EH}EHC.CompileRun}
%%]

-- general imports
%%[8 import(qualified Data.Map as Map,qualified Data.Set as Set)
%%]
%%[8 import(System.IO, System.Exit, System.Environment, System.Process)
%%]
%%[99 import(UHC.Util.Time, System.CPUTime, System.Locale, Data.IORef, System.IO.Unsafe)
%%]
%%[99 import(System.Directory)
%%]
%%[8 import(Control.Monad.State)
%%]
%%[99 import(Control.Exception as CE)
%%]
%%[99 import(UHC.Util.FPath)
%%]
%%[99 import({%{EH}Base.PackageDatabase})
%%]

%%[(8 codegen) hs import({%{EH}CodeGen.ValAccess} as VA)
%%]

%%[8 import({%{EH}EHC.Common})
%%]
%%[8 import({%{EH}EHC.CompileUnit})
%%]
%%[50 import({%{EH}EHC.CompileGroup})
%%]
-- Language syntax: Core
%%[(8 codegen) import( qualified {%{EH}Core} as Core)
%%]
-- Language syntax: TyCore
%%[(8 codegen tycore) import(qualified {%{EH}TyCore} as C)
%%]
-- Language semantics: HS, EH
%%[8 import(qualified {%{EH}EH.MainAG} as EHSem, qualified {%{EH}HS.MainAG} as HSSem)
%%]
-- Language semantics: Core
%%[(8 core) import(qualified {%{EH}Core.ToGrin} as Core2GrSem)
%%]

-- HI Syntax and semantics, HS module semantics
%%[5050 import(qualified {%{EH}HI} as HI)
%%]
%%[50 import(qualified {%{EH}HS.ModImpExp} as HSSemMod)
%%]
-- module admin
%%[50 import({%{EH}Module.ImportExport})
%%]

-- Misc
%%[102 import({%{EH}Debug.HighWaterMark})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(EHCTime, EHCTimeDiff, getEHCTime, ehcTimeDiff, ehcTimeDiffFmt)
type EHCTime = Integer
type EHCTimeDiff = Integer

getEHCTime :: IO EHCTime
getEHCTime = getCPUTime

ehcTimeDiff :: EHCTime -> EHCTime -> EHCTimeDiff
ehcTimeDiff = (-)

ehcTimeDiffFmt :: EHCTimeDiff -> String
ehcTimeDiffFmt t
  = fm 2 hrs ++ ":" ++ fm 2 mins ++ ":" ++ fm 2 secs ++ ":" ++ fm 6 (psecs `div` 1000000)
  where (r0  , psecs) = t  `quotRem` 1000000000000
        (r1  , secs ) = r0 `quotRem` 60
        (r2  , mins ) = r1 `quotRem` 60
        (days, hrs  ) = r2 `quotRem` 24
        fm n x = strPadLeft '0' n (show x)
%%]

%%[99 export(EHCIOInfo(..),newEHCIOInfo)
data EHCIOInfo
  = EHCIOInfo
      { ehcioinfoStartTime			:: EHCTime
      , ehcioinfoLastTime			:: EHCTime
      }

newEHCIOInfo :: IO (IORef EHCIOInfo)
newEHCIOInfo
  = do t <- getEHCTime
       newIORef (EHCIOInfo t t)
%%]

%%[99
%%]

%%[9999 export(unsafeTimedPerformIO)
-- | Unsafe do IO with timing info
unsafeTimedPerformIO
  :: IORef EHCIOInfo
     -> IO a
     -> ( a
        , EHCTime				-- last time being called
        , EHCTimeDiff			-- delta since that time
        )
unsafeTimedPerformIO inforef io
  = unsafePerformIO $
    do info <- readIORef inforef
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile run combinators
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(EHCompileRunStateInfo(..))
data EHCompileRunStateInfo
  = EHCompileRunStateInfo
      { crsiOpts        :: !EHCOpts                             -- options
      , crsiNextUID     :: !UID                                 -- unique id, the next one
      , crsiHereUID     :: !UID                                 -- unique id, the current one
      , crsiHSInh       :: !HSSem.Inh_AGItf                     -- current inh attrs for HS sem
      , crsiEHInh       :: !EHSem.Inh_AGItf                     -- current inh attrs for EH sem
%%[[(8 codegen)
      , crsiCoreInh     :: !Core2GrSem.Inh_CodeAGItf            -- current inh attrs for Core2Grin sem
%%]]
%%[[50
      , crsiMbMainNm    :: !(Maybe HsName)                      -- name of main module, if any
      , crsiHSModInh    :: !HSSemMod.Inh_AGItf                  -- current inh attrs for HS module analysis sem
      , crsiModMp       :: !ModMp                               -- import/export info for modules
      , crsiGrpMp       :: (Map.Map HsName EHCompileGroup)      -- not yet used, for mut rec modules
      , crsiOptim       :: !Optim                               -- inter module optimisation info
%%]]
%%[[(50 codegen)
      , crsiModOffMp    :: !VA.HsName2FldMpMp              		-- mapping of all modules + exp entries to offsets in module + exp tables
%%]]
%%[[99
      , crsiEHCIOInfo	:: !(IORef EHCIOInfo)					-- unsafe info
      , crsiFilesToRm   :: ![FPath]                             -- files to clean up (remove)
%%]]
      }
%%]

%%[8 export(emptyEHCompileRunStateInfo)
emptyEHCompileRunStateInfo :: EHCompileRunStateInfo
emptyEHCompileRunStateInfo
  = EHCompileRunStateInfo
      { crsiOpts        =   defaultEHCOpts
      , crsiNextUID     =   uidStart
      , crsiHereUID     =   uidStart
      , crsiHSInh       =   panic "emptyEHCompileRunStateInfo.crsiHSInh"
      , crsiEHInh       =   panic "emptyEHCompileRunStateInfo.crsiEHInh"
%%[[(8 codegen)
      , crsiCoreInh     =   panic "emptyEHCompileRunStateInfo.crsiCoreInh"
%%]]
%%[[50
      , crsiMbMainNm    =   Nothing
      , crsiHSModInh    =   panic "emptyEHCompileRunStateInfo.crsiHSModInh"
      , crsiModMp       =   Map.empty
      , crsiGrpMp       =   Map.empty
      , crsiOptim       =   defaultOptim
%%]]
%%[[(50 codegen)
      , crsiModOffMp    =   Map.empty
%%]]
%%[[99
      , crsiEHCIOInfo   =   panic "emptyEHCompileRunStateInfo.crsiEHCIOInfo"
      , crsiFilesToRm   =   []
%%]]
      }
%%]

%%[(50 codegen) export(crsiExpNmOffMp)
crsiExpNmOffMp :: HsName -> EHCompileRunStateInfo -> VA.HsName2FldMp
crsiExpNmOffMp modNm crsi = mmiNmOffMp $ panicJust ("crsiExpNmOffMp: " ++ show modNm) $ Map.lookup modNm $ crsiModMp crsi
%%]

%%[50
instance Show EHCompileRunStateInfo where
  show _ = "EHCompileRunStateInfo"

instance PP EHCompileRunStateInfo where
  pp i = "CRSI:" >#< ppModMp (crsiModMp i)
%%]

%%[8
instance CompileRunStateInfo EHCompileRunStateInfo HsName () where
  crsiImportPosOfCUKey n i = ()
%%]

%%[8 export(EHCompileRun,EHCompilePhase)
type EHCompileRun     = CompileRun   HsName EHCompileUnit EHCompileRunStateInfo Err
type EHCompilePhase a = CompilePhase HsName EHCompileUnit EHCompileRunStateInfo Err a
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile Run base info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(crBaseInfo,crBaseInfo')
crBaseInfo' :: EHCompileRun -> (EHCompileRunStateInfo,EHCOpts)
crBaseInfo' cr
  = (crsi,opts)
  where crsi   = crStateInfo cr
        opts   = crsiOpts  crsi

crBaseInfo :: HsName -> EHCompileRun -> (EHCompileUnit,EHCompileRunStateInfo,EHCOpts,FPath)
crBaseInfo modNm cr
  = ( ecu ,crsi
%%[[8
    , opts
%%][99
    -- if any per module opts are available, use those
    , maybe opts id $ ecuMbOpts ecu
%%]]
    , fp
    )
  where ecu         = crCU modNm cr
        (crsi,opts) = crBaseInfo' cr
        fp          = ecuFilePath ecu
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: debug info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
cpMemUsage :: EHCompilePhase ()
cpMemUsage
%%[[8
  = return ()
%%][102
  = do { cr <- get
       ; let (crsi,opts) = crBaseInfo' cr
       ; size <- lift $ megaBytesAllocated
       ; when (ehcOptVerbosity opts >= VerboseDebug)
              (lift $ putStrLn ("Mem: " ++ show size ++ "M"))
       }
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Update state
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Update: options, additional exports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(cpUpdOpts)
cpUpdOpts :: (EHCOpts -> EHCOpts) -> EHCompilePhase ()
cpUpdOpts upd
  = cpUpdSI (\crsi -> crsi {crsiOpts = upd $ crsiOpts crsi})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: clean up (remove) files to be removed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(cpRegisterFilesToRm)
cpRegisterFilesToRm :: [FPath] -> EHCompilePhase ()
cpRegisterFilesToRm fpL
  = cpUpdSI (\crsi -> crsi {crsiFilesToRm = fpL ++ crsiFilesToRm crsi})
%%]

%%[99 export(cpRmFilesToRm)
cpRmFilesToRm :: EHCompilePhase ()
cpRmFilesToRm
  = do { cr <- get
       ; let (crsi,opts) = crBaseInfo' cr
             files = Set.toList $ Set.fromList $ map fpathToStr $ crsiFilesToRm crsi
       ; lift $ mapM rm files
       ; cpUpdSI (\crsi -> crsi {crsiFilesToRm = []})
       }
  where rm f = CE.catch (removeFile f)
                        (\(e :: SomeException) -> hPutStrLn stderr (show f ++ ": " ++ show e))
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: message
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(cpMsg,cpMsg')
cpMsg :: HsName -> Verbosity -> String -> EHCompilePhase ()
cpMsg modNm v m
  = do { cr <- get
       ; let (_,_,_,fp) = crBaseInfo modNm cr
       ; cpMsg' modNm v m Nothing fp
       }

cpMsg' :: HsName -> Verbosity -> String -> Maybe String -> FPath -> EHCompilePhase ()
cpMsg' modNm v m mbInfo fp
  = do { cr <- get
       ; let (ecu,crsi,opts,_) = crBaseInfo modNm cr
%%[[99
       ; ehcioinfo <- lift $ readIORef (crsiEHCIOInfo crsi)
       ; clockTime <- lift getEHCTime
       ; let clockStartTimePrev = ehcioinfoStartTime ehcioinfo
             clockTimePrev      = ehcioinfoLastTime ehcioinfo
             clockStartTimeDiff = ehcTimeDiff clockTime clockStartTimePrev
             clockTimeDiff      = ehcTimeDiff clockTime clockTimePrev
%%]]
       ; let
%%[[8
             m'             = m
%%][99
             t				= if v >= VerboseALot then "<" ++ strBlankPad 35 (ehcTimeDiffFmt clockStartTimeDiff ++ "/" ++ ehcTimeDiffFmt clockTimeDiff) ++ ">" else ""
             m'             = show (ecuSeqNr ecu) ++ t ++ " " ++ m
%%]]
       ; lift $ putCompileMsg v (ehcOptVerbosity opts) m' mbInfo modNm fp
%%[[99
       ; clockTime <- lift getEHCTime
       ; lift $ writeIORef (crsiEHCIOInfo crsi) (ehcioinfo {ehcioinfoLastTime = clockTime})
       -- ; cpUpdSI (\crsi -> crsi { crsiTime = clockTime })
%%]]
       ; cpMemUsage
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: step/set unique counter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(cpStepUID,cpSetUID)
cpStepUID :: EHCompilePhase ()
cpStepUID
  = cpUpdSI (\crsi -> let (n,h) = mkNewLevUID (crsiNextUID crsi)
                      in  crsi {crsiNextUID = n, crsiHereUID = h}
            )

cpSetUID :: UID -> EHCompilePhase ()
cpSetUID u
  = cpUpdSI (\crsi -> crsi {crsiNextUID = u})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: shell/system/cmdline invocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(cpSystem',cpSystem)
cpSystem' :: Maybe FilePath -> (FilePath,[String]) -> EHCompilePhase ()
cpSystem' mbStdOut (cmd,args)
  = do { exitCode <- lift $ system $ showShellCmd $ (cmd,args ++ (maybe [] (\o -> [">", o]) mbStdOut))
       ; case exitCode of
           ExitSuccess -> return ()
           _           -> cpSetFail
       }

cpSystem :: (FilePath,[String]) -> EHCompilePhase ()
cpSystem = cpSystem' Nothing
%%]
cpSystem' :: (FilePath,[String]) -> Maybe FilePath -> EHCompilePhase ()
cpSystem' (cmd,args) mbStdOut
  = do { exitcode <- lift $ do 
           proc <- runProcess cmd args Nothing Nothing Nothing Nothing Nothing
           waitForProcess proc
       ; case exitCode of
           ExitSuccess -> return ()
           _           -> cpSetFail
       }

cpSystem' :: (FilePath,[String]) -> Maybe FilePath -> EHCompilePhase ()
cpSystem' (cmd,args) mbStdOut
  = do { exitCode <- lift $ system cmd
       ; case exitCode of
           ExitSuccess -> return ()
           _           -> cpSetFail
       }

%%[8 export(cpSystemRaw)
cpSystemRaw :: String -> [String] -> EHCompilePhase ()
cpSystemRaw cmd args
  = do { exitCode <- lift $ rawSystem cmd args
       ; case exitCode of
           ExitSuccess -> return ()
           _           -> cpSetErrs [rngLift emptyRange Err_PP $ pp $ show exitCode] -- cpSetFail
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compile actions: stop at phase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8 export(cpStopAt)
cpStopAt :: CompilePoint -> EHCompilePhase ()
cpStopAt atPhase
  = do { cr <- get
       ; let (_,opts) = crBaseInfo' cr
       ; unless (atPhase < ehcStopAtPoint opts)
                cpSetStopAllSeq
       }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Partition imports into newer + older
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50
crPartitionNewerOlderImports :: HsName -> EHCompileRun -> ([EHCompileUnit],[EHCompileUnit])
crPartitionNewerOlderImports modNm cr
  = partition isNewer $ map (flip crCU cr) $ ecuImpNmL ecu
  where ecu = crCU modNm cr
        t   = panicJust "crPartitionNewerOlderImports1" $ ecuMbHIInfoTime ecu
        isNewer ecu'
            | isJust mbt = t' `diffClockTimes` t > noTimeDiff
            | otherwise  = False
            where t' = panicJust "crPartitionNewerOlderImports2" $ ecuMbHIInfoTime ecu'
                  mbt = ecuMbHIInfoTime ecu'
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Module needs recompilation?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(crModNeedsCompile)
crModNeedsCompile :: HsName -> EHCompileRun -> Bool
crModNeedsCompile modNm cr
  = ecuIsMainMod ecu -- ecuIsTopMod ecu
    || not (  ehcOptCheckRecompile opts
           && ecuCanUseHIInsteadOfHS ecu
           && null newer
           )
  where ecu = crCU modNm cr
        (newer,_) = crPartitionNewerOlderImports modNm cr
        opts = crsiOpts $ crStateInfo cr
%%]
    || (ehcOptCheckVersion opts
        && (  not (ecuCanUseHIInsteadOfHS ecu)
           || not (null newer)
       )   )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compilation can actually be done?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(crModCanCompile)
crModCanCompile :: HsName -> EHCompileRun -> Bool
crModCanCompile modNm cr
  = isJust (ecuMbSrcTime ecu) && ecuDirIsWritable ecu
  where ecu = crCU modNm cr
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Partition modules into those belonging to a package and the rest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(99 codegen) export(crPartitionIntoPkgAndOthers)
-- | split module names in those part of a package, and others
crPartitionIntoPkgAndOthers :: EHCompileRun -> [HsName] -> ([PkgModulePartition],[HsName])
crPartitionIntoPkgAndOthers cr modNmL
  = ( [ (p,d,m)
      | ((p,d),m) <- Map.toList $ Map.unionsWith (++) $ map Map.fromList ps
      ]
    , concat ms
    )
  where (ps,ms) = unzip $ map loc modNmL
        loc m = case filelocKind $ ecuFileLocation ecu of
                  FileLocKind_Dir	  -> ([           ], [m])
                  FileLocKind_Pkg p d -> ([((p,d),[m])], [ ])
              where (ecu,_,_,_) = crBaseInfo m cr
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Set 'main'-ness of module, checking whethere there are not too many modules having a main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(crSetAndCheckMain)
crSetAndCheckMain :: HsName -> EHCompilePhase ()
crSetAndCheckMain modNm
  = do { cr <- get
       ; let (crsi,opts) = crBaseInfo' cr
             mkerr lim ns = cpSetLimitErrs 1 "compilation run" [rngLift emptyRange Err_MayOnlyHaveNrMain lim ns modNm]
       ; case crsiMbMainNm crsi of
           Just n | n /= modNm          -> mkerr 1 [n]
           _ | ehcOptDoExecLinking opts -> cpUpdSI (\crsi -> crsi {crsiMbMainNm = Just modNm})
             | otherwise                -> return ()
                                           -- mkerr 0 []
       }
%%]

