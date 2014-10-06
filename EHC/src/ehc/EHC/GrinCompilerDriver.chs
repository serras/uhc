%%[(8 codegen grin wholeprogAnal) module {%{EH}EHC.GrinCompilerDriver} export(doCompileGrin)
%%]

%%[(8 codegen grin wholeprogAnal) import(System.IO, System.CPUTime, Numeric)
%%]
%%[(8 codegen grin wholeprogAnal) import(Control.Monad.Error, Control.Monad.State, Control.Exception)
%%]
%%[(8 codegen grin wholeprogAnal) import(Data.Maybe, Data.Array.IArray, qualified Data.Map as Map, qualified Data.Set as Set)
%%]
%%[(8 codegen grin wholeprogAnal) import(Debug.Trace)
%%]
%%[(8 codegen grin wholeprogAnal) import(UU.Parsing)
%%]
%%[(8 codegen grin wholeprogAnal) import(UHC.Util.Pretty, UHC.Util.CompileRun, UHC.Util.FPath)
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}Base.Common}, {%{EH}Base.Target}, {%{EH}Base.HsName.Builtin}, {%{EH}Opts}, {%{EH}Scanner.Scanner}, {%{EH}Scanner.Common(grinScanOpts)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode}, {%{EH}GrinCode.Pretty})
%%]
%%[(8 codegen grinparser wholeprogAnal) import({%{EH}GrinCode.Parser})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Common})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.DropUnreachableBindings(dropUnreachableBindings)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.MemberSelect(memberSelect)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.SimpleNullary(simpleNullary)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.CleanupPass(cleanupPass)})
%%]
%%[(97 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.ConstInt(constInt)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.BuildAppBindings(buildAppBindings)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.GlobalConstants(globalConstants)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.Inline(grInline)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.FlattenSeq(grFlattenSeq)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.SetGrinInvariant(setGrinInvariant)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.CheckGrinInvariant(checkGrinInvariant)})
%%]
%%[(9 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.MergeInstance(mergeInstance)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.EvalStored(evalStored)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.ApplyUnited(applyUnited)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.SpecConst(specConst)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.NumberIdents(numberIdents)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.DropUnusedExpr(dropUnusedExpr)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.PointsToAnalysis(heapPointsToAnalysis)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.InlineEA(inlineEA)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.DropDeadBindings(dropDeadBindings)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.EmptyAlts(emptyAlts)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.LateInline(lateInline)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.ImpossibleCase(impossibleCase)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.SingleCase(singleCase)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.MergeCase(mergeCase)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.LowerGrin(lowerGrin)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.CopyPropagation(copyPropagation)})
%%]
%%[(8 codegen grin wholeprogAnal) import({%{EH}GrinCode.Trf.SplitFetch(splitFetch)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}GrinCode.ToSilly(grin2silly)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly(SilModule(..))})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly.InlineExpr(inlineExpr)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly.ElimUnused(elimUnused)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly.GroupAllocs(groupAllocs)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly.EmbedVars(embedVars)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly.Pretty(pretty)})
%%]
%%[(8 codegen grin wholeprogAnal wholeprogC) import({%{EH}Silly.PrettyC(prettyC)})
%%]
%%[(8 codegen grin llvm wholeprogAnal wholeprogC) import({%{EH}Silly.ToLLVM(silly2llvm)})
%%]
%%[(8 codegen llvm wholeprogAnal wholeprogC) import({%{EH}LLVM(LLVMModule(..))})
%%]
%%[(8 codegen llvm wholeprogAnal wholeprogC) import({%{EH}LLVM.Pretty(prettyLLVMModule)})
%%]
%%[(8 codegen clr wholeprogAnal wholeprogC) hs import(Language.Cil (Assembly (..), cil))
%%]
%%[(8 codegen clr wholeprogAnal wholeprogC) import({%{EH}GrinCode.ToCil(grin2cil)})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compilerdriver entry point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin wholeprogAnal)
specialize s 
  =    do{ transformCode         evalStored         "EvalStored"       ; caWriteGrin (s++"a-evalstored")
         ; transformCode         applyUnited        "ApplyUnited"      
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin (s++"b-applyUnited")
         ; transformCodeIterated dropUnusedExpr     "DropUnusedExpr"   ; caWriteGrin (s++"c-unusedExprDropped")
         ; transformCode         specConst          "SpecConst"        ; caWriteGrin (s++"d-specConst")
         ; transformCodeIterated copyPropagation    "CopyPropagation"  ; caWriteGrin (s++"e-after-cp")
         ; transformCode         singleCase         "singleCase"       ; 
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin (s++"f-singleCase")
         ; transformCode         simpleNullary      "SimpleNullary"    ; caWriteGrin (s++"g-simpleNullary")
		 ; transformCode         memberSelect       "MemberSelect"     ; caWriteGrin (s++"h-memberSelected")
         ; transformCode         (dropUnreachableBindings False) 
                                             "DropUnreachableBindings" ; caWriteGrin (s++"i-reachable")
         }

