%%[0
%include lhs2TeX.fmt
%include afp.fmt
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Haskell importable interface to HI/AbsSyn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs module {%{EH}HI} import({%{EH}Base.Common},{%{EH}Opts},{%{EH}Base.HsName.Builtin},{%{EH}NameAspect})
%%]

%%[50 hs import ({%{EH}Gam.Full})
%%]

%%[(50 hmtyinfer) hs import ({%{EH}Gam.ClassDefaultGam})
%%]

%%[(50 hmtyinfer || hmtyast) hs import({%{EH}Ty})
%%]

%%[50 hs import({%{EH}Base.Target})
%%]
%%[(50 codegen) hs import({%{EH}Core}, {%{EH}LamInfo})
%%]
%%[(50 codegen tycore) hs import(qualified {%{EH}TyCore} as C)
%%]

%%[(50 grin) hs import({%{EH}GrinCode})
%%]
%%[(50 grin) hs import({%{EH}GrinByteCode})
%%]

%%[50 hs import({%{EH}Config},{%{EH}Module.ImportExport})
%%]

%%[(50 hmtyinfer) hs import({%{EH}Pred.ToCHR},{%{EH}CHR.Solve},qualified {%{EH}Gam.ClGam} as Pr)
%%]

%%[50 hs import(qualified Data.Set as Set,qualified Data.Map as Map,qualified UHC.Util.Rel as Rel,qualified UHC.Util.FastSeq as Seq,UHC.Util.Utils)
%%]

%%[5020 hs export(AGItf(..),Module(..),Binding(..),Bindings)
%%]

%%[50 hs export(Visible(..))
%%]

%%[50 hs import(Control.Monad, UHC.Util.Binary)
%%]
%%[50 hs import(Data.Typeable(Typeable), Data.Generics(Data), UHC.Util.Serialize)
%%]

%%[50 hs import(qualified {%{EH}Config} as Cfg)
%%]
%%[50 import(qualified {%{EH}SourceCodeSig} as Sig)
%%]

%%[(9999 codegen grin) hs import({%{EH}GrinCode.Trf.ForceEval})
%%]

-- for debug
%%[50 hs import({%{EH}Base.Debug},UHC.Util.Pretty)
%%]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Additional defs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs
data Visible
  = VisibleNo | VisibleYes
  deriving Eq

instance Show Visible where
  show VisibleNo  = "visibleno"
  show VisibleYes = "visibleyes"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% HI info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs export(HIInfoUsedModMp,HIInfo(..))
type HIInfoUsedModMp = (Map.Map HsName (Set.Set HsName))

