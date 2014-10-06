
%%[0
%include lhs2TeX.fmt
%include afp.fmt
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Options of all sorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 module {%{EH}Opts} import(System.Console.GetOpt,{%{EH}Base.Common}) 
%%]

%%[1 import({%{EH}Opts.Base}) export(module {%{EH}Opts.Base})
%%]

%%[1 import(UHC.Util.Utils)
%%]

%%[1 import(Data.Maybe,qualified Data.Map as Map,Data.Char)
%%]

%%[4 import(UHC.Util.Pretty)
%%]

%%[(4 hmtyinfer || hmtyast) import({%{EH}Ty})
%%]

%%[7 import(qualified Data.Set as Set)
%%]

%%[8 import(Data.List,{%{EH}Base.HsName.Builtin})
%%]

%%[8 import(UHC.Util.FPath)
%%]
%%[8 import({%{EH}EHC.Environment})
%%]

%%[(8 codegen) import({%{EH}Base.Target})
%%]

%%[(8 codegen) import({%{EH}Base.Optimize}) export(Optimize(..), OptimizationLevel(..))
%%]

%%[40 import({%{EH}Ty.Trf.Instantiate})
%%]

%%[8 import({%{EH}Base.FileSearchLocation}) export(module {%{EH}Base.FileSearchLocation})
%%]

%%[(93 hmtyinfer) import({%{EH}Error})
%%]

%%[99 import(qualified {%{EH}Config} as Cfg)
%%]

%%[99 import({%{EH}Base.Pragma}, {%{EH}Opts.CommandLine}, {%{EH}Base.Parser}, {%{EH}Base.Parser2})
%%]

-- debug only
%%[99 import({%{EH}Base.Debug})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Adaption of options by pragmas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(ehcOptUpdateWithPragmas)
-- | possibly adapt with pragmas
ehcOptUpdateWithPragmas :: Set.Set Pragma -> EHCOpts -> (EHCOpts,Bool)
ehcOptUpdateWithPragmas pragmas opts
  = foldr (\p om@(o,modf) -> maybe om (\o -> (o,True)) $ upd p o) (opts,False) (Set.toList pragmas)
  where upd pragma opts
          = case pragma of
              Pragma_NoGenericDeriving  	-> Just $ opts { ehcOptGenGenerics          = False }
              Pragma_GenericDeriving    	-> Just $ opts { ehcOptGenGenerics          = True  }
              Pragma_NoBangPatterns     	-> Just $ opts { ehcOptBangPatterns         = False }
              Pragma_BangPatterns       	-> Just $ opts { ehcOptBangPatterns         = True  }
              Pragma_NoOverloadedStrings	-> Just $ opts { ehcOptOverloadedStrings	= False }
              Pragma_OverloadedStrings		-> Just $ opts { ehcOptOverloadedStrings	= True  }
              Pragma_NoPolyKinds     		-> Just $ opts { ehcOptPolyKinds         	= False }
              Pragma_PolyKinds       		-> Just $ opts { ehcOptPolyKinds         	= True  }
              Pragma_ExtensibleRecords  	-> Just $ opts { ehcOptExtensibleRecords    = True  }
              Pragma_Fusion             	-> Just $ opts { ehcOptFusion               = True  }
              Pragma_OptionsUHC o       	-> fmap (\o -> o {ehcOptCmdLineOptsDoneViaPragma = True}) mo
                                        	where (mo,_,_) = ehcCmdLineOptsApply (words o) opts
              _                         	-> Nothing
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
mkStringPath :: String -> [String]
mkStringPath = wordsBy (`elem` ";,")

mkFileLocPath :: String -> FileLocPath
mkFileLocPath = map mkDirFileLoc . mkStringPath
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Option specific options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 export(optOptsIsYes, showStr2stMp)
optOpts :: Map.Map String opt -> String -> [opt]
optOpts m s = catMaybes $ map (\os -> Map.lookup os m) $ wordsBy (==',') s

optOptsIsYes :: Eq opt => Maybe [opt] -> opt -> Bool
optOptsIsYes mos o = maybe False (o `elem`) mos

%%]

%%[(8 codegen)
instance Show CoreOpt where
%%[[(8 coreout)
  -- show CoreOpt_PPParseable      = "pp-parseable"
  show CoreOpt_Dump             	= "dump"
  show CoreOpt_DumpBinary	      	= "dump-binary"
  show CoreOpt_DumpAlsoNonParseable	= "whendump-alsononparseable"
%%]]
%%[[(8 corerun)
  show CoreOpt_DumpRun            	= "dump-run"
  show CoreOpt_Run            	    = "run"
%%]]
%%[[(8 coresysf)
  show CoreOpt_SysF             	= "sysf"
  show CoreOpt_SysFCheck        	= "check"
  show CoreOpt_SysFCheckOnlyVal 	= "checkonlyval"
  show CoreOpt_SysFOnlyHi       	= "onlyhi"
%%]]
  show _      						= "-"

coreOptMp :: Map.Map String CoreOpt
coreOptMp = str2stMpWithOmit [CoreOpt_NONE]
%%]

%%[(8 codegen tycore)
instance Show TyCoreOpt where
  show TyCoreOpt_Sugar      = "sugar"       -- first letters of alternatives must be unique
  show TyCoreOpt_Unicode    = "unicode"

tycoreOpts :: [TyCoreOpt]
tycoreOpts = [TyCoreOpt_Sugar, TyCoreOpt_Unicode]

tycoreOptMp :: Map.Map String TyCoreOpt
tycoreOptMp
  = Map.fromList $ concat
    $ [ [ (s, o), ([head s], o) ]
      | o <- tycoreOpts
      , let s = show o
      ]
%%]

%%[(8 codegen cmm)
instance Show CmmOpt where
  show CmmOpt_Check        = "check"

cmmOpts :: [CmmOpt]
cmmOpts = [CmmOpt_Check]

cmmOptMp :: Map.Map String CmmOpt
cmmOptMp = str2stMp
%%]

%%[(8 codegen javascript)
javaScriptOptMp :: Map.Map String JavaScriptOpt
javaScriptOptMp = str2stMp
%%]