doCompileGrin :: Either String (FPath,GrModule)  -> EHCOpts -> IO ()
doCompileGrin input opts
  = drive (initialState opts input) putErrs $
        do 
         { options <- gets gcsOpts
         ; when (either (const True) (const False) input) caParseGrin  ; caWriteGrin "-110-parsed"
         ; transformCode         (dropUnreachableBindings False) 
                                             "DropUnreachableBindings" ; caWriteGrin "-111-reachable"
%%[[9                                             
		 ; transformCode         mergeInstance      "MergeInstance"    ; caWriteGrin "-112-instanceMerged"
		 ; transformCode         memberSelect       "MemberSelect"     ; caWriteGrin "-113-memberSelected"
		 
         ; transformCode         (dropUnreachableBindings False) 
                                             "DropUnreachableBindings" ; caWriteGrin "-114-reachable"
%%]]
         ; transformCode         cleanupPass        "CleanupPass"      ; caWriteGrin "-115b-cleaned"
         ; transformCode         simpleNullary      "SimpleNullary"    ; caWriteGrin "-115c-simpleNullary"
%%[[97
         ; transformCode         constInt           "ConstInt"         ; caWriteGrin "-116-constint"
%%]]
         ; transformCode         buildAppBindings   "BuildAppBindings" ; caWriteGrin "-117-appsbound"
         ; transformCode         globalConstants    "GlobalConstants"  ; caWriteGrin "-118-globconst"
         
         -- ; transformCodeInline                      "Inline" 
         -- ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-119-inlined"

         -- ; transformCode         singleCase         "singleCase"       ; 
         -- ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-121-singleCase"

         ; transformCode         setGrinInvariant   "SetGrinInvariant" ; caWriteGrin "-122-invariant"
         ; checkCode             checkGrinInvariant "CheckGrinInvariant"

         ; specialize "-123-1"
         ; specialize "-123-2"
         ; specialize "-123-3"
         ; specialize "-123-4"
         ; specialize "-123-5"
         ; specialize "-123-6"
         -- ; specialize "-123-7"
         -- ; specialize "-123-8"

         ; transformCodeInline                      "Inline" 
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-124-inlined"

         ; transformCode         evalStored         "EvalStored"       ; caWriteGrin ("125-evalstored")


         ; transformCode         (dropUnreachableBindings False) 
                                             "DropUnreachableBindings" ; caWriteGrin "-126-reachable"


         ; transformCode         setGrinInvariant   "SetGrinInvariant" ; caWriteGrin "-128-invariant"
         ; checkCode             checkGrinInvariant "CheckGrinInvariant"

         
         ; transformCode         numberIdents       "NumberIdents"     ; caWriteGrin "-129-numbered"
         ; caHeapPointsTo                                              ; caWriteHptMap "-130-hpt"
         ; transformCodeChgHpt   (inlineEA False)   "InlineEA" 
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-131-evalinlined"

         ; transformCodeUseHpt   impossibleCase     "ImpossibleCase"   ; caWriteGrin "-132-possibleCase"


         --; transformCodeUseHpt   dropDeadBindings   "DropDeadBindings" ; caWriteGrin "-132-undead"
         ; transformCode         emptyAlts          "EmptyAlts"        ; caWriteGrin "-133-emptyAlts"
         ; transformCode         (dropUnreachableBindings True) 
                                             "DropUnreachableBindings" ; caWriteGrin "-134-reachable"
         ; transformCodeChgHpt   lateInline         "LateInline"
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-135-lateinlined"
         ; transformCode         emptyAlts          "EmptyAlts"        ; caWriteGrin "-136-emptyAlts"
         ; transformCodeUseHpt   impossibleCase     "ImpossibleCase"   ; caWriteGrin "-141-possibleCase"
         ; transformCode         emptyAlts          "EmptyAlts"        ; caWriteGrin "-142-emptyAlts"
         ; transformCode         singleCase         "singleCase"       ; 
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-143-singleCase"
         ; transformCodeIterated dropUnusedExpr     "DropUnusedExpr"   ; caWriteGrin "-144-unusedExprDropped"
		 ; transformCode         mergeCase          "MergeCase"        ; caWriteGrin "-145-caseMerged"         
         ; transformCodeChgHpt   lowerGrin          "LowerGrin"        ; caWriteGrin "-151-lowered"
                                                                       ; caWriteHptMap "-152-hpt"
         ; transformCodeIterated copyPropagation    "CopyPropagation"  ; caWriteGrin "-161-after-cp"
         ; transformCodeUseHpt   impossibleCase     "ImpossibleCase"   ; caWriteGrin "-162-possibleCase"
         ; transformCode         singleCase         "singleCase"       ; 
         ; transformCode         grFlattenSeq       "Flatten"          ; caWriteGrin "-163-singleCase"


         ; transformCodeIterated dropUnusedExpr     "DropUnusedExpr"   ; caWriteGrin "-169-unusedExprDropped"
         ; transformCodeChgHpt   splitFetch         "SplitFetch"       ; caWriteGrin "-171-splitFetch"
                                                                       ; caWriteHptMap "-172-hpt"
         ; transformCodeIterated dropUnusedExpr     "DropUnusedExpr"   ; caWriteGrin "-176-unusedExprDropped"
         ; transformCodeIterated copyPropagation    "copyPropagation"  ; caWriteGrin "-179-final"
                                                                       ; caWriteHptMap "-180-hpt"

%%[[(8 wholeprogC)
         ; when (targetDoesHPTAnalysis (ehcOptTarget options))
           ( do { caGrin2Silly                                         ; caWriteSilly "-201" "sil" pretty ehcOptDumpGrinStages
                ; transformSilly inlineExpr         "InlineExpr"       ; caWriteSilly "-202" "sil" pretty ehcOptDumpGrinStages
                ; transformSilly elimUnused         "ElimUnused"       ; caWriteSilly "-203" "sil" pretty ehcOptDumpGrinStages
                ; transformSilly embedVars          "EmbedVars"        ; caWriteSilly "-204" "sil" pretty ehcOptDumpGrinStages
                
                -- the GroupAllocs transformation is not compatible with the new EmbedVars tactique of sharing locations.
                -- GroupAllocs is a bad idea anyway.
--              ; transformSilly groupAllocs        "GroupAllocs"      ; caWriteSilly "-205" "sil" pretty ehcOptDumpGrinStages
%%[[(8 llvm)
                ; when (ehcOptEmitLLVM options) 
                  (do { caSilly2LLVM
                      ; caWriteLLVM
                      }
                   )
%%]]
%%[[(8 clr)
                ; when (ehcOptEmitCLR options) 
                  (do { caGrin2Cil
                      ; caWriteCil ""
                      }
                   )
%%]]
                ; caWriteSilly "" "c" prettyC ehcOptEmitC
                }
           )
%%]]
         }
      
