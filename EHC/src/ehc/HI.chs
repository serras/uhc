%%[0
%include lhs2TeX.fmt
%include afp.fmt
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Haskell importable interface to HI/AbsSyn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs module {%{EH}HI} import({%{EH}Base.Common},{%{EH}Base.Opts},{%{EH}NameAspect})
%%]

%%[(20 hmtyinfer || hmtyast) hs import ({%{EH}Gam.Full},{%{EH}Gam.ClassDefaultGam})
%%]

%%[(20 hmtyinfer || hmtyast) hs import({%{EH}Ty})
%%]

%%[(20 codegen) hs import({%{EH}Base.Target})
%%]
%%[(20 codegen) hs import({%{EH}Core}, {%{EH}LamInfo})
%%]
%%[(20 codegen) hs import(qualified {%{EH}TyCore} as C)
%%]

%%[(20 codegen grin) hs import({%{EH}GrinCode})
%%]
%%[(20 codegen grin) hs import({%{EH}GrinByteCode})
%%]

%%[20 hs import({%{EH}Config},{%{EH}Module})
%%]

%%[(20 hmtyinfer) hs import({%{EH}Pred.ToCHR},{%{EH}CHR.Solve},qualified {%{EH}Pred} as Pr)
%%]

%%[20 hs import(qualified Data.Map as Map,qualified EH.Util.Rel as Rel,qualified EH.Util.FastSeq as Seq,EH.Util.Utils)
%%]

%%[2020 hs export(AGItf(..),Module(..),Binding(..),Bindings)
%%]

%%[20 hs export(Visible(..))
%%]

%%[20 hs import(Control.Monad, {%{EH}Base.Binary})
%%]
%%[20 hs import(Data.Typeable(Typeable), Data.Generics(Data), {%{EH}Base.Serialize})
%%]

%%[9999 hs import({%{EH}Base.ForceEval})
%%]

%%[(9999 codegen grin) hs import({%{EH}GrinCode.Trf.ForceEval})
%%]

-- for debug
%%[20 hs import({%{EH}Base.Debug},EH.Util.Pretty)
%%]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Additional defs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs
data Visible
  = VisibleNo | VisibleYes
  deriving Eq

instance Show Visible where
  show VisibleNo  = "visibleno"
  show VisibleYes = "visibleyes"
%%]

%%[2020 hs export(HILamInfo(..),emptyHILamInfo)
-- | Info about function implementation which must be visible across modules
data HILamInfo
  = HILamInfo
      { hilaminfoGrinByteCode :: GrinByteCodeLamInfo
      }
  deriving (Typeable, Data)

emptyHILamInfo :: HILamInfo
emptyHILamInfo = HILamInfo emptyGrinByteCodeLamInfo
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% HI info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs export(HIInfo(..), emptyHIInfo)
data HIInfo
  = HIInfo
      { hiiValidity             :: !HIValidity
      , hiiSrcSig               :: !String
      , hiiTargetFlavor         :: !TargetFlavor
      , hiiCompiler             :: !String
      , hiiCompileFlags         :: !String
      , hiiHasMain              :: !Bool
      , hiiSrcTimeStamp         :: !String
      , hiiSrcVersionMajor      :: !String
      , hiiSrcVersionMinor      :: !String
      , hiiSrcVersionMinorMinor :: !String
      , hiiSrcVersionSvn        :: !String

      , hiiExps                 :: !ModEntRel
      , hiiHiddenExps           :: !ModEntRel
      , hiiFixityGam            :: !FixityGam
      , hiiIdDefAssocL          :: !(AssocL IdOcc IdOcc) -- IdDefOccGam
      , hiiHIDeclImpModL        :: ![HsName]
      , hiiHIUsedImpModL        :: ![HsName]
%%[[(20 hmtyinfer)
      , hiiValGam               :: !ValGam
      , hiiTyGam                :: !TyGam
      , hiiTyKiGam              :: !TyKiGam
      , hiiPolGam               :: !PolGam
      , hiiDataGam              :: !DataGam
      , hiiClGam                :: !Pr.ClGam
      , hiiClDfGam              :: !ClassDefaultGam
      , hiiCHRStoreL            :: !ScopedPredStoreL
%%]]
%%[[(20 codegen)
      , hiiLamMp                :: !LamMp
%%]]
%%[[(20 codegen grin)
      , hiiGrInlMp              :: !GrInlMp
%%]]
      }
%%[[20
  deriving (Typeable, Data)
%%]]

emptyHIInfo :: HIInfo
emptyHIInfo 
  = HIInfo HIValidity_Absent "" defaultTargetFlavor "" "" False "" "" "" "" ""
           Rel.empty Rel.empty emptyGam []
           [] []
           -- emptyHiSettings
%%[[(20 hmtyinfer)
           emptyGam emptyGam emptyGam emptyGam emptyGam emptyGam emptyGam []
%%]]
%%[[(20 codegen)
           Map.empty
%%]]
%%[[(20 codegen grin)
           Map.empty
%%]]
%%]