%%[99
instance Show PgmExec where
  show PgmExec_CPP      = "P"
  show PgmExec_C        = "c"
  show PgmExec_Linker	= "l"

pgmExecMp :: Map.Map String PgmExec
pgmExecMp = str2stMp
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Derived options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Some are there for (temporary) backwards compatibility.

%%[(50 codegen) export(ehcOptWholeProgOptimizationScope)
-- do something with whole program
ehcOptWholeProgOptimizationScope :: EHCOpts -> Bool
ehcOptWholeProgOptimizationScope opts
  = ehcOptOptimizationScope opts > OptimizationScope_PerModule
%%]

%%[(50 codegen) export(ehcOptEarlyModMerge)
-- compatibility option
ehcOptEarlyModMerge :: EHCOpts -> Bool
ehcOptEarlyModMerge opts
  = ehcOptOptimizationScope opts >= OptimizationScope_WholeCore
%%]

%%[8 export(ehcOptWholeProgHPTAnalysis)
-- do whole program analysis, with HPT
ehcOptWholeProgHPTAnalysis :: EHCOpts -> Bool
ehcOptWholeProgHPTAnalysis opts
%%[[(8 codegen grin)
  =  targetDoesHPTAnalysis (ehcOptTarget opts)
%%[[50
  || ehcOptWholeProgOptimizationScope opts
%%]]
%%][8
  = False
%%]]
%%]

%%[(8 codegen grin) export(ehcOptErrAboutBytecode)
-- report when Grin ByteCode errors occur
ehcOptErrAboutBytecode :: EHCOpts -> Bool
%%[[8
ehcOptErrAboutBytecode _ = False
%%][99
ehcOptErrAboutBytecode   = targetIsGrinBytecode . ehcOptTarget
%%]]
%%]

%%[(8 codegen grin) export(ehcOptEmitC)
-- generate C
ehcOptEmitC :: EHCOpts -> Bool
ehcOptEmitC = targetIsC . ehcOptTarget
%%]

%%[(8888 codegen java) export(ehcOptEmitJava)
-- generate Java, as src text
ehcOptEmitJava :: EHCOpts -> Bool
ehcOptEmitJava o = ehcOptTarget o == Target_Interpreter_Core_Java
%%]

%%[(8 codegen grin llvm wholeprogAnal wholeprogC) export(ehcOptEmitLLVM)
-- generate LLVM
ehcOptEmitLLVM :: EHCOpts -> Bool
ehcOptEmitLLVM = targetIsLLVM . ehcOptTarget
%%]

%%[(8 codegen clr wholeprogC) export(ehcOptEmitCLR)
-- generate CIL, as .il assembly file
ehcOptEmitCLR :: EHCOpts -> Bool
ehcOptEmitCLR = targetIsCLR . ehcOptTarget
%%]

%%[(8 codegen) export(ehcOptEmitCore)
-- generate Core
ehcOptEmitCore :: EHCOpts -> Bool
ehcOptEmitCore opts
  = ehcOptWholeProgHPTAnalysis opts || targetIsCore (ehcOptTarget opts)
%%]

%%[(8 codegen tycore) export(ehcOptEmitTyCore,ehcOptTyCore)
-- generate TyCore
ehcOptEmitTyCore :: EHCOpts -> Bool
ehcOptEmitTyCore opts
  = {- ehcOptWholeProgHPTAnalysis opts || -} targetIsTyCore (ehcOptTarget opts)

ehcOptTyCore :: EHCOpts -> Bool
ehcOptTyCore opts = ehcOptEmitTyCore opts || isJust (ehcOptUseTyCore opts)

%%]

%%[(8 codegen) export(ehcOptOptimizes)
-- | optimizes a particular option
ehcOptOptimizes :: Optimize -> EHCOpts -> Bool
ehcOptOptimizes o opts = o `Set.member` ehcOptOptimizations opts
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Default compiler options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1.defaultEHCOpts export(defaultEHCOpts)
defaultEHCOpts
  = emptyEHCOpts
%%[[99
      { ehcOptExecOptsMp = ehcOptExecOptsMp emptyEHCOpts `Map.union` Map.fromList
      	  [ (Cfg.shellCmdCpp, [ExecOpt_Plain "traditional-cpp", ExecOpt_Plain "std=gnu99", ExecOpt_Plain "fno-show-column", ExecOpt_Plain "P"])
      	  ]
      }
%%]]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Options as passed on the command line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 export(ehcCmdLineOpts)
ehcCmdLineOpts
  =  [  Option "h"  ["help"]                (NoArg oHelp)                           "print this help (then stop)"
     ,  Option ""   ["version"]             (NoArg oVersion)                        "print version info (then stop)"
%%[[99
     ,  Option ""   ["version-dotted"]      (NoArg oNumVersion)                     ("print version in \"x.y.z\" style (then stop)")
     ,  Option ""   ["version-asnumber"]    (NoArg oVersionAsNumber)                ("print version in \"xyz\" style (then stop)")
     ,  Option ""   ["numeric-version"]     (NoArg oNumVersion)                     "see --version-dotted (to become obsolete)"
%%]]
%%[[8
     ,  Option "v"  ["verbose"]             (OptArg oVerbose "0|1|2|3|4")           (   "be verbose, 0=quiet, 4=debug, "
%%[[8
                                                                                    ++ "default=2"
%%][100
                                                                                    ++ "default=1"
%%]]
                                                                                    )
%%]]
%%[[1
     ,  Option "t"  ["target"]              (OptArg oTarget "")                     "code generation not available"
%%][(8 codegen)
     ,  Option "t"  ["target"]              (ReqArg oTarget (showSupportedTargets'  "|"))
                                                                                    ("generate code for target, default=" ++ show defaultTarget)
     ,  Option ""   ["target-flavor"]       (ReqArg oTargetFlavor (showAllTargetFlavors' "|"))
                                                                                    ("generate code for target flavor, default=" ++ show defaultTargetFlavor)
%%]]
%%[[1
     ,  Option "p"  ["pretty"]              (OptArg oPretty "hs|eh|ast|-")          "show pretty printed source or EH abstract syntax tree, default=eh, -=off, (downstream only)"
%%][(8 codegen tycore)
     ,  Option "p"  ["pretty"]              (OptArg oPretty "hs|eh|ast|ty|-")       "show pretty printed source, EH abstract syntax tree or TyCore ast, default=eh, -=off, (downstream only)"
%%]]
%%[[1
     ,  Option "d"  ["debug"]               (NoArg oDebug)                          "show debug information"
     ,  Option ""   ["priv"]                (boolArg oPriv)                         "private flag, used during development of 2 impls of 1 feature"
%%][100
%%]]
%%[[(1 hmtyinfer)
     ,  Option ""   ["show-top-ty"]         (OptArg oShowTopTy "yes|no")            "show top ty, default=no"
%%][100
%%]]

%%[[1
     ,  Option ""   ["stopat"]
%%[[1
                                            (ReqArg oStopAt "0|1|2|3")              "stop at compile phase 0=imports, 1=parse, 2=hs, 3=eh"
%%][(8 codegen)
                                            (ReqArg oStopAt "0|1|2|3|4")            "stop at compile phase 0=imports, 1=parse, 2=hs, 3=eh, 4=core"
%%]]
%%][100
%%]]

%%[[7_2
     ,  Option ""   ["nounique"]            (NoArg oUnique)                         "do not compute uniqueness solution"
%%]]
%%[[(8 codegen)
     ,  Option "O"  ["optimise"]            (OptArg oOptimization ("0|1|2|3|<opt>[=" ++ boolArgStr ++ "]"))
                                                                                    ("optimise with level or specific <opt> by optim name: "
                                                                                     ++ showStr2stMp allOptimizeMp
                                                                                     ++ ", or by scope name: "
                                                                                     ++ showStr2stMp allOptimScopeMp
                                                                                     ++ ", default=1")
%%]]
%%[[(8 codegen)
     ,  Option ""   ["code"]                (OptArg oCode "hs|eh|exe[c]|lexe[c]|bexe[c]|-")
                                                                                    "write code to file, default=bexe (will be obsolete and/or changed, use --target)"
%%][100
%%]]
%%[[(8 codegen grin)
     ,  Option ""   ["time-compilation"]    (NoArg oTimeCompile)                    "show grin compiler CPU usage for each compilation phase (only with -v2)"
     ,  Option ""   ["gen-casedefault"]     (boolArg optSetGenCaseDefault)          "codegen: trap wrong casedistinction in C (no)"
     ,  Option ""   ["gen-cmt"]             (boolArg optSetGenCmt)                  "codegen: include comment about code in generated code"
     ,  Option ""   ["gen-debug"]           (boolArg optSetGenDebug)                "codegen: include debug info in generated code (yes)"
     ,  Option ""   ["gen-trace"]           (boolArg optSetGenTrace)                "codegen: trace functioncalls in C (no)"
     ,  Option ""   ["gen-trace-assign"]    (boolArg optSetGenTrace2)               "codegen: trace assignments in C (no)"
     ,  Option ""   ["gen-rtsinfo"]         (ReqArg oRTSInfo "<nr>")                "codegen: flags for rts info dumping (default=0)"
%%][100
%%]]
%%[[(8 codegen)
     ,  Option ""   ["gen-trampoline"]      (boolArg oSetGenTrampoline)             "codegen: use trampoline mechanism (development/internal use only)"
%%]]
%%[[(8 grin)
     ,  Option ""   ["gen-boxgrin"]      	(boolArg oSetGenBoxGrin)             	"codegen: generate simplified grin wrt boxing (development/internal use only)"
%%]]
%%[[(8 codegen)
     ,  Option ""   ["dump-core-stages"]    (boolArg optDumpCoreStages)             "dump: intermediate Core transformation stages (no)"
%%][100
%%]]
%%[[(8 codegen grin)
     ,  Option ""   ["dump-grin-stages"]    (boolArg optDumpGrinStages)             "dump: intermediate Grin and Silly transformation stages (no)"
%%][100
%%]]
%%[[(8 codegen cmm)
     ,  Option ""   ["dump-cmm-stages"]     (boolArg optDumpCmmStages)              "dump: intermediate Cmm stages (no)"
%%][100
%%]]
%%[[(8 javascript)
     ,  Option ""   ["dump-js-stages"]      (boolArg optDumpJavaScriptStages)       "dump: intermediate JavaScript transformation stages (no)"
%%][100
%%]]
%%[[(8 codegen java)
%%]]
%%[[50
     ,  Option ""   ["no-recomp"]           (NoArg oNoRecomp)                       "turn off recompilation check (force recompile)"
%%]]
%%[[99
     ,  Option ""   ["no-prelude"]          (NoArg oNoPrelude)                      "do not assume presence of Prelude"
     ,  Option ""   ["no-hi-check"]         (NoArg oNoHiCheck)                      "no check on .hi files not matching the compiler version"
%%]]
%%[[50
     ,  Option "c"  ["compile-only"]        (NoArg oCompileOnly)                    "compile only, do not link"
%%]]
%%[[50
     ,  Option ""   ["debug-stopat-hi-error"]
                                            (boolArg oStopAtHIError)                "debug: stop at .hi parse error (default=off)"
%%][100
%%]]
%%[[(50 codegen)
     ,  Option ""   ["debug-stopat-core-error"]
                                            (boolArg oStopAtCoreError)              "debug: stop at .cr parse error (default=off)"
%%][100
%%]]
%%[[99
     ,  Option "i"  ["import-path"]         (ReqArg oUsrFileLocPath "path")         "search path for user files, separators=';', appended to previous"
     ,  Option "L"  ["lib-search-path"]     (ReqArg oLibFileLocPath "path")         "search path for library files, see also --import-path"
     ,  Option ""   ["cpp"]                 (NoArg oCPP)                            "preprocess source with CPP"
     ,  Option ""   ["limit-tysyn-expand"]  (intArg oLimitTyBetaRed)                "type synonym expansion limit"     
     ,  Option ""   ["odir"]                (ReqArg oOutputDir "dir")               "base directory for generated files"
     ,  Option "o"  ["output"]              (ReqArg oOutputFile "file")             "file to generate executable to (implies --compile-only off)"
     ,  Option ""   ["keep-intermediate-files"] (NoArg oKeepIntermediateFiles)      "keep intermediate files (default=off)"
%%]]
%%[[(99 hmtyinfer tyderivtree)
     ,  Option ""   ["deriv-tree"]          (OptArg oDerivTree ("f|i[,p=[{0,1,2,3,4,5}|<n>m]][,f=" ++ boolArgStr ++ "]"))
                                                                                    "emit derivation tree on .lhs file; f=final, i=infer, default=f; p=paper size (0=a0,...; <n>m=2^<n> meter), dflt=2; f=show subsumption"
%%][100
%%]]
     ,  Option ""   ["meta-variant"]        (NoArg oVariant)                        "meta: print variant (then stop)"
     ,  Option ""   ["meta-target-default"] (NoArg oTargetDflt)                     "meta: print the default codegeneration target (then stop)"
     ,  Option ""   ["meta-targets"]        (NoArg oTargets)                        "meta: print supported codegeneration targets (then stop)"
%%[[(8 codegen)
     ,  Option ""   ["meta-optimizations"]  (NoArg oOptimizations)                  "meta: print optimization names (then stop)"
%%]
%%[[99
     ,  Option ""   ["meta-pkgdir-system"]  (NoArg oMetaPkgdirSys)                  "meta: print system package dir (then stop)"
     ,  Option ""   ["meta-pkgdir-user"]    (NoArg oMetaPkgdirUser)                 "meta: print user package dir (then stop)"
     ,  Option ""   ["package"]             (ReqArg oExposePackage "package")       "see --pkg-expose"
     ,  Option ""   ["hide-all-packages"]   (NoArg oHideAllPackages)                "see --pkg-hide-all"
     ,  Option ""   ["pkg-expose"]          (ReqArg oExposePackage "package")       "pkg: expose/use package"
     ,  Option ""   ["pkg-hide"]            (ReqArg oHidePackage   "package")       "pkg: hide package"
     ,  Option ""   ["pkg-hide-all"]        (NoArg oHideAllPackages)                "pkg: hide all (implicitly) assumed/used packages"
     ,  Option ""   ["pkg-searchpath"]      (ReqArg oPkgdirLocPath "path")          "pkg: package search directories, each dir has <pkg>/<variant>/<target>/<flavor>"
     ,  Option ""   ["pkg-build"]           (ReqArg oPkgBuild "package")            "pkg build: build package from files. Implies --compile-only"
     ,  Option ""   ["pkg-build-exposed"]   (ReqArg oPkgBuildExposedModules "modules")
     																				"pkg build: for package building, exposed modules (blank separated)"
     ,  Option ""   ["pkg-build-depends"]   (ReqArg oPkgBuildBuildDepends "packages")
     																				"pkg build: for package building, depended on packages (blank separated)"
     ,  Option ""   ["cfg-install-root"]    (ReqArg oCfgInstallRoot "dir")          "cfg: installation root (to be used only by wrapper script)"
     ,  Option ""   ["cfg-install-variant"] (ReqArg oCfgInstallVariant "variant")   "cfg: installation variant (to be used only by wrapper script)"
     ,  Option ""   ["optP"]                (ReqArg (oCmdLineOpts Cmd_CPP_Preprocessing) "opt for cmd")
                                                                                    "opt: option for cmd used by compiler, currently only P (preprocessing)"
     ,  Option ""   ["pgmP"]                (ReqArg (oPgmExec PgmExec_CPP)          "alternate program for cmd")
                                                                                    "pgm: alternate executable used by compiler, currently only P (preprocessing)"
%%]]
%%[[(8 codegen)
     ,  Option ""   ["coreopt"]             (ReqArg oOptCore "opt[,...]")           ("opts (specific) for core: " ++ showStr2stMp coreOptMp)
%%]]
%%[[(8 codegen tycore)
     ,  Option ""   ["tycore"]              (OptArg oUseTyCore "opt[,...]")         ("temporary/development: use (specific) typed core. opts: " ++ showStr2stMp tycoreOptMp)
%%]]
%%[[(8 codegen cmm)
     ,  Option ""   ["cmm"]                 (OptArg oUseCmm "opt[,...]")            ("temporary/development: use (specific) cmm. opts: " ++ showStr2stMp cmmOptMp)
     ,  Option ""   ["cmmopt"]              (ReqArg oOptCmm "opt[,...]")            ("opts (specific) for cmm: " ++ showStr2stMp cmmOptMp)
%%]]
%%[[(8 codegen javascript)
     ,  Option ""   ["js"]                  (ReqArg oOptJavaScript "opt[,...]")     ("opts (specific) for javascript: " ++ showStr2stMp javaScriptOptMp)
%%]]
     ]
%%]
%%[1
  where  oPretty     ms  o =  case ms of
                                Just "-"     -> o { ehcOptShowEH       = False     }
                                Just "no"    -> o { ehcOptShowEH       = False     }
                                Just "off"   -> o { ehcOptShowEH       = False     }
                                Just "hs"    -> o { ehcOptShowHS       = True      }
                                Just "eh"    -> o { ehcOptShowEH       = True      }
                                Just "pp"    -> o { ehcOptShowEH       = True      }
%%[[(8 codegen tycore)
                                Just "ty"    -> o { ehcOptShowTyCore   = True      }
%%]]
%%[[1
                                Just "ast"   -> o { ehcOptShowAst      = True      }
%%][100
%%]]
                                _            -> o
%%[[(1 hmtyinfer)
         oShowTopTy  ms  o =  case ms of
                                Just "yes"  -> o { ehcOptShowTopTyPP   = True      }
                                _           -> o
%%]]
         oHelp           o =  o { ehcOptImmQuit       = Just ImmediateQuitOption_Help    }
         oVersion        o =  o { ehcOptImmQuit       = Just ImmediateQuitOption_Version }
         oVariant        o =  o { ehcOptImmQuit       = Just ImmediateQuitOption_Meta_Variant }
         oDebug          o =  o { ehcOptDebug         = True
%%[[1
                                , ehcOptShowAst       = True
%%][100
%%]]
                                }
         oStopAt       s o =  o { ehcStopAtPoint       =
                                    case s of
                                      "0" -> CompilePoint_Imports
                                      "1" -> CompilePoint_Parse
                                      "2" -> CompilePoint_AnalHS
                                      "3" -> CompilePoint_AnalEH
%%[[(8 codegen)
                                      "4" -> CompilePoint_Core
%%]]
                                      _   -> CompilePoint_All
                                }
%%[[7_2
         oUnique         o =  o { ehcOptUniqueness    = False   }
%%]]
%%[[(8 grin)
         oTimeCompile    o =  o { ehcOptTimeGrinCompile       = True    }
%%]]
%%[[(8 codegen)
         oOptCore    s   o =  o { ehcOptCoreOpts = optOpts coreOptMp s ++ ehcOptCoreOpts o}
%%]]
%%[[(8 codegen cmm)
         oOptCmm     s   o =  o { ehcOptCmmOpts = optOpts cmmOptMp s }
%%]]
%%[[(8 codegen javascript)
         oOptJavaScript s o = o { ehcOptJavaScriptOpts = optOpts javaScriptOptMp s }
%%]]
%%[[(8 codegen tycore)
         oUseTyCore ms   o =  case ms of
                                Just s -> o { ehcOptUseTyCore = Just opts2 }
                                       where opts1 = optOpts tycoreOptMp s
                                             opts2 = if TyCoreOpt_Unicode `elem` opts1 then ([TyCoreOpt_Sugar] ++ opts1) else opts1
                                _      -> o { ehcOptUseTyCore = Just [] }
%%]]
%%[[(8 codegen cmm)
         oUseCmm ms   o =  case ms of
                                Just s -> o { ehcOptUseCmm = Just opts1 }
                                       where opts1 = optOpts cmmOptMp s
                                             -- opts2 = if TyCoreOpt_Unicode `elem` opts1 then ([TyCoreOpt_Sugar] ++ opts1) else opts1
                                _      -> o { ehcOptUseCmm = Just [] }
%%]]
%%[[1
         oTarget        _ o =  o
%%][(8 codegen)
         oTarget        s o =  o { ehcOptMbTarget          = mbtarget
%%[[50
                                 , ehcOptOptimizationScope = if isJustOk mbtarget && targetDoesHPTAnalysis (fromJustOk mbtarget)
                                                             then max oscope (maxBound :: OptimizationScope)
                                                             else oscope
%%]]
                                 }
                            where mbtarget = maybe (NotOk s) JustOk $ Map.lookup s supportedTargetMp
                                  oscope = ehcOptOptimizationScope o
         oTargetFlavor  s o =  o { ehcOptMbTargetFlavor  = maybe (NotOk s) JustOk $ Map.lookup s allTargetFlavorMp }
         oOptimizations   o =  o { ehcOptImmQuit         = Just ImmediateQuitOption_Meta_Optimizations       }
%%]]
%%[[1
         oTargets        o =  o { ehcOptImmQuit       = Just ImmediateQuitOption_Meta_Targets       }
         oTargetDflt     o =  o { ehcOptImmQuit       = Just ImmediateQuitOption_Meta_TargetDefault  }
                                      
%%]]
%%[[8
         oCode       ms  o =  case ms of
                                Just "hs"    -> o { ehcOptEmitHS           = True   }
                                Just "eh"    -> o { ehcOptEmitEH           = True   }
%%[[(8 codegen)
                                Just "-"     -> o -- { ehcOptEmitCore         = False  }
                                Just "core"  -> o { ehcOptMbTarget         = JustOk Target_None_Core_AsIs
                                                  }
                                Just "tycore"-> o { ehcOptMbTarget         = JustOk Target_None_TyCore_None
                                                  }
%%]]
%%[[(8888 codegen java)
                                Just "java"  -> o { ehcOptMbTarget         = JustOk Target_Interpreter_Core_Java   }
%%]]
%%[[(8 codegen grin)
                                Just "grin"  -> o -- { ehcOptEmitGrin         = True   }
                                Just "bc"    -> o -- { ehcOptEmitBytecode     = True 
                                                  -- , ehcOptWholeProgHPTAnalysis = False
                                                  -- }
                                Just m | m `elem` ["bexe","bexec"]
                                             -> o { ehcOptMbTarget         = JustOk Target_Interpreter_Grin_C
                                                  }

                                Just "c"     -> o -- { ehcOptEmitC            = True
                                                  -- , ehcOptWholeProgHPTAnalysis = True
                                                  -- , ehcOptEmitExecBytecode = False
                                                  -- , ehcOptEmitBytecode     = False
                                                  -- , ehcOptErrAboutBytecode = False
                                                  -- }

%%[[(8 wholeprogC)
                                Just m | m `elem` ["exe","exec"]
                                             -> o { ehcOptMbTarget         = JustOk Target_FullProgAnal_Grin_C
                                                  }
%%]]

%%[[(8 llvm wholeprogC)
                                Just "llvm"  -> o -- { ehcOptEmitLLVM         = True
                                                  -- , ehcOptWholeProgHPTAnalysis = True
                                                  -- , ehcOptEmitExecBytecode = False
                                                  -- , ehcOptEmitBytecode     = False
                                                  -- , ehcOptErrAboutBytecode = False
                                                  -- }
%%]]

%%]]
%%[[(8 codegen llvm wholeprogC)
                                Just m | m `elem` ["lexe", "lexec"]
                                             -> o { ehcOptMbTarget         = JustOk Target_FullProgAnal_Grin_LLVM
                                                  }                   
%%]]
%%[[(8 codegen clr wholeprogC)
                                Just "clr"   -> o { ehcOptMbTarget         = JustOk Target_FullProgAnal_Grin_CLR   }
%%]]
%%[[(99 hmtyinfer tyderivtree)
                                Just "dt"    -> o { ehcOptEmitDerivTree    = DerivTreeWay_Final   }
%%]]
                                _            -> o

%%[[(8888 codegen)
         oTrf        s   o =  o { ehcOptTrf           = opt s   }
                           where  opt "" =  []
                                  opt o  =  let  (pm,o2) = span (\c -> c == '+' || c == '-') o
                                                 (tr,o3) = span isAlpha o2
                                                 opt2    = opt o3
                                            in   case (pm,tr) of
                                                   ("+",_:_)  -> TrfYes tr : opt2
                                                   ("-",_:_)  -> TrfNo tr : opt2
                                                   ("+",_)    -> [TrfAllYes]
                                                   ("-",_)    -> [TrfAllNo]
                                                   _          -> []
%%]]
%%[[(8 codegen grin)
         oRTSInfo    s   o =  o { ehcOptGenRTSInfo     = read s       }
%%]]
         oVerbose    ms  o =  case ms of
                                Just "0"    -> o { ehcOptVerbosity     = VerboseQuiet       }
                                Just "1"    -> o { ehcOptVerbosity     = VerboseMinimal     }
                                Just "2"    -> o { ehcOptVerbosity     = VerboseNormal      }
                                Just "3"    -> o { ehcOptVerbosity     = VerboseALot        }
                                Just "4"    -> o { ehcOptVerbosity     = VerboseDebug       }
                                Nothing     -> o { ehcOptVerbosity     = succ (ehcOptVerbosity o)}
                                _           -> o
%%[[(8 codegen)
         oOptimization ms o
                           = o' {ehcOptOptimizations = optimizeRequiresClosure os}
                           where (o',doSetOpts)
                                    = case ms of
                                        Just (clevel:',':cscope:_)
                                          | isJust mbO -> (fromJust mbO o, True)
                                          where mbO = mbLevelScope (Just clevel) (Just cscope)
                                        Just (',':cscope:_)
                                          | isJust mbO -> (fromJust mbO o, True)
                                          where mbO = mbLevelScope Nothing (Just cscope)
                                        Just olevel@(clevel:_)
                                          | isDigit clevel && l >= 0 && l < (maxscp * maxlev)
                                            -> ( o { ehcOptOptimizationLevel = toEnum lev, ehcOptOptimizationScope = toEnum sc }
                                               , True
                                               )
                                          where l = read olevel :: Int
                                                (sc,lev) = quotRem l maxlev
                                        Just scpname@(_:_)
                                          | isJust mbScp
                                            -> ( o { ehcOptOptimizationScope = sc }
                                               , True
                                               )
                                          where mbScp@(~(Just sc)) = Map.lookup scpname allOptimScopeMp
                                        Just optname@(_:_)
                                          -> case break (== '=') optname of
                                               (nm, yesno)
                                                 -> ( o { ehcOptOptimizations = os
                                                        , ehcOptOptimizeOptionMp = osmp `Map.union` ehcOptOptimizeOptionMp o
                                                        }
                                                    , False
                                                    )
                                                 where set True  opt = Set.insert opt $ ehcOptOptimizations o
                                                       set False opt = Set.delete opt $ ehcOptOptimizations o
                                                       (os,osmp)
                                                          = -- lookup name, and attempt to extract boolean of assumedly '=' prefixed string, or if not a boolean try to extract specific config whilst also assuming True for the boolean
                                                            case (Map.lookup nm allOptimizeMp, optArgTake optArgAllAllow $ drop 1 yesno) of
                                                              (Just opt, Just (OptArg_Bool b,_ ))   -> (set b     opt           , Map.empty)
                                                              (Just opt, Just (OptArg_Int  i,_ ))   -> (set True  opt           , optimizeOptionMpSingleton opt optopt v)
                                                                                                    where (optopt,optdflt) = allOptimizeOptionMpAnyOption opt
                                                                                                          v = maybe optdflt (\(_,(lo,_)) -> toEnum $ fromEnum lo + i)
                                                                                                              $ mapLookup2 opt optopt allOptimizeOptionMp
                                                              (Just opt, _                      )   -> (set True  opt           , Map.empty)
                                                              _                                     -> (ehcOptOptimizations o   , Map.empty)
                                        Nothing
                                          -> (o { ehcOptOptimizationLevel      = OptimizationLevel_Much       }, True)
                                        _ -> (o, False)
                                 os | doSetOpts = Map.findWithDefault Set.empty (ehcOptOptimizationLevel o') optimizationLevelMp
                                    | otherwise = ehcOptOptimizations o'
                                 maxlev = fromEnum (maxBound :: OptimizationLevel) + 1
                                 maxscp = fromEnum (maxBound :: OptimizationScope) + 1
                                 mbLevelScope ml ms
                                   | isJust l && isJust s = Just (\o -> o { ehcOptOptimizationLevel = toEnum (fromJust l), ehcOptOptimizationScope = toEnum (fromJust s) })
                                   | otherwise            = Nothing
                                   where l = r ehcOptOptimizationLevel maxlev ml
                                         s = r ehcOptOptimizationScope maxscp ms
                                         r dflt mx m
                                           | x >= 0 && x < mx = Just x
                                           | otherwise        = Nothing
                                           where x = (maybe (fromEnum $ dflt o) (\c -> read [c]) m) :: Int
%%]]
%%]]
%%[[50
         oNoRecomp              o   = o { ehcOptCheckRecompile              = False    }
         oCompileOnly           o   = o { ehcOptLinkingStyle                = LinkingStyle_None }
%%]]
%%[[99
         oNoHiCheck             o   = o { ehcOptHiValidityCheck             = False    }
         oNumVersion            o   = o { ehcOptImmQuit                     = Just ImmediateQuitOption_VersionDotted }
         oVersionAsNumber       o   = o { ehcOptImmQuit                     = Just ImmediateQuitOption_VersionAsNumber }
         oUsrFileLocPath      s o   = o { ehcOptImportFileLocPath           = ehcOptImportFileLocPath o ++ mkFileLocPath s }
         oLibFileLocPath      s o   = o { ehcOptLibFileLocPath              = ehcOptLibFileLocPath o ++ mkFileLocPath s }
         oPkgdirLocPath       s o   = o { ehcOptPkgdirLocPath               = ehcOptPkgdirLocPath o ++ mkStringPath s }
         oNoPrelude             o   = o { ehcOptUseAssumePrelude            = False   }
         oCPP                   o   = o { ehcOptCPP                         = True    }
         oLimitTyBetaRed        o l = o { ehcOptTyBetaRedCutOffAt           = l }
         oLimitCtxtRed          o l = o { ehcOptPrfCutOffAt                 = l }
         oMetaPkgdirSys         o   = o { ehcOptImmQuit                     = Just ImmediateQuitOption_Meta_Pkgdir_System }
         oMetaPkgdirUser        o   = o { ehcOptImmQuit                     = Just ImmediateQuitOption_Meta_Pkgdir_User }
         oExposePackage       s o   = o { ehcOptPackageSearchFilter         = ehcOptPackageSearchFilter o ++ pkgSearchFilter parsePkgKey PackageSearchFilter_ExposePkg [s]
                                        -- , ehcOptLibPackages                 = ehcOptLibPackages   o ++ [s]
                                        }
         oHidePackage         s o   = o { ehcOptPackageSearchFilter         = ehcOptPackageSearchFilter o ++ pkgSearchFilter parsePkgKey PackageSearchFilter_HidePkg [s]
                                        }
         oHideAllPackages       o   = o { ehcOptPackageSearchFilter         = ehcOptPackageSearchFilter o ++ [PackageSearchFilter_HideAll]
                                        -- , ehcOptHideAllPackages             = True
                                        }
         oOutputDir           s o   = o { ehcOptOutputDir                   = Just s
                                          -- no linking when no output file is generated. This is not failsafe, requires better solution as now no executable is generated when no --output is specified. Should depend on existence of main.
                                        -- , ehcOptDoExecLinking                   = isJust (ehcOptMbOutputFile o)
                                        }
         oOutputFile          s o   = o { ehcOptMbOutputFile                = Just (mkFPath s)
                                        , ehcOptLinkingStyle                = LinkingStyle_Exec
                                        }
         oKeepIntermediateFiles o   = o { ehcOptKeepIntermediateFiles       = True }
         oPkgBuild            s o   = o { ehcOptPkgOpt                      = Just ((maybe emptyPkgOption id $ ehcOptPkgOpt o) {pkgoptName=s})
                                        , ehcOptLinkingStyle                = LinkingStyle_Pkg
                                        }
         oPkgBuildExposedModules
                              s o   = o { ehcOptPkgOpt                      = Just ((maybe emptyPkgOption id $ ehcOptPkgOpt o) {pkgoptExposedModules = words s})
                                        }
         oPkgBuildBuildDepends
                              s o   = o { ehcOptPkgOpt                      = Just ((maybe emptyPkgOption id $ ehcOptPkgOpt o) {pkgoptBuildDepends = words s})
                                        }
         oCfgInstallRoot      s o   = o { ehcOptCfgInstallRoot              = Just s }
         oCfgInstallVariant   s o   = o { ehcOptCfgInstallVariant           = Just s }
         oCmdLineOpts cmd     s o   = o { ehcOptCmdLineOpts                 = -- (\v -> tr "XX" (pp s >#< show v) v) $ 
                                                                              nub $ ehcOptCmdLineOpts o ++ fst (parseCmdLineOpts cmd s) }
         oPgmExec     cmd     s o   = o { ehcOptPgmExecMp                   = Map.insert cmd s $ ehcOptPgmExecMp o }
%%]]
%%[[(99 hmtyinfer tyderivtree)
         oDerivTree  ms  o =  case ms of
                                Just ('f':a) -> opts a $ o { ehcOptEmitDerivTree    = DerivTreeWay_Final  }
                                Just ('i':a) -> opts a $ o { ehcOptEmitDerivTree    = DerivTreeWay_Infer  }
                                Nothing      ->          o { ehcOptEmitDerivTree    = DerivTreeWay_Final  }
                                _            ->          o
                           where opts (',':'p':'=':sz:'m':r) o = opts r $ o { ehcOptEmitDerivTreePaperSize = ['m',sz] }
                                 opts (',':'p':'=':sz    :r) o = opts r $ o { ehcOptEmitDerivTreePaperSize = [sz] }
                                 opts (',':'f':'='       :r) o = maybe o (\(b,r) -> opts r $ o {ehcOptEmitDerivFitsIn = b}) (optBooleanTake r)
                                 opts _                      o = o
%%][100
%%]]
%%]

%%[99
intArg  tr = ReqArg (optInt tr) "<nr>"

optInt :: (EHCOpts -> Int -> EHCOpts) -> String -> EHCOpts -> EHCOpts
optInt tr s o
 = tr o $ read s
%%]

%%[1
-- | What kind of optional args are allowed
data OptArgAllow
  = OptArgAllow_Bool
  | OptArgAllow_Int
  deriving (Eq,Enum,Bounded)

optArgAllAllow :: [OptArgAllow]
optArgAllAllow = [minBound .. maxBound]
%%]

%%[1
-- | An optional arg, universal type for all occurring variants
data OptArg
  = OptArg_Bool     Bool
  | OptArg_Int      Int
%%]

%%[1
optArgTake :: [OptArgAllow] -> String -> Maybe (OptArg,String)
optArgTake allow s
  = case s of
      ('-':r)           -> Just (OptArg_Bool False,r)
      ('n':'o':r)       -> Just (OptArg_Bool False,r)
      ('n':r)           -> Just (OptArg_Bool False,r)
      ('o':'f':'f':r)   -> Just (OptArg_Bool False,r)
      ('0':r) | noInt   -> Just (OptArg_Bool False,r)
      ('+':r)           -> Just (OptArg_Bool True ,r)
      ('y':'e':'s':r)   -> Just (OptArg_Bool True ,r)
      ('y':r)           -> Just (OptArg_Bool True ,r)
      ('o':'n':r)       -> Just (OptArg_Bool True ,r)
      ('1':r) | noInt   -> Just (OptArg_Bool True ,r)
      ( c :_) | yesInt && isDigit c
                        -> Just (OptArg_Int (read d) ,r)
                        where (d,r) = span isDigit s
      _                 -> Nothing
  where yesInt = OptArgAllow_Int `elem` allow
        noInt  = not yesInt
%%]

%%[1
optBooleanTake :: String -> Maybe (Bool,String)
optBooleanTake s
  = case optArgTake [OptArgAllow_Bool] s of
      Just (OptArg_Bool b, r)   -> Just (b,r)
      _                         -> Nothing

optBoolean :: (EHCOpts -> Bool -> EHCOpts) -> Maybe String -> EHCOpts -> EHCOpts
optBoolean tr ms o
 = case ms of
     Just s -> maybe o (tr o . fst) (optBooleanTake s)
     _      -> o

%%[[1
boolArgStr = "0|1|n[o]|y[es]|off|on|-|+"
%%][100
boolArgStr = "Bool"
%%]]
boolArg tr = OptArg (optBoolean tr) boolArgStr
%%]

%%[1
oPriv                o b = o { ehcOptPriv           = b }
%%]

%%[(8 codegen)
optDumpCoreStages    o b = o { ehcOptDumpCoreStages = b }
%%]

%%[(8 javascript)
optDumpJavaScriptStages o b = o { ehcOptDumpJavaScriptStages = b }
%%]

%%[(8 codegen)
oSetGenTrampoline	 o b = o { ehcOptGenTrampoline_ = b }
%%]

%%[(8 codegen grin)
optSetGenTrace       o b = o { ehcOptGenTrace       = b }
optSetGenTrace2      o b = o { ehcOptGenTrace2      = b }
optSetGenRTSInfo     o b = o { ehcOptGenRTSInfo     = b }
optSetGenCaseDefault o b = o { ehcOptGenCaseDefault = b }
optSetGenCmt         o b = o { ehcOptGenCmt         = b }
optSetGenDebug       o b = o { ehcOptGenDebug       = b }
oSetGenBoxGrin		 o b = o { ehcOptGenBoxGrin_    = b }
optDumpGrinStages    o b = o { ehcOptDumpGrinStages = b {-, ehcOptEmitGrin = b -} }
-- optEarlyModMerge     o b = o { ehcOptEarlyModMerge  = b }
%%]

%%[(8 codegen cmm)
optDumpCmmStages     o b = o { ehcOptDumpCmmStages = b }
%%]

%%[(50 codegen)
oStopAtCoreError     o b = o { ehcDebugStopAtCoreError     = b }
%%]

%%[50
oStopAtHIError       o b = o { ehcDebugStopAtHIError       = b }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Apply the options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 export(ehcCmdLineOptsApply)
-- | Apply the cmdline opts description to a EHCOpts, returning Nothing when there were no options
ehcCmdLineOptsApply :: [String] -> EHCOpts -> (Maybe EHCOpts, [String], [String])
ehcCmdLineOptsApply args opts
  = (if null o then Nothing else Just (foldl (flip ($)) opts o),n,errs)
  where oo@(o,n,errs)  = getOpt Permute ehcCmdLineOpts args
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Discrimination options for recompile, represent as string, difference means recompile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(optsDiscrRecompileRepr)
optsDiscrRecompileRepr :: EHCOpts -> String
optsDiscrRecompileRepr opts
  = concat
    $ intersperse " "
    $ [ show (ehcOptAspects opts)
%%[[(50 codegen)
      , o "clsrec"          (ehcCfgClassViaRec      opts)
      -- , o "exec"            (ehcOptEmitExecC        opts)
      -- , o "bexec"           (ehcOptEmitExecBytecode opts)
      , show (ehcOptTarget opts)
      , show (ehcOptOptimizationLevel opts)
%%]]
      ]
  where o m v = if v then m else ""
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Fitting options (should be in FitsIn, but here it avoids mut rec modules)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(9 hmtyinfer) export(FIOBind(..))
data FIOBind
  = FIOBindYes | FIOBindNoBut TyVarIdS
  deriving (Show)
%%]

%%[(4 hmtyinfer).FIOpts.hd export(FIOpts(..))
data FIOpts =  FIOpts   {  fioLeaveRInst     ::  !Bool                ,  fioBindRFirst           ::  !Bool
                        ,  fioBindLFirst     ::  !Bool                ,  fioBindLBeforeR         ::  !Bool
                        ,  fioMode           ::  !FIMode              ,  fioUniq                 ::  !UID
                        ,  fioBindCategs     ::  ![TyVarCateg]
%%[[7
                        ,  fioNoRLabElimFor  ::  ![HsName]            ,  fioNoLLabElimFor        ::  ![HsName]
                        ,  fioDontBind       ::  !TyVarIdS
%%]]
%%[[8
                        ,  fioExpandEqTyVar  ::  !Bool                -- expand tyvars also when equal. Required for Sys F translation.
%%]]
%%[[9
                        ,  fioPredAsTy       ::  !Bool                ,  fioAllowRPredElim       ::  !Bool
                        ,  fioBindLVars      ::  !FIOBind             ,  fioBindRVars            ::  !FIOBind
%%]]
%%[[41
                        ,  fioFitFailureToProveObl    :: !Bool
                        ,  fioFitVarFailureToProveObl :: !Bool
%%]]
%%[[40
                        ,  fioAllowEqOpen    ::  !Bool                ,  fioInstCoConst          ::  !HowToInst
%%]]
%%[[(93 hmtyinfer)
                        ,  fiMbMkErrClash    ::  Maybe (Ty -> Ty -> Err) -- alternate error construction for type clash
%%]]
                        }
%%]

Difference strong/weak:

strong: in a context where information is known (i.e. type signature)
strong allows impredicative binding whereas weak will instantiate quantifiers

%%[(9 hmtyinfer) export(fioBindIsYes,fioBindNoSet)
fioBindNoSet :: FIOBind -> TyVarIdS
fioBindNoSet (FIOBindNoBut s) = s
fioBindNoSet _                = Set.empty

fioBindIsYes :: FIOBind -> Bool
fioBindIsYes FIOBindYes = True
fioBindIsYes _          = False
%%]

%%[(4 hmtyinfer).strongFIOpts.hd export(strongFIOpts)
strongFIOpts :: FIOpts
strongFIOpts =  FIOpts  {  fioLeaveRInst     =   False               ,  fioBindRFirst           =   True
                        ,  fioBindLFirst     =   True                ,  fioBindLBeforeR         =   True
                        ,  fioMode           =   FitSubLR            ,  fioUniq                 =   uidStart
                        ,  fioBindCategs     =   [TyVarCateg_Plain]
%%[[7
                        ,  fioNoRLabElimFor  =   []                  ,  fioNoLLabElimFor        =   []
                        ,  fioDontBind       =   Set.empty
%%]]
%%[[8
                        ,  fioExpandEqTyVar  =   False
%%]]
%%[[9
                        ,  fioPredAsTy       =   False               ,  fioAllowRPredElim       =   True
                        ,  fioBindLVars      =   FIOBindYes          ,  fioBindRVars            =   FIOBindYes
%%]]
%%[[41
                        ,  fioFitFailureToProveObl    = False
                        ,  fioFitVarFailureToProveObl = False
%%]]
%%[[40
                        ,  fioAllowEqOpen    =   False               ,  fioInstCoConst          =   instCoConst
%%]]
%%[[(93 hmtyinfer)
                        ,  fiMbMkErrClash    =   Nothing
%%]]
                        }
%%]

%%[(4 hmtyinfer)
instance Show FIOpts where
  show o =  "FIOpts"
%%]

%%[(4 hmtyinfer)
instance PP FIOpts where
  pp   o =  "FIOpts{"
            >#< "leaveRInst=" >|< pp (fioLeaveRInst o)
            >#< "bindLFirst=" >|< pp (fioBindLFirst o)
            >#< "bindRFirst=" >|< pp (fioBindRFirst o)
%%[[7
            >#< "fioNoLLabElimFor=" >|< pp (show $ fioNoLLabElimFor o)
            >#< "fioNoRLabElimFor=" >|< pp (show $ fioNoRLabElimFor o)
%%]]
%%[[9
            >#< "allowRPredElim=" >|< pp (fioAllowRPredElim o)
%%]]
            >#< "}"
%%]

%%[(4 hmtyinfer).FIOpts.instLFIOpts export(instLFIOpts)
instLFIOpts :: FIOpts
instLFIOpts = strongFIOpts {fioBindRFirst = False}
%%]

%%[(4 hmtyinfer).FIOpts.instLRFIOpts export(instLRFIOpts)
instLRFIOpts :: FIOpts
instLRFIOpts = strongFIOpts {fioBindRFirst = False, fioBindLFirst = False}
%%]

%%[(4 hmtyinfer).FIOpts.instFIOpts export(unifyFIOpts,instFIOpts)
unifyFIOpts :: FIOpts
unifyFIOpts = strongFIOpts {fioMode = FitUnify}

instFIOpts :: FIOpts
instFIOpts = instLFIOpts {fioLeaveRInst = True, fioBindLFirst = False}
%%]

%%[(4_2 hmtyinfer).FIOpts.defaults export(meetFIOpts,joinFIOpts,impredFIOpts)
meetFIOpts :: FIOpts
meetFIOpts = unifyFIOpts {fioMode = FitMeet}

joinFIOpts :: FIOpts
joinFIOpts = unifyFIOpts {fioMode = FitJoin}

impredFIOpts :: FIOpts
impredFIOpts = strongFIOpts {fioBindToTyAlts = True}
%%]

%%[(5 hmtyinfer) export(weakFIOpts)
weakFIOpts :: FIOpts
weakFIOpts = fioMkWeak strongFIOpts
%%]

%%[(9 hmtyinfer) export(predFIOpts,implFIOpts)
predFIOpts :: FIOpts
predFIOpts = strongFIOpts {fioPredAsTy = True, fioLeaveRInst = True}

implFIOpts  :: FIOpts
implFIOpts = strongFIOpts {fioAllowRPredElim = False}
%%]

%%[(4 hmtyinfer) export(fioSwapPolarity, fioSwapOpts)
fioSwapOpts :: FIOpts -> FIOpts
fioSwapOpts fio
  = fio
      { fioBindRFirst   = fioBindLFirst fio
      , fioBindLFirst   = fioBindRFirst fio
      , fioBindLBeforeR = not (fioBindLBeforeR fio)
%%[[9
      , fioBindLVars    = fioBindRVars fio
      , fioBindRVars    = fioBindLVars fio
%%]]
      }

fioSwapPolarity :: Polarity -> FIOpts -> FIOpts
fioSwapPolarity pol fio = fio {fioMode = fimSwapPol pol (fioMode fio)}
%%]

%%[(4 hmtyinfer).fioMkStrong export(fioMkStrong)
fioMkStrong :: FIOpts -> FIOpts
fioMkStrong fi = fi {fioLeaveRInst = False, fioBindRFirst = True, fioBindLFirst = True}
%%]

%%[(4 hmtyinfer).fioMkStrong export(fioMkWeak)
fioMkWeak :: FIOpts -> FIOpts
fioMkWeak fi = fi {fioLeaveRInst = True, fioBindRFirst = False}
%%]

%%[(8 hmtyinfer).fioMkStrong export(fioMkFinal)
-- | Adapt options for extracting final ty
fioMkFinal :: FIOpts -> FIOpts
fioMkFinal fi = fi {fioBindLFirst = False, fioBindRFirst = False, fioExpandEqTyVar = True}
%%]

%%[(4 hmtyinfer).fioMkUnify export(fioMkUnify)
fioMkUnify :: FIOpts -> FIOpts
fioMkUnify fi = fi {fioMode = FitUnify}
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FitsIn opts related
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(4 hmtyinfer) export(fioIsSubsume)
fioIsSubsume :: FIOpts -> Bool
fioIsSubsume fio =  case fioMode fio of {FitSubLR -> True ; _ -> False}
%%]

%%[(4_2 hmtyinfer) export(fioIsMeetJoin)
fioIsMeetJoin :: FIOpts -> Bool
fioIsMeetJoin fio =  case fioMode fio of {FitMeet -> True ; FitJoin -> True ; _ -> False}
%%]