initialState opts (Left fn)          = (initState opts) {gcsPath=mkTopLevelFPath "grin" fn}
initialState opts (Right (fp,grmod)) = (initState opts) {gcsPath=fp, gcsGrin=grmod}

initState opts
  = GRINCompileState { gcsGrin       = GrModule_Mod hsnUnknown [] [] Map.empty
%%[[(8 wholeprogC)
                     , gcsSilly      = SilModule_SilModule [] [] []
%%]]
%%[[(8 llvm wholeprogC)
                     , gcsLLVM       = LLVMModule_LLVMModule [] [] [] [] [] []
%%]]
%%[[(8 clr wholeprogC)
                     , gcsCil        = panic "GrinCompilerDriver.initState.gcsCil"
%%]]
%%[[(8 grin)
                     , gcsHptMap     = listArray (1,0) []
                     , gcsPath       = emptyFPath
                     , gcsOpts       = opts
                     }
%%]]
%%]

%%[(8 codegen grin wholeprogAnal)
putErrs (CompileError e) = putStrLn e >> return ()
%%]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Low level compiler actions: input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin wholeprogAnal)
parseGrin :: FPath -> IO GrModule
parseGrin path
  = do{ (fn,fh) <- openFPath path ReadMode False
      ; tokens  <- scanHandle grinScanOpts fn fh
      ; code    <- parseIO (pModule) tokens
      ; return code
      }

