%%[0
%include lhs2TeX.fmt
%include afp.fmt
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% TyCore base
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs module {%{EH}TyCore.Base} import({%{EH}Base.HsName.Builtin},{%{EH}Base.Common},{%{EH}Opts})
%%]
%%[(8 codegen tycore) hs import ({%{EH}TyCore},{%{EH}Ty.ToTyCore}) export(module {%{EH}TyCore},module {%{EH}Ty.ToTyCore})
%%]
%%[(8 codegen tycore) hs import({%{EH}AbstractCore},{%{EH}AbstractCore.Utils})
%%]
%%[(8 codegen tycore) hs import({%{EH}Error})
%%]

%%[(8888 codegen) hs import({%{EH}Core}(ctagTrue, ctagFalse, ctagCons,ctagNil)) export(ctagCons,ctagNil)
%%]

%%[(8 codegen tycore) hs import(Data.Maybe,Data.Char,Data.List,UHC.Util.Pretty,qualified UHC.Util.FastSeq as Seq)
%%]

%%[(8 codegen tycore) hs import(qualified Data.Map as Map,qualified Data.Set as Set)
%%]

-- import Ty (and others) only qualified
%%[(8 codegen tycore) hs import(qualified {%{EH}Ty} as T)
%%]
%%[(8888 codegen) hs import(qualified {%{EH}Gam} as G)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Abstract syntax for encoding case+pattern rewrite info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(RAlt,RPat,RPatConBind,RPatFld)
type RAlt 			= RAlt' 		Expr Ty ValBind PatRest
type RPat 			= RPat' 		Expr Ty ValBind PatRest
type RPatConBind 	= RPatConBind' 	Expr Ty ValBind PatRest
type RPatFld 		= RPatFld' 		Expr Ty ValBind PatRest
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Utility functions for CMeta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(metasDefault)
metasDefault :: Metas
metasDefault = (MetaBind_Plain,MetaVal_Val)
%%]

%%[(8 codegen tycore) hs export(metasVal)
metasVal :: Metas -> MetaVal
metasVal (_,v) = v
%%]

%%[(8 codegen tycore) hs export(metasMapVal)
metasMapVal :: (MetaVal -> MetaVal) -> Metas -> Metas
metasMapVal f (b,v) = (b,f v)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Context: strictness as required by context
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(EvalCtx(..),isStrict)
data EvalCtx
  = EvalCtx_None         -- nothing known, no strictness required
  | EvalCtx_Eval         -- strictness (thus eval) required
  | EvalCtx_EvalUnbox    -- strictness (thus eval) + unboxing required
  deriving Eq

isStrict :: EvalCtx -> Bool
isStrict EvalCtx_Eval        = True
isStrict EvalCtx_EvalUnbox   = True
isStrict _                   = False
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(exprIsLam)
exprIsLam :: Expr -> Bool
exprIsLam (Expr_Lam   _ _) = True
exprIsLam (Expr_Arrow _ _) = True
exprIsLam _                = False
%%]

%%[(8888 codegen) hs export(valBindNm)
valBindNm :: ValBind -> HsName
valBindNm (ValBind_Val       b _ _ _) | isJust mb = n
  where mb@(~Just (n,_)) = exprSeqMbL0Bind b
-- valBindNm (ValBind_FFI _ _ _ n _  ) = n
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Remove duplicate bindings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(9999 codegen) hs export(valBindLNub)
valBindLNub :: ValBindL -> ValBindL
valBindLNub = nubBy (\b1 b2 -> valBindNm b1 == valBindNm b2)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Lifting to MetaVal tupled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8888 codegen) hs export(metaLift)
metaLift :: Functor f => f x -> f (x,MetaVal)
metaLift = fmap2Tuple MetaVal_Val
%%]