data HIInfo
  = HIInfo
      { hiiValidity             :: !HIValidity                              -- a valid HI info?
      , hiiOrigin               :: !HIOrigin                                -- where did the HI come from
      , hiiSrcSig               :: !String                                  -- compiler source signature (md5)
      , hiiTarget               :: !Target                                  -- for which backend the hi is generated
      , hiiTargetFlavor         :: !TargetFlavor                            -- for which flavor the hi is generated
      , hiiCompiler             :: !String                                  -- compiler version info
      , hiiCompileFlags         :: !String                                  -- flags
      , hiiHasMain              :: !Bool                                    -- has file a main?
      , hiiModuleNm             :: !HsName                                  -- module name
      , hiiSrcTimeStamp         :: !String                                  -- timestamp of compiler source
      , hiiSrcVersionMajor      :: !String                                  -- major (etc) version numbers
      , hiiSrcVersionMinor      :: !String
      , hiiSrcVersionMinorMinor :: !String
      , hiiSrcVersionSvn        :: !String                                  -- svn version

      , hiiExps                 :: !ModEntRel                               -- exported stuff
      , hiiHiddenExps           :: !ModEntRel                               -- exported, but hidden otherwise (instances, optimized code variants, ...)
      , hiiFixityGam            :: !FixityGam                               -- fixity of identifiers
      , hiiHIDeclImpModS        :: !(Set.Set HsName)                        -- declared imports
      , hiiHIUsedImpModS        :: !(Set.Set HsName)                        -- used imports, usually indirectly via renaming
      , hiiTransClosedUsedModMp :: !HIInfoUsedModMp       					-- used modules with their imports, required to be linked together, transitively closed/cached over imported modules
      , hiiTransClosedOrphanModS:: !(Set.Set HsName)                        -- orphan modules, required to read its .hi file, transitively closed/cached over imported modules
%%[[(50 codegen hmtyinfer)
      , hiiMbOrphan             :: !(Maybe (Set.Set HsName))                -- is orphan module, carrying the module names required
%%]]
%%[[(50 hmtyinfer)
      , hiiValGam               :: !ValGam                                  -- value identifier environment
      , hiiTyGam                :: !TyGam                                   -- type identifier env
      , hiiTyKiGam              :: !TyKiGam                                 -- type/tyvar kind env
      , hiiPolGam               :: !PolGam                                  -- polarity env
      , hiiDataGam              :: !DataGam                                 -- datatype info env
      , hiiClGam                :: !Pr.ClGam                                -- class env
      , hiiClDfGam              :: !ClassDefaultGam                         -- class defaults env
      , hiiCHRStore             :: !ScopedPredStore                         -- rule database
%%]]
%%[[(50 codegen)
      , hiiLamMp                :: !LamMp                                   -- codegen info for identifiers
%%]]
%%[[(50 codegen grin)
      , hiiGrInlMp              :: !GrInlMp                                 -- grin inlineable code
%%]]
%%[[99
      , hiiImpHIMp              :: !ImpHIMp                                 -- cache of HIInfo's of imported modules, filtered for visibility
%%]]
      }
%%[[50
  deriving (Typeable, Data)
%%]]
%%]

%%[50 hs export(emptyHIInfo)
emptyHIInfo :: HIInfo
emptyHIInfo 
  = HIInfo HIValidity_Absent HIOrigin_FromFile
           "" defaultTarget defaultTargetFlavor "" "" False hsnUnknown "" "" "" "" ""
           Rel.empty Rel.empty emptyGam
           Set.empty Set.empty
           Map.empty Set.empty
%%[[(50 codegen hmtyinfer)
           Nothing
%%]]
%%[[(50 hmtyinfer)
           emptyGam emptyGam emptyGam emptyGam emptyGam emptyGam emptyGam emptyCHRStore
%%]]
%%[[(50 codegen)
           Map.empty
%%]]
%%[[(50 codegen grin)
           Map.empty
%%]]
%%[[99
           Map.empty
%%]]
%%]

%%[50 hs export(hiiIsEmpty)
-- | not empty if ok
hiiIsEmpty :: HIInfo -> Bool
hiiIsEmpty hii = hiiValidity hii /= HIValidity_Ok
%%]

%%[50 hs export(hiiIdDefOccGam)
hiiIdDefOccGam :: HIInfo -> IdDefOccGam
hiiIdDefOccGam hii = hiiIdDefOccGamFromHIIdGam $ mentrelToIdDefOccGam (hiiModuleNm hii) (hiiExps hii)
%%]

%%[5020 hs export(hiiCHRStore)
hiiCHRStore :: HIInfo -> ScopedPredStore
hiiCHRStore = hiiScopedPredStoreFromList . hiiCHRStoreL
%%]