caParseGrin :: CompileAction ()
caParseGrin 
  = do{ putMsg VerboseALot "Parsing" Nothing
      ; path <- gets gcsPath
      ; code <- liftIO $ parseGrin path
      ; modify (gcsUpdateGrin code)
      }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Low level compiler actions: processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin wholeprogAnal)

caHeapPointsTo :: CompileAction ()
caHeapPointsTo = task VerboseALot "Heap-points-to analysis"
    ( do { code    <- gets gcsGrin
         ; let (iterCount,hptMap) = heapPointsToAnalysis code
         ; modify (gcsUpdateHptMap hptMap)
         ; return iterCount
         }
     ) (\i -> Just $ show i ++ " iteration(s)")

%%[[(8 wholeprogC)
caGrin2Silly :: CompileAction ()
caGrin2Silly = do
    { code <- gets gcsGrin
    ; hptMap  <- gets gcsHptMap
    ; opts    <- gets gcsOpts
    ; let silly = grin2silly hptMap code opts
    ; modify (gcsUpdateSilly silly)
    }
%%]]
%%]

%%[(8 codegen llvm wholeprogAnal wholeprogC)
caSilly2LLVM :: CompileAction ()
caSilly2LLVM = do
    { code <- gets gcsSilly
    ; opts    <- gets gcsOpts
    ; let llvm = silly2llvm opts code
    ; modify (gcsUpdateLLVM llvm)
    }
%%]

%%[(8 codegen clr wholeprogAnal wholeprogC)
caGrin2Cil :: CompileAction ()
caGrin2Cil = do
    { code <- gets gcsGrin
    ; hptMap <- gets gcsHptMap
    ; opts   <- gets gcsOpts
    ; let cilAst = grin2cil hptMap code opts
    ; modify (gcsUpdateCil cilAst)
    }

%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Low level compiler actions: output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin wholeprogAnal)
caWriteFile :: String -> String -> (EHCOpts -> a -> PP_Doc) -> a -> CompileAction()
caWriteFile extra suffix ppFun struct =
  do { input <- gets gcsPath
     ; opts  <- gets gcsOpts
     ; do { let fileName  = fpathBase input ++ extra
                output    = fpathSetSuff suffix (fpathSetBase fileName input)
          ; putMsg VerboseALot ("Writing " ++ fpathToStr output) Nothing
          ; liftIO $ writePP (ppFun opts) struct output
          }
     }

%%[[(8 llvm)
caWriteLLVM  :: CompileAction()
caWriteLLVM  =
  do { llvm <- gets gcsLLVM
     ; caWriteFile "" "ll" (const prettyLLVMModule) llvm
     }
%%]]

%%[[(8 clr wholeprogC)
caWriteCil :: String -> CompileAction()
caWriteCil extra =
  do { cilAst <- gets gcsCil
     ; caWriteFile extra "il" (const (\c -> text (cil c ""))) cilAst
     }
%%]]

caWriteGrin :: String -> CompileAction ()
caWriteGrin extra
  = do { opts <- gets gcsOpts
       ; when (ehcOptDumpGrinStages opts)
           (do { grin <- gets gcsGrin
               ; caWriteFile extra "grin" (const ppGrModule) grin
               }
           )
       }
     
%%[[(8 wholeprogC)
caWriteSilly :: String -> String -> (EHCOpts -> SilModule -> PP_Doc) -> (EHCOpts->Bool) -> CompileAction ()
caWriteSilly extra suffix ppFun cond =
  do { opts <- gets gcsOpts
     ; when (cond opts)
            ( do { silly <- gets gcsSilly
                 ; caWriteFile extra suffix ppFun silly
                }
            )
     }
%%]]