%%[20 hs export(hiiIdDefOccGam,hiiCHRStore)
hiiIdDefOccGam :: HIInfo -> IdDefOccGam
hiiIdDefOccGam = hiiIdDefOccGamFromAssocL . hiiIdDefAssocL

hiiCHRStore :: HIInfo -> ScopedPredStore
hiiCHRStore = hiiScopedPredStoreFromList . hiiCHRStoreL
%%]

%%[20 hs
instance Show HIInfo where
  show _ = "HIInfo"

instance PP HIInfo where
  pp i = "HIInfo" >#< (   "DeclImp=" >|< ppCommas (hiiHIDeclImpModL i)
                      >-< "UsedImp=" >|< ppCommas (hiiHIUsedImpModL i)
                      )
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Conversions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs export(hiiIdDefOccGamToAssocL,hiiIdDefOccGamFromAssocL)
hiiIdDefOccGamToAssocL :: IdDefOccGam -> AssocL IdOcc IdOcc
hiiIdDefOccGamToAssocL idg = [ (o,doccOcc docc) | (o,docc) <- gamToAssocL idg ]

hiiIdDefOccGamFromAssocL :: AssocL IdOcc IdOcc -> IdDefOccGam
hiiIdDefOccGamFromAssocL l = gamFromAssocL [ (o,mkIdDefOcc od IdAsp_Any nmLevOutside emptyRange) | (o,od) <- l ]
%%]

%%[20 hs export(hiiScopedPredStoreToList,hiiScopedPredStoreFromList)
hiiScopedPredStoreToList :: ScopedPredStore -> ScopedPredStoreL
hiiScopedPredStoreToList s = chrStoreElems s

hiiScopedPredStoreFromList :: ScopedPredStoreL -> ScopedPredStore
hiiScopedPredStoreFromList = chrStoreFromElems
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Validity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs export(HIValidity(..))
data HIValidity
  = HIValidity_Ok				-- ok
  | HIValidity_Inconsistent		-- inconsistent with compiler
  | HIValidity_Absent			-- not available
  deriving (Eq,Enum,Show,Typeable,Data)
%%]