%%[50 hs
instance Show HIInfo where
  show _ = "HIInfo"

instance PP HIInfo where
  pp i = "HIInfo" >#< (   "ModNm  =" >#< pp         (             hiiModuleNm              i)
                      >-< "DeclImp=" >#< ppCommas   (Set.toList $ hiiHIDeclImpModS         i)
                      >-< "UsedImp=" >#< ppCommas   (Set.toList $ hiiHIUsedImpModS         i)
                      >-< "AllUsed=" >#< ppAssocLV  (assocLMapElt (ppCommas . Set.toList) $ Map.toList $ hiiTransClosedUsedModMp i)
                      >-< "AllOrph=" >#< ppCommas   (Set.toList $ hiiTransClosedOrphanModS i)
%%[[(50 codegen hmtyinfer)
                      >-< "MbOrph =" >#< ppCommas   (maybe [] Set.toList $ hiiMbOrphan     i)
%%]]
                      -- >-< "Exps="    >#< pp         (hiiExps          i)
                      -- >-< "Exps(H)=" >#< pp         (hiiHiddenExps    i)
                      -- >-< "ValGam =" >#< pp         (hiiValGam        i)
                      -- >-< "TyGam  =" >#< pp         (hiiTyGam         i)
%%[[99
                      -- >-< "Cached =" >#< ppAssocLV  (assocLMapElt pp $ Map.toList $ hiiImpHIMp    i)
%%]]
                      )
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Retain info of a HI which is still needed after cleanup.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[9999 hs export(hiiRetainAfterCleanup)
hiiRetainAfterCleanup :: HIInfo -> HIInfo
hiiRetainAfterCleanup hii
  = emptyHIInfo
      { hiiTransClosedUsedModMp		=	hiiTransClosedUsedModMp		hii
      , hiiTransClosedOrphanModS	=	hiiTransClosedOrphanModS	hii
      , hiiMbOrphan					=	hiiMbOrphan					hii
      }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Utils for caching imported HIInfos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 hs export(ImpHIMp)
type ImpHIMp = Map.Map HsName HIInfo

%%]

%%[99 hs export(hiiUnion)
-- | combine HI info for a single module, as extracted from the cached hiiImpHIMp of the module importing these combined modules
hiiUnion :: HIInfo -> HIInfo -> HIInfo
hiiUnion m1 m2
  = m1 { hiiFixityGam           = hiiFixityGam      m1 `gamUnion`       hiiFixityGam    m2
       -- , hiiIdDefHIIdGam        = hiiIdDefHIIdGam    m1 `gamUnion`       hiiIdDefHIIdGam m2
%%[[(99 hmtyinfer)
       , hiiValGam              = hiiValGam         m1 `gamUnion`       hiiValGam       m2
       , hiiTyGam               = hiiTyGam          m1 `gamUnion`       hiiTyGam        m2
       , hiiTyKiGam             = hiiTyKiGam        m1 `gamUnion`       hiiTyKiGam      m2
       , hiiPolGam              = hiiPolGam         m1 `gamUnion`       hiiPolGam       m2
       , hiiDataGam             = hiiDataGam        m1 `gamUnion`       hiiDataGam      m2
       , hiiClGam               = hiiClGam          m1 `gamUnion`       hiiClGam        m2
       , hiiClDfGam             = hiiClDfGam        m1 `gamUnion`       hiiClDfGam      m2
       , hiiCHRStore            = hiiCHRStore       m1 `chrStoreUnion`  hiiCHRStore     m2
%%]]
%%[[(99 codegen)
       , hiiLamMp               = hiiLamMp          m1 `Map.union`      hiiLamMp        m2
%%]]
%%[[(99 codegen grin)
       , hiiGrInlMp             = hiiGrInlMp        m1 `Map.union`      hiiGrInlMp      m2
%%]]
       }
%%]

%%[99 hs
-- | restrict envs to the ones being in the filter map, so only those visible relative to that map remain
hiiRestrictToFilterMp :: ModEntRelFilterMp -> HIInfo -> HIInfo
hiiRestrictToFilterMp mfm hii
  = hii
      { hiiFixityGam            = fg expVT $ hiiFixityGam       hii
      -- , hiiIdDefHIIdGam         = fg (\o -> exp (ioccKind o) (ioccNm o))
      --                                      $ hiiIdDefHIIdGam    hii
%%[[(99 hmtyinfer)
      , hiiValGam               = fg expV  $ hiiValGam          hii
      , hiiTyGam                = fg expT  $ hiiTyGam           hii
      , hiiTyKiGam              = fg expT' $ hiiTyKiGam         hii
      , hiiPolGam               = fg expT  $ hiiPolGam          hii
      , hiiDataGam              = fg expT  $ hiiDataGam         hii
      , hiiClGam                = fg expC  $ hiiClGam           hii
      , hiiClDfGam              = fg expC  $ hiiClDfGam         hii
%%]]
%%[[(99 codegen)
      , hiiLamMp                = fm expV  $ hiiLamMp           hii
%%]]
%%[[(99 codegen grin)
      , hiiGrInlMp              = fm expV  $ hiiGrInlMp         hii
%%]]
      }
  where exp k  = (`Set.member` Map.findWithDefault Set.empty k mfm)
        expV   = exp IdOcc_Val
        expT   = exp IdOcc_Type
%%[[(99 hmtyinfer)
        expT'  = maybe False (exp IdOcc_Type) . tyKiKeyMbName
%%]]
        expVT x= expV x || expT x
        expC   = expT -- exp IdOcc_Class
        fg p   = fst . gamPartition (\k _ -> p k)
        fm p   = Map.filterWithKey (\k _ -> p k)
%%]