caWriteHptMap :: String -> CompileAction ()
caWriteHptMap fn
  = do { opts <- gets gcsOpts
       ; when (ehcOptDumpGrinStages opts)
           ( do { hptMap <- gets gcsHptMap
                ; input <- gets gcsPath
                ; let fileName   = fpathBase input ++ fn
                      output = fpathSetSuff "txt" (fpathSetBase fileName input)
                ; liftIO $ writeToFile (showHptMap hptMap) output
                }
           )
       }
%%]




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compilerdriver utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin wholeprogAnal).State
data GRINCompileState = GRINCompileState
    { gcsGrin      :: !GrModule
%%[[(8 wholeprogC)
    , gcsSilly     :: !SilModule
%%]]
%%[[(8 llvm wholeprogC)
    , gcsLLVM      :: !LLVMModule
%%]]
%%[[(8 clr wholeprogC)
    , gcsCil       :: Assembly
%%]]
    , gcsHptMap    :: !HptMap
    , gcsPath      :: !FPath
    , gcsOpts      :: !EHCOpts
    }

gcsUpdateGrin   x s = s { gcsGrin   = x }
%%[[(8 wholeprogC)
gcsUpdateSilly  x s = s { gcsSilly  = x }
%%]]
%%[[(8 llvm wholeprogC)
gcsUpdateLLVM   x s = s { gcsLLVM   = x }
%%]]
%%[[(8 clr wholeprogC)
gcsUpdateCil    x s = s { gcsCil    = x }
%%]]
gcsUpdateHptMap x s = s { gcsHptMap = x }

gcsGetCodeHpt
  = do{ code   <- gets gcsGrin
      ; hpt    <- gets gcsHptMap
      ; return (code,hpt)
      }

gcsPutCodeHpt (code,hptMap)
  = modify (\s -> s { gcsGrin   = code
                    , gcsHptMap = hptMap
                    }
           )

traceHptMap :: CompileAction ()
traceHptMap
  = do { hptMap <- gets gcsHptMap
       ; trace (showHptMap hptMap) (return ())
       }

transformCode :: (GrModule->GrModule) -> String -> CompileAction ()
transformCode process message 
  = task VerboseALot message body (const Nothing)
     where body = do { grin <- gets gcsGrin
                    ; modify (gcsUpdateGrin (process grin))
                    }

checkCode :: (GrModule->[String]) -> String -> CompileAction ()
checkCode process message
  = do { putMsg VerboseALot message Nothing
       ; grin <- gets gcsGrin
       ; let errors = process grin
       ; when (not (null errors)) (error (unlines errors))
       }

transformCodeInline :: String -> CompileAction ()
transformCodeInline message 
  = do { putMsg VerboseALot message Nothing
       ; grin <- gets gcsGrin
%%[[8
       ; let code = grInline False grin
%%][50
       ; let (code,_) = grInline False Set.empty Map.empty grin 
%%]]
       ; modify (gcsUpdateGrin code)
       }

transformCodeUseHpt :: ((GrModule,HptMap)->GrModule) -> String -> CompileAction ()
transformCodeUseHpt process message 
  = do { putMsg VerboseALot message Nothing
       ; ch <- gcsGetCodeHpt
       ; modify (gcsUpdateGrin (process ch))
       }

transformCodeChgHpt :: ((GrModule,HptMap) -> (GrModule,HptMap)) -> String -> CompileAction ()
transformCodeChgHpt process message 
  = do { putMsg VerboseALot message Nothing
       ; tup <- gcsGetCodeHpt
       ; gcsPutCodeHpt (process tup)
       }

transformCodeIterated :: (GrModule->(GrModule,Bool)) -> String -> CompileAction ()
transformCodeIterated process message 
  = task VerboseALot message (caFixCount 1) (\i -> Just $ show i ++ " iteration(s)")
     where
     caFixCount n = do
         code <- gets gcsGrin
         (code, changed) <- return $ process code
         modify (gcsUpdateGrin code)
         if changed then (caFixCount $ n+1) else return n