%%[(9999 codegen) hs export(metaLiftDict)
metaLiftDict :: Functor f => f x -> f (x,MetaVal)
metaLiftDict = fmap2Tuple (MetaVal_Dict Nothing)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Construction: val/ty binding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(mkValBind1LevMetas)
mkValBind1LevMetas :: Bool -> HsName -> MetaLev -> Metas -> Ty -> Expr -> ValBind
mkValBind1LevMetas doMkSeq n l m t e
  = ValBind_Val b (if metasIsDflt m then Nothing else Just m) l e'
  where e' = if doMkSeq then mkExprSeq  e
                        else mkExprSeq1 e
        s  = ExprSeq1_L0Bind n t
        b  = if doMkSeq then Expr_Seq  [s]
                        else Expr_Seq1  s
%%]

%%[(8 codegen tycore) hs export(mkValBind1Meta,mkValStrictBind1Meta)
mkValBind1LevMeta :: Bool -> HsName -> MetaLev -> MetaVal -> Ty -> Expr -> ValBind
mkValBind1LevMeta doMkSeq n l m t e = mkValBind1LevMetas doMkSeq n l (MetaBind_Plain,m) t e

mkValBind1Meta :: HsName -> MetaVal -> Ty -> Expr -> ValBind
mkValBind1Meta n m t e = mkValBind1LevMeta True n 0 m t e

mkValStrictBind1Meta :: HsName -> MetaVal -> Ty -> Expr -> ValBind
mkValStrictBind1Meta n m t e = mkValBind1LevMeta False n 0 m t e
%%]

%%[(8 codegen tycore) hs export(mkValBind1,mkValStrictBind1,mkValThunkBind1)
mkValBind1 :: HsName -> Ty -> Expr -> ValBind
mkValBind1 n t e = mkValBind1Meta n MetaVal_Val t e

mkValStrictBind1 :: HsName -> Ty -> Expr -> ValBind
mkValStrictBind1 n t e = mkValStrictBind1Meta n MetaVal_Val t e

mkValThunkBind1 :: HsName -> Ty -> Expr -> ValBind
mkValThunkBind1 n t e = mkValBind1 n (mkTyThunk t) (mkExprThunk e)
%%]

%%[(8 codegen tycore) hs export(mkValBind1FFI)
mkValBind1FFI :: HsName -> Ty -> Expr -> ValBind
mkValBind1FFI n t e = mkValBind1Meta n MetaVal_Val t e
%%]

%%[(8 codegen tycore) hs export(mkTyBind1)
mkTyBind1 :: HsName -> Ty -> Expr -> ValBind
mkTyBind1 n t e = mkValBind1LevMeta True n 1 MetaVal_Val t e
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Construction: cast and alike
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(mkCast)
mkCast :: Ty -> Ty -> Expr -> Expr
mkCast frTy toTy e
  = Expr_Cast e (Expr_Unsafe frTy toTy)
%%]

%%[(8 codegen tycore) hs export(mkInject)
mkInject :: CTag -> Ty -> Expr -> Expr
mkInject tag toTy e
  = Expr_Inject e tag toTy
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Construction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs
mkExprApp1' :: (Expr->Expr) -> Expr -> Expr -> Expr
mkExprApp1' mka f a = Expr_App f (mka $ Expr_Seq [ExprSeq1_L0Val a])

mkExprApp1 :: Expr -> Expr -> Expr
mkExprApp1 = mkExprApp1' id

mkExprApp1Meta' :: (Expr->Expr) -> Expr -> Expr -> MetaVal -> Expr
mkExprApp1Meta' mka f a m = mkExprApp1' mka f a

mkExprApp1Meta :: Expr -> Expr -> MetaVal -> Expr
mkExprApp1Meta = mkExprApp1Meta' id

mkExprAppMeta' :: (Expr->Expr) -> Expr -> [(Expr,MetaVal)] -> Expr
mkExprAppMeta' mka f as = foldl (\f (a,m) -> mkExprApp1Meta' mka f a m) f as