%%[99 hs
-- | restrict envs to the ones being exported, so only the visible part remains
hiiRestrictToExported :: HIInfo -> HIInfo
hiiRestrictToExported hii = hiiRestrictToFilterMp (mentrelToFilterMp [] (hiiExps hii) `mentrelFilterMpUnion` mentrelToFilterMp [] (hiiHiddenExps hii)) hii
%%]

%%[99 hs export(hiiIncludeCacheOfImport)
-- | include the imported HIInfos in this one, restricted to their exports, to be done just before saving
hiiIncludeCacheOfImport :: (HsName -> HIInfo) -> ModEntRelFilterMp -> HIInfo -> HIInfo
hiiIncludeCacheOfImport imp mfm hii
  = hii
      { hiiImpHIMp = Map.map reset $ Map.unions [top, subtop]
      }
  where -- imports of this module
        top    = Map.unions [ Map.singleton i $ hiiRestrictToFilterMp mfm $ {- (\x -> tr "hiiIncludeCacheOfImport.1" (i >#< x) x) $ -} imp i | i <- Set.toList $ hiiHIDeclImpModS hii `Set.union` hiiHIUsedImpModS hii ]

        -- the closure of the imports w.r.t. import relationship
        subtop = Map.map (hiiRestrictToFilterMp mfm) $ Map.unionsWith hiiUnion $ map hiiImpHIMp $ Map.elems top
        
        -- reset some info in cached hii's
        reset hii = hii { hiiImpHIMp                = Map.empty
                        , hiiExps                   = Rel.empty
                        , hiiHiddenExps             = Rel.empty
                        , hiiHIDeclImpModS          = Set.empty
                        , hiiHIUsedImpModS          = Set.empty
%%[[(99 hmtyinfer)
                        , hiiCHRStore               = emptyCHRStore     -- this cannot be, but no solution for filtering this...
%%]]
                        , hiiSrcSig                 = ""
                        , hiiCompiler               = ""
                        , hiiSrcTimeStamp           = ""
                        , hiiSrcVersionMajor        = ""
                        , hiiSrcVersionMinor        = ""
                        , hiiSrcVersionMinorMinor   = ""
                        , hiiSrcVersionSvn          = ""
                        }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Reconstruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 export(mentrelToIdDefOccGam)
mentrelToIdDefOccGam :: HsName -> ModEntRel -> Gam IdOcc IdOcc -- IdDefOccGam
mentrelToIdDefOccGam modNm r
  = gamFromAssocL
      [ ( IdOcc n' k
        -- , mkIdDefOcc (IdOcc (ioccNm $ mentIdOcc e) k) IdAsp_Any nmLevOutside emptyRange
        , IdOcc (ioccNm $ mentIdOcc e) k
        )
      | (n,e) <- Rel.toList r
      , let k  = ioccKind $ mentIdOcc e
            n' = hsnSetQual modNm n
      ]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Conversions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs export(hiiIdDefOccGamToHIIdGam,hiiIdDefOccGamFromHIIdGam)
hiiIdDefOccGamToHIIdGam :: IdDefOccGam -> Gam IdOcc IdOcc
hiiIdDefOccGamToHIIdGam = gamMap (\(k,v) -> (k,doccOcc v))

hiiIdDefOccGamFromHIIdGam :: Gam IdOcc IdOcc -> IdDefOccGam
hiiIdDefOccGamFromHIIdGam = gamMap (\(k,v) -> (k,mkIdDefOcc v IdAsp_Any nmLevOutside emptyRange))
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Validity, origin of HI file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs export(HIOrigin(..))
data HIOrigin
  = HIOrigin_FromFile                               -- from .hi file
  | HIOrigin_FromImportedBy HsNameS                 -- reconstructed from modules which imported this hi
  deriving (Eq,Show,Typeable,Data)
%%]

%%[50 hs export(HIValidity(..))
data HIValidity
  = HIValidity_Ok               -- ok
  | HIValidity_WrongMagic       -- wrong magic number
  | HIValidity_Inconsistent     -- inconsistent with compiler
  | HIValidity_Absent           -- not available
  deriving (Eq,Enum,Show,Typeable,Data)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gam flattening
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs
gamFlatten :: Ord k => Gam k v -> Gam k v
gamFlatten = id -- gamFromAssocL . gamToAssocL
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Instances: Binary, Serialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[50 hs
instance Serialize HIValidity where
  sput = sputEnum8
  sget = sgetEnum8
%%]

%%[50 hs export(sgetHIInfo)
sgetHIInfo :: EHCOpts -> SGet HIInfo
sgetHIInfo opts = do
  { hi_magic <- sequence $ replicate (length Cfg.magicNumberHI) sgetWord8
  ; if hi_magic == Cfg.magicNumberHI
    then do { hi_sig   <- sget
            ; hi_ts    <- sget
            ; hi_t     <- sget
            ; hi_tv    <- sget
            ; hi_fl    <- sget
            ; hi_comp  <- sget
            ; if (    hi_sig == Sig.sig
                   && hi_ts  == Sig.timestamp
                   && hi_t   == ehcOptTarget       opts
                   && hi_tv  == ehcOptTargetFlavor opts
                 )
%%[[99
                 || not (ehcOptHiValidityCheck opts)
%%]]
              then do { hi_nm     <- sget
                      ; hi_hm     <- sget
                      ; hi_m      <- sget
                      ; hi_mm     <- sget
                      ; hi_mmm    <- sget
                      ; hi_svn    <- sget
                      ; e         <- sget
                      ; he        <- sget
                      ; fg        <- sget
                      ; impd      <- sget
                      ; impu      <- sget
                      ; tclused   <- sget
                      ; tclorph   <- sget
%%[[(50 codegen hmtyinfer)
                      ; isorph    <- sget
%%]]
%%[[(50 hmtyinfer)
                      ; vg        <- sget
                      ; tg        <- sget
                      ; tkg       <- sget
                      ; pg        <- sget
                      ; dg        <- sget
                      ; cg        <- sget
                      ; cdg       <- sget
                      ; cs        <- sget
%%]]
%%[[(50 codegen)
                      ; am        <- sget
%%]]
%%[[(50 codegen grin)
                      ; im        <- sget
%%]]
%%[[99
                      ; him       <- sget
%%]]
                      ; return 
                          (emptyHIInfo
                            { hiiValidity             = HIValidity_Ok
                            , hiiSrcSig               = hi_sig
                            , hiiCompiler             = hi_comp
                            , hiiCompileFlags         = hi_fl
                            , hiiTarget               = hi_t
                            , hiiTargetFlavor         = hi_tv
                            , hiiHasMain              = hi_hm
                            , hiiSrcTimeStamp         = hi_ts
                            , hiiModuleNm             = hi_nm
                            , hiiSrcVersionMajor      = hi_m
                            , hiiSrcVersionMinor      = hi_mm
                            , hiiSrcVersionMinorMinor = hi_mmm
                            , hiiSrcVersionSvn        = hi_svn
                            , hiiExps                 = e
                            , hiiHiddenExps           = he
                            , hiiFixityGam            = fg
                            , hiiHIDeclImpModS        = impd
                            , hiiHIUsedImpModS        = impu
                            , hiiTransClosedUsedModMp = tclused
                            , hiiTransClosedOrphanModS= tclorph
%%[[(50 codegen hmtyinfer)
                            , hiiMbOrphan             = isorph
%%]]
%%[[(50 hmtyinfer)
                            , hiiValGam               = vg
                            , hiiTyGam                = tg
                            , hiiTyKiGam              = tkg
                            , hiiPolGam               = pg
                            , hiiDataGam              = dg
                            , hiiClGam                = cg
                            , hiiClDfGam              = cdg
                            , hiiCHRStore             = cs
%%]]
%%[[(50 codegen)
                            , hiiLamMp                = am
%%]]
%%[[(50 codegen grin)
                            , hiiGrInlMp              = im
%%]]
%%[[99
                            , hiiImpHIMp              = him
%%]]
                            })
                      }
              else return $
                     emptyHIInfo
                       { hiiValidity             = HIValidity_Inconsistent
                       , hiiSrcSig               = hi_sig
                       , hiiSrcTimeStamp         = hi_ts
                       , hiiCompileFlags         = hi_fl
                       , hiiCompiler             = hi_comp
                       , hiiTarget               = hi_t
                       , hiiTargetFlavor         = hi_tv
                       }
            }
    else return $
           emptyHIInfo
             { hiiValidity             = HIValidity_WrongMagic
             }
  }
%%]

%%[50 hs
instance Serialize HIInfo where
  sput       (HIInfo
                  { hiiSrcSig               = hi_sig
                  , hiiTarget               = hi_t
                  , hiiTargetFlavor         = hi_tv
                  , hiiCompiler             = hi_comp
                  , hiiCompileFlags         = hi_fl
                  , hiiModuleNm             = hi_nm
                  , hiiHasMain              = hi_hm
                  , hiiSrcTimeStamp         = hi_ts
                  , hiiSrcVersionMajor      = hi_m
                  , hiiSrcVersionMinor      = hi_mm
                  , hiiSrcVersionMinorMinor = hi_mmm
                  , hiiSrcVersionSvn        = hi_svn
                  , hiiExps                 = e
                  , hiiHiddenExps           = he
                  , hiiFixityGam            = fg
                  , hiiHIDeclImpModS        = impd
                  , hiiHIUsedImpModS        = impu
                  , hiiTransClosedUsedModMp = tclused
                  , hiiTransClosedOrphanModS= tclorph
%%[[(50 codegen hmtyinfer)
                  , hiiMbOrphan             = isorph
%%]]
%%[[(50 hmtyinfer)
                  , hiiValGam               = vg
                  , hiiTyGam                = tg
                  , hiiTyKiGam              = tkg
                  , hiiPolGam               = pg
                  , hiiDataGam              = dg
                  , hiiClGam                = cg
                  , hiiClDfGam              = cdg
                  , hiiCHRStore             = cs
%%]]
%%[[(50 codegen)
                  , hiiLamMp                = am
%%]]
%%[[(50 codegen grin)
                  , hiiGrInlMp              = im
%%]]
%%[[99
                  , hiiImpHIMp              = him
%%]]
                  })
              =    mapM sputWord8 Cfg.magicNumberHI
                >> sput hi_sig
                >> sput hi_ts
                >> sput hi_t
                >> sput hi_tv
                >> sput hi_fl
                >> sput hi_comp
                >> sput hi_nm
                >> sput hi_hm
                >> sput hi_m
                >> sput hi_mm
                >> sput hi_mmm
                >> sput hi_svn
                >> sput e
                >> sput he
                >> sput (gamFlatten fg)
                >> sput impd
                >> sput impu
                >> sput tclused
                >> sput tclorph
%%[[(50 codegen hmtyinfer)
                >> sput isorph
%%]]
%%[[(50 hmtyinfer)
                >> sput (gamFlatten vg)
                >> sput (gamFlatten tg)
                >> sput (gamFlatten tkg)
                >> sput (gamFlatten pg)
                >> sput (gamFlatten dg)
                >> sput (gamFlatten cg)
                >> sput (gamFlatten cdg)
                >> sput cs
%%]]
%%[[(50 codegen)
                >> sput am
%%]]
%%[[(50 codegen grin)
                >> sput im
%%]]
%%[[99
                >> sput him
%%]]

  sget = sgetHIInfo (defaultEHCOpts
%%[[99
                       { ehcOptHiValidityCheck = False
                       }
%%]]
                    )
%%]