%%[2020 hs export(hiiPostCheckValidity)
hiiPostCheckValidity :: EHCOpts -> HIInfo -> HIInfo
hiiPostCheckValidity opts i
  = i { hiiIsValid
          =    hiiIsValid i
            -- && optsDiscrRecompileRepr opts == hiiCompileFlags  i
            && ehcOptTargetFlavor    opts == hiiTargetFlavor i
      }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gam flattening
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs
gamFlatten :: Ord k => Gam k v -> Gam k v
gamFlatten = id -- gamFromAssocL . gamToAssocL
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Instances: Binary, Serialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[20 hs
instance Serialize HIValidity where
  sput = sputEnum8
  sget = sgetEnum8
%%]

%%[20 hs export(sgetHIInfo)
sgetHIInfo :: EHCOpts -> SGet HIInfo
sgetHIInfo opts = do
  { hi_sig  <- sget
  ; hi_ts   <- sget
  ; hi_tv   <- sget
  ; hi_fl   <- sget
  ; hi_comp <- sget
  ; if (    hi_sig == verSig version
         && hi_ts  == verTimestamp version
         && hi_tv  == ehcOptTargetFlavor opts
       )
%%[[99
       || not (ehcOptHiValidityCheck opts)
%%]]
    then do { hi_hm     <- sget
            ; hi_m      <- sget
            ; hi_mm     <- sget
            ; hi_mmm    <- sget
            ; hi_svn    <- sget
            ; e         <- sget
            ; he        <- sget
            ; fg        <- sget
            ; idg       <- sget
            ; impd      <- sget
            ; impu      <- sget
%%[[(20 hmtyinfer)
            ; vg        <- sget
            ; tg        <- sget
            ; tkg       <- sget
            ; pg        <- sget
            ; dg        <- sget
            ; cg        <- sget
            ; cdg       <- sget
            ; cs        <- sget
%%]]
%%[[(99 codegen)
            ; am        <- sget
%%]]
%%[[(99 codegen grin)
            ; im        <- sget
%%]]
            ; return 
                (emptyHIInfo
                  { hiiValidity             = HIValidity_Ok
                  , hiiSrcSig               = hi_sig
                  , hiiCompiler             = hi_comp
                  , hiiCompileFlags         = hi_fl
                  , hiiTargetFlavor         = hi_tv
                  , hiiHasMain              = hi_hm
                  , hiiSrcTimeStamp         = hi_ts
                  , hiiSrcVersionMajor      = hi_m
                  , hiiSrcVersionMinor      = hi_mm
                  , hiiSrcVersionMinorMinor = hi_mmm
                  , hiiSrcVersionSvn        = hi_svn
                  , hiiExps                 = e
                  , hiiHiddenExps           = he
                  , hiiFixityGam            = fg
                  , hiiIdDefAssocL          = {- tr "HIInfo.Binary.get idGam" (pp $ lookup (IdOcc (mkHNm "Prelude.putStrLn") IdOcc_Val) idg) $ -}
                                              idg
                  , hiiHIDeclImpModL        = impd
                  , hiiHIUsedImpModL        = impu
%%[[(20 hmtyinfer)
                  , hiiValGam               = vg
                  , hiiTyGam                = tg
                  , hiiTyKiGam              = tkg
                  , hiiPolGam               = pg
                  , hiiDataGam              = dg
                  , hiiClGam                = cg
                  , hiiClDfGam              = cdg
                  , hiiCHRStoreL            = cs
%%]]
%%[[(99 codegen)
                  , hiiLamMp                = am
%%]]
%%[[(99 codegen grin)
                  , hiiGrInlMp              = im
%%]]
                  })
            }
    else do { return
                (emptyHIInfo
                  { hiiValidity             = HIValidity_Inconsistent
                  , hiiSrcSig               = hi_sig
                  , hiiSrcTimeStamp         = hi_ts
                  , hiiCompileFlags         = hi_fl
                  , hiiCompiler             = hi_comp
                  , hiiTargetFlavor         = hi_tv
                  })
            }
  }
%%]

instance Serialize HILamInfo where
  sput (HILamInfo a) = sput a
  sget = liftM  HILamInfo sget

%%[20 hs
instance Serialize HIInfo where
  sput       (HIInfo
                  { hiiSrcSig               = hi_sig
                  , hiiTargetFlavor         = hi_tv
                  , hiiCompiler             = hi_comp
                  , hiiCompileFlags         = hi_fl
                  , hiiHasMain              = hi_hm
                  , hiiSrcTimeStamp         = hi_ts
                  , hiiSrcVersionMajor      = hi_m
                  , hiiSrcVersionMinor      = hi_mm
                  , hiiSrcVersionMinorMinor = hi_mmm
                  , hiiSrcVersionSvn        = hi_svn
                  , hiiExps                 = e
                  , hiiHiddenExps           = he
                  , hiiFixityGam            = fg
                  , hiiIdDefAssocL          = idg
                  , hiiHIDeclImpModL        = impd
                  , hiiHIUsedImpModL        = impu
%%[[(20 hmtyinfer)
                  , hiiValGam               = vg
                  , hiiTyGam                = tg
                  , hiiTyKiGam              = tkg
                  , hiiPolGam               = pg
                  , hiiDataGam              = dg
                  , hiiClGam                = cg
                  , hiiClDfGam              = cdg
                  , hiiCHRStoreL            = cs
%%]]
%%[[(99 codegen)
                  , hiiLamMp                = am
%%]]
%%[[(99 codegen grin)
                  , hiiGrInlMp              = im
%%]]
                  })
              =    sput hi_sig
                >> sput hi_ts
                >> sput hi_tv
                >> sput hi_fl
                >> sput hi_comp
                >> sput hi_hm
                >> sput hi_m
                >> sput hi_mm
                >> sput hi_mmm
                >> sput hi_svn
                >> sput e
                >> sput he
                >> sput (gamFlatten fg)
                >> sput idg
                >> sput impd
                >> sput impu
%%[[(20 hmtyinfer)
                >> sput (gamFlatten vg)
                >> sput (gamFlatten tg)
                >> sput (gamFlatten tkg)
                >> sput (gamFlatten pg)
                >> sput (gamFlatten dg)
                >> sput (gamFlatten cg)
                >> sput (gamFlatten cdg)
                >> sput cs
%%]]
%%[[(99 codegen)
                >> sput am
%%]]
%%[[(99 codegen grin)
                >> sput im
%%]]

  sget = sgetHIInfo defaultEHCOpts
%%]

%%[20 hs
-- instance Serialize HIInfo
%%]