mkExprAppMeta :: Expr -> [(Expr,MetaVal)] -> Expr
mkExprAppMeta f as = foldl (\f (a,m) -> mkExprApp1Meta f a m) f as
%%]

%%[(8 codegen tycore) hs
mkExprApp1Ty :: Expr -> Ty -> Expr
mkExprApp1Ty f t = Expr_App f (Expr_Seq [ExprSeq1_L1Val t])

mkExprAppTy :: Expr -> [Ty] -> Expr
mkExprAppTy f as = foldl mkExprApp1Ty f as
%%]

%%[(8 codegen tycore) hs
mkTyApp :: Ty -> [Ty] -> Ty
mkTyApp f as = mkExprAppMeta' mkTySeq1 f (acoreMetaLift as)
%%]

%%[(8 codegen tycore) hs
mkExprLam1Meta' :: (Expr->Expr) -> HsName -> MetaVal -> Ty -> Expr -> Expr
mkExprLam1Meta' mka a m t e = Expr_Lam (mka $ Expr_Seq [ExprSeq1_L0Bind a t]) e

mkExprLam1Meta :: HsName -> MetaVal -> Ty -> Expr -> Expr
mkExprLam1Meta = mkExprLam1Meta' id

mkExprLamMeta :: [(HsName,MetaVal,Ty)] -> Expr -> Expr
mkExprLamMeta as e = foldr (\(n,m,t) e -> mkExprLam1Meta n m t e) e as
%%]

%%[(8 codegen tycore) hs
mkExprLam1MetaLev' :: (HsName -> Ty -> ExprSeq1) -> (Expr->Expr) -> HsName -> Ty -> Expr -> Expr
mkExprLam1MetaLev' mkb mka a t e = Expr_Lam (mka $ Expr_Seq [mkb a t]) e
%%]

%%[(8 codegen tycore) hs
mkExprLam1Ki' :: (Expr->Expr) -> HsName -> Ty -> Expr -> Expr
mkExprLam1Ki' = mkExprLam1MetaLev' ExprSeq1_L2Bind
%%]

%%[(8 codegen tycore) hs
mkExprLam1Ty' :: (Expr->Expr) -> HsName -> Ty -> Expr -> Expr
mkExprLam1Ty' = mkExprLam1MetaLev' ExprSeq1_L1Bind
%%]

mkExprLam1Ty :: HsName -> Ty -> Expr -> Expr
mkExprLam1Ty = mkExprLam1Ty' id

mkExprLamTy :: [(HsName,Ty)] -> Expr -> Expr
mkExprLamTy as e = foldr (\(n,t) e -> mkExprLam1Ty n t e) e as

%%[(8 codegen tycore) hs
mkExprLam1' :: (Expr->Expr) -> HsName -> Ty -> Expr -> Expr
mkExprLam1' mka a t e = mkExprLam1Meta' mka a MetaVal_Val t e

mkExprLam1 :: HsName -> Ty -> Expr -> Expr
mkExprLam1 = mkExprLam1' id

mkExprLam :: [(HsName,Ty)] -> Expr -> Expr
mkExprLam as e = mkExprLamMeta [ (n,MetaVal_Val,t) | (n,t) <- as ] e
%%]

%%[(8 codegen tycore) hs
mkExprTuple'' :: CTag -> Ty -> AssocL (Maybe HsName) Expr -> Expr
mkExprTuple'' t ty
  = case t of
      CTagRec -> mkprod
      _       -> mkInject t ty . mkprod
  where mkprod = Expr_Node . zipWith mkseq1 positionalFldNames
        mkseq1 _ ((Just n),e) = ExprSeq1_L0LblVal n e
        mkseq1 n (_       ,e) = ExprSeq1_L0LblVal n e

mkExprTuple' :: CTag -> Ty -> [Expr] -> Expr
mkExprTuple' t ty fs = mkExprTuple'' t ty (zip (repeat Nothing) fs) -- Expr_Node {- t -} . map ExprSeq1_L0Val
%%]