%%[[(8 wholeprogC)
transformSilly :: (EHCOpts->SilModule->SilModule) -> String -> CompileAction ()
transformSilly process message 
  = do { putMsg VerboseALot message Nothing
       ; silly <- gets gcsSilly
       ; options <- gets gcsOpts
       ; modify (gcsUpdateSilly (process options silly))
       }
%%]]
%%]


%%[(8 codegen grin wholeprogAnal).Errors
newtype CompileError = CompileError String
    deriving (Show)

instance Error CompileError where
    noMsg    = CompileError "internal error"
    strMsg s = CompileError s
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Compilerdriver abstractions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen grin wholeprogAnal).CompilerDriver
type CompileAction a = ErrorT CompileError (StateT GRINCompileState IO) a

drive :: GRINCompileState -> (CompileError -> IO a) -> CompileAction a -> IO a
drive initState errorHandler action = do
    result <- doAction action
    case result of
        Right suc -> return suc
        Left  err -> errorHandler err
    where
    doAction = flip evalStateT initState . runErrorT

%%]

%%[(8 codegen grin wholeprogAnal).errorHandling
ignoreErrors :: (Monad m) => a -> b -> m a
-- ignoreErrors = const . return -- does not typecheck in HM (but does in ML-F)
ignoreErrors v e = return v

harden   :: (MonadError e m) => a -> m a -> m a
harden v =  flip catchError (ignoreErrors v)

ignoreErrors_ :: (Monad m) => b -> m ()
ignoreErrors_ = ignoreErrors ()

harden_  :: (MonadError e m) => m() -> m ()
harden_  =  harden ()

force :: a -> CompileAction a
force = liftIO . evaluate
%%]

%%[(8 codegen grin wholeprogAnal)
putMsg :: Verbosity -> String -> (Maybe String) -> CompileAction ()
putMsg minVerbosity msg mbMsg =  harden_ $ do
    currentVerbosity <- gets (ehcOptVerbosity . gcsOpts)
    guard (currentVerbosity >= minVerbosity)
    let msg2    = maybe "" (\m -> " (" ++ m ++ ")") mbMsg
        message = strBlankPad 36 msg ++ msg2
    liftIO $ putStrLn message


task :: Verbosity -> String -> CompileAction a -> (a -> Maybe String) -> CompileAction ()
task minVerbosity taskDesc ca f = do
    { startMsg minVerbosity taskDesc
    ; start   <- liftIO getCPUTime
    ; result  <- ca
    -- ; g <- gets gcsGrin
    -- ; liftIO $ putStrLn (result `seq` g `seq` "debug")
    ; end     <- liftIO getCPUTime
    ; finishMsg minVerbosity (f result) (end-start)
    }
    where
    startMsg :: Verbosity -> String -> CompileAction ()
    startMsg minVerbosity msg =  harden_ $ do
        currentVerbosity <- gets (ehcOptVerbosity . gcsOpts)
        guard (currentVerbosity >= minVerbosity)
        liftIO $ putStr (strBlankPad 36 msg)

    finishMsg :: Verbosity -> Maybe String -> Integer -> CompileAction ()
    finishMsg minVerbosity mbMsg cpuTime =  harden_ $ do
        { currentVerbosity <- gets (ehcOptVerbosity . gcsOpts)
        ; guard (currentVerbosity >= minVerbosity)
        ; doTiming <- gets (ehcOptTimeGrinCompile . gcsOpts)
        ; let timeMsg      =  showFFloat (Just 5) (fromInteger cpuTime / 1000000000000) " seconds"
              formatMsg m  | doTiming   =  " (" ++ m ++ ", " ++ timeMsg ++ ")"
                           | otherwise  =  " (" ++ m ++ ")"
              defaultMsg   | doTiming   =  " (" ++ timeMsg ++ ")"
                           | otherwise  =  ""

        ; liftIO (putStrLn $ maybe defaultMsg formatMsg mbMsg)
        }

%%]



-- Idiom for doing a transformation only when the --priv=1 option is in effect:

         ; options <- gets gcsOpts
         ; when (ehcOptPriv options)
                ( do { transformCode         evalStored         "EvalStored"
                     ; caWriteGrin "-116-evalstored"
                     }
                )