%%[(8 codegen tycore) hs
mkExprLet' :: Bool -> ValBindCateg -> ValBindL -> Expr -> Expr
mkExprLet' merge c bs e
  = if null bs
    then e
    else case e of
           Expr_Let c' bs' e' | merge && c' == c
             -> mk c (bs++bs') e'
           _ -> mk c bs e
  where mk ValBindCateg_Rec bs e = Expr_Let ValBindCateg_Rec bs e
        mk c                bs e = foldr (\b e -> Expr_Let c [b] e) e bs

mkExprLet :: ValBindCateg -> ValBindL -> Expr -> Expr
mkExprLet c bs e = mkExprLet' False c bs e
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Inspection/deconstruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(exprMbVar,exprVar)
exprMbVar :: Expr -> Maybe HsName
exprMbVar (Expr_Var                           n ) = Just n
exprMbVar (Expr_Lam   (Expr_Seq []) (Expr_Var n)) = Just n
exprMbVar (Expr_Arrow (Expr_Seq []) (Expr_Var n)) = Just n
exprMbVar _                                       = Nothing

exprVar :: Expr -> HsName
exprVar = maybe hsnUnknown id . exprMbVar
%%]

%%[(8 codegen tycore) hs export(exprTupFld)
exprTupFld :: Expr -> Expr
exprTupFld (Expr_TupIns _ _ _ _ e) = e
exprTupFld e                       = e	-- default to expr itself
%%]

%%[(8 codegen tycore) hs export(exprIsEvaluated)
exprIsEvaluated :: Expr -> Bool
exprIsEvaluated (Expr_Int  _ _) = True
exprIsEvaluated (Expr_Char _ _) = True
exprIsEvaluated _               = False
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Various construction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(tcVarAsArg)
tcVarAsArg :: HsName -> Expr
tcVarAsArg n = mkExprThunk $ Expr_Var n
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Var introduction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(VarIntro(..),emptyVarIntro)
data VarIntro
  = VarIntro
      { vintroLev		:: Int		-- lexical level
      , vintroMeta		:: MetaVal	-- meta info
      }

emptyVarIntro :: VarIntro
emptyVarIntro
  = VarIntro cLevExtern MetaVal_Val
%%]

%%[(8 codegen tycore) hs export(VarIntroMp,VarIntroL,vintroLookup)
type VarIntroMp = Map.Map HsName VarIntro
type VarIntroL  = AssocL  HsName VarIntro

vintroLookup :: HsName -> VarIntroMp -> VarIntro
vintroLookup n m = Map.findWithDefault emptyVarIntro n m
%%]

%%[(8 codegen tycore) hs export(cLevModule,cLevExtern)
cLevModule, cLevExtern :: Int
cLevModule = 0
cLevExtern = 0
%%]

%%[(50 codegen tycore) hs export(cLevIntern)
cLevIntern :: Int
cLevIntern = 1
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Replacement in general
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(VarRepl(..))
data VarRepl r
  = VarRepl
      { vreplRepl		:: r		-- replacement
      , vreplMeta		:: MetaVal	-- meta info
      }
%%]

%%[(8 codegen tycore) hs export(VarReplMp)
type VarReplMp  r = Map.Map HsName (VarRepl r)
type VarReplAsc r = AssocL  HsName (VarRepl r)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Replacement with HsName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(VarReplNm,emptyVarReplNm)
type VarReplNm = VarRepl HsName

emptyVarReplNm :: VarReplNm
emptyVarReplNm = VarRepl hsnUnknown MetaVal_Val
%%]

%%[(8 codegen tycore) hs export(VarReplNmMp,VarReplNmL)
type VarReplNmMp = VarReplMp  HsName
type VarReplNmL  = VarReplAsc HsName
%%]

%%[(8 codegen tycore) hs export(vreplFromVarIntro)
vreplFromVarIntro :: VarIntro -> VarReplNm
vreplFromVarIntro i
  = emptyVarReplNm
      { vreplMeta 	= vintroMeta i
      }
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Support for transformations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(fvLev,fvsLev)
fvLev :: HsName -> VarIntroMp -> Int
fvLev n m = vintroLev $ vintroLookup n m

fvsLev :: VarIntroMp -> Int -> FvS -> Int
fvsLev lm lDflt fvs = foldr (\n l -> fvLev n lm `max` l) lDflt $ Set.toList $ fvs
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Known function arity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(ArityMp)
type ArityMp = Map.Map HsName Int
%%]

%%[(8 codegen tycore) hs export(lamMpLookupLam,lamMpLookupCaf)
lamMpLookupLam :: HsName -> ArityMp -> Maybe Int
lamMpLookupLam n m
  = case Map.lookup n m of
      j@(Just a) | a > 0 -> j
      _                  -> Nothing

lamMpLookupCaf :: HsName -> ArityMp -> Maybe Int
lamMpLookupCaf n m
  = case Map.lookup n m of
      j@(Just a) | a == 0 -> j
      _                   -> Nothing
%%]

%%[(8 codegen tycore) hs export(lamMpFilterLam,lamMpFilterCaf)
lamMpFilterLam :: ArityMp -> ArityMp
lamMpFilterLam = Map.filter (>0)

lamMpFilterCaf :: ArityMp -> ArityMp
lamMpFilterCaf = Map.filter (==0)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Name to offset (in a record)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(50 codegen tycore) hs export(HsName2OffsetMp,HsName2OffsetMpMp)
type HsNameOffset      = Int
type HsName2OffsetMp   = Map.Map HsName HsNameOffset
type HsName2OffsetMpMp = Map.Map HsName (Int,HsName2OffsetMp)
%%]

%%[(50 codegen tycore) hs export(offMpMpKeysSet)
offMpMpKeysSet :: HsName2OffsetMpMp -> HsNameS
offMpMpKeysSet m = Set.unions [ Map.keysSet m' | (_,m') <- Map.elems m ]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Subst to replace CaseAltFail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(CaseFailSubst)
type CaseFailSubst = CaseFailSubst' Expr MetaVal ValBind ValBind Ty
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Lam args merge of type and actual code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Assumption: singleton argument sequences in the type

%%[(8 codegen tycore) hs export(tcMergeArgTypeSeqAndCode')
tcMergeArgTypeSeqAndCode' :: (Ty -> TySeq) -> [TySeq1L] -> [(HsName,Expr->Expr)] -> (Expr->Expr,[TySeq])
tcMergeArgTypeSeqAndCode' mka ts as
  = merge ts as
  where merge ((ExprSeq1_L0Val  t    :ts):tss) ((argNm,mkBody):as) = (mkExprLam1'   mka argNm t . mkBody . body, mka t : args)
                                                                   where (body,args) = merge (ts:tss) as
        merge ((ExprSeq1_L0Bind v   k:ts):tss)                 as  = (mkExprLam1Ty' mka v     k          . body,         args)
                                                                   where (body,args) = merge (ts:tss) as
        merge ((ExprSeq1_L1Bind v   k:ts):tss)                 as  = (mkExprLam1Ki' mka v     k          . body,         args)
                                                                   where (body,args) = merge (ts:tss) as
        merge (_                         :tss)                 as  =                   merge     tss  as
        merge _                                                _   = (id,[])
%%]

%%[(8 codegen tycore) hs export(tcMergeArgTypeSeqAndCode)
tcMergeArgTypeSeqAndCode :: [TySeq1L] -> [(HsName,Expr->Expr)] -> Expr -> Expr
tcMergeArgTypeSeqAndCode ts as
  = fst $ tcMergeArgTypeSeqAndCode' mkTySeq ts as
%%]

%%[(8 codegen tycore) hs export(tcMergeLamTySeqAndArgNms,tcMergeLamTySeq1AndArgNms)
tcMergeLamTySeqAndArgNms' :: (Ty -> TySeq) -> (Ty -> TySeq) -> Ty -> [HsName] -> (Expr->Expr,([TySeq],TySeq))
tcMergeLamTySeqAndArgNms' mka mkr t as
  = (mk,(args,mkr res))
  where (ts,res ) = tyArrowArgsResSeq t
        (mk,args) = tcMergeArgTypeSeqAndCode' mka ts (zip as (repeat id))

tcMergeLamTySeqAndArgNms :: Ty -> [HsName] -> (Expr->Expr,([TySeq],TySeq))
tcMergeLamTySeqAndArgNms
  = tcMergeLamTySeqAndArgNms' mkTySeq id

tcMergeLamTySeq1AndArgNms :: Ty -> [HsName] -> (Expr->Expr,([TySeq],TySeq))
tcMergeLamTySeq1AndArgNms
  = tcMergeLamTySeqAndArgNms' mkTySeq1 mkTySeq1
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Environment for bindings as used by TyCore checking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore) hs export(Env,emptyEnv,envUnion,envLookup,envLookup',envSingleton,envUnions)
type Env = Map.Map HsName (Map.Map MetaLev Ty)

emptyEnv :: Env
emptyEnv = Map.empty

envUnion :: Env -> Env -> Env
envUnion = Map.unionWith Map.union

envUnions :: [Env] -> Env
envUnions [] = emptyEnv
envUnions l  = foldr1 envUnion l

envLookup' :: HsName -> MetaLev -> Env -> Maybe Ty
envLookup' n ml e
  = case Map.lookup n e of
      Just m -> Map.lookup ml m 
      _      -> Nothing

envLookup :: HsName -> MetaLev -> Env -> (Ty,ErrSq)
envLookup n ml e
  = case envLookup' n ml e of
      Just x -> (x,Seq.empty)
      _      -> (tyErr $ "envLookup:" ++ show n,Seq.singleton $ rngLift emptyRange mkErr_NamesNotIntrod ("TyCore metalevel " ++ show ml) [n])

envSingleton :: HsName -> MetaLev -> Ty -> Env 
envSingleton n ml t = Map.singleton n (Map.singleton ml t)
%%]

%%[(8 codegen tycore) hs export(envFromGam)
envFromGam :: {- G.TyKiGam -> -} (v -> T.Ty) -> MetaLev -> AssocL HsName v -> Env
envFromGam {- tkg -} getTy ml g
  = envUnions [ envSingleton n ml (tyToTyCoreBase {- fitsInForToTyCore (G.tyKiGamLookupKi tkg) -} $ getTy x) | (n,x) <- g ]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% AbstractCore instance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(8 codegen tycore)
instance AbstractCore Expr MetaVal ValBind ValBind ValBindCateg MetaBind Ty Pat PatRest FldBind Alt where
  -- expr
  acore1App           			    	= mkExprApp1
  acoreLam1Ty         				    = mkExprLam1
  acoreTagTupTy   tg t es 				= mkExprTuple' tg t es
  acoreBoundVal1CatLevMetasTy cat n l m t e
  										= mkValBind1LevMetas doMkSeq n l m t e
                                        where doMkSeq = cat /= ValBindCateg_Strict
  acoreBoundmeta 		  				= panic "TyCore.Base.acoreBoundmeta"
  acoreBound1MetaVal		  			= panic "TyCore.Base.acoreBound1MetaVal"
  acoreBoundValTy1CatLev _ _ _ t		= panic "TyCore.Base.acoreBoundValTy1CatLev"
  acoreBind1Asp n [a]					= a
  acoreBind1CatLevMetasTy bcat n mlev mb t e
  										= acoreBind1Asp n [acoreBoundVal1CatLevMetasTy bcat n mlev mb t e]
  acoreLetBase							= Expr_Let
  acoreCaseDflt	e as d					= Expr_Case e as d
  acoreVar								= Expr_Var
  acoreStringTy t i						= Expr_String i t
  acoreCharTy t i						= Expr_Char i t
  acoreIntTy t i						= Expr_Int (toInteger i) t
  acoreIntTy2							= flip Expr_Int
  acoreUidHole							= Expr_Hole
%%[[9
  acoreHoleLet							= Expr_HoleLet
%%]
  
  -- ty
  -- acoreTyInt2							= tyInt

  -- pat
  acorePatVarTy							= Pat_Var
  acorePatCon 							= Pat_Con
  acorePatIntTy t i						= Pat_Int (toInteger i) t
  acorePatIntTy2 t i					= Pat_Int i t
  acorePatCharTy t i					= Pat_Char i t
%%[[97
  acorePatBoolExpr 						= Pat_BoolExpr
%%]]
  
  -- patfld
  acorePatFldBind		  				= panic "TyCore.Base.acorePatFldBind"
  acorePatFldTy t (_,off) n 			= FldBind_Fld n t off	-- obsolete

  -- patrest
  acorePatRestEmpty  					= PatRest_Empty
  acorePatRestVar						= PatRest_Var

  -- alt
  acoreAlt                             	= Alt_Alt

  acoreTy2ty							= panic "TyCore.Base.acoreTy2ty"
  
  -- defaults
  acoreMetavalDflt      				= MetaVal_Val
%%[[9
  acoreMetavalDfltDict   				= MetaVal_Dict Nothing
%%]]
  acoreMetabindDflt      				= MetaBind_Plain
  acoreTyErr           s 				= tyErr s
  acoreTyChar 							= tyChar
  acoreTyNone            				= tyErr "TyCore.Base.acoreTyNone"
  acoreTyInt 							= tyInt
  acoreTyString o 						= tycString o

  -- bindcateg
  acoreBindcategRec 					= ValBindCateg_Rec
  acoreBindcategStrict 					= ValBindCateg_Strict
  acoreBindcategPlain					= ValBindCateg_Plain

  -- inspecting
  acoreExprMbApp		  				= panic "TyCore.Base.acoreExprMbApp"
  acoreExprMbLam		  				= panic "TyCore.Base.acoreExprMbLam"

  acoreExprMbLet (Expr_Let c b e)       = Just (c,b,e)
  acoreExprMbLet _                      = Nothing

  acoreExprMbVar           				= exprMbVar

  acoreExprMbInt (Expr_Int i t)         = Just (t,i)
  acoreExprMbInt _                      = Nothing

  acoreBindcategMbRec ValBindCateg_Rec  = Just ValBindCateg_Rec
  acoreBindcategMbRec _                 = Nothing

  acoreBindcategMbStrict ValBindCateg_Strict  = Just ValBindCateg_Strict
  acoreBindcategMbStrict _                    = Nothing

  acorePatMbCon (Pat_Con tg r fs)		= Just (tg,r,fs)
  acorePatMbCon _                 		= Nothing

  acorePatMbInt (Pat_Int i t)			= Just (t,i)
  acorePatMbInt _                 		= Nothing

  acorePatMbChar (Pat_Char c t)			= Just (t,c)
  acorePatMbChar _                 		= Nothing

  acoreUnAlt (Alt_Alt p e)				= (p,e)
  -- acoreUnPatFld (FldBind_Fld n t o)		= (t,(n,o),n)	-- TBD, not impl correct (bitrot)
  -- acoreUnBind (Bind_Bind n _)			= (n,[])		-- TBD, not impl correct (bitrot)

  -- transforming
  acoreExprUnThunk 						= mkExprUnThunk
  acoreTyUnThunk   						= tyUnThunkTySeq

  -- coercion
  acoreCoeArg 							= Expr_CoeArg
  acoreExprIsCoeArg						= (== Expr_CoeArg)
%%]

