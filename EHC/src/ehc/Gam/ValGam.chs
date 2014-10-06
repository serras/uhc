%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gam specialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1 module {%{EH}Gam.ValGam}
%%]

%%[1 import(UHC.Util.Pretty,UHC.Util.Utils)
%%]

%%[1 hs import ({%{EH}Base.Common},{%{EH}Base.TermLike},{%{EH}Base.HsName.Builtin})
%%]
%%[(1 hmtyast || hmtyinfer) hs import ({%{EH}Ty},{%{EH}Ty.Pretty})
%%]
%%[1 hs import ({%{EH}Gam})
%%]
%%[1 hs import({%{EH}Error}) 
%%]

%%[(2 hmtyinfer || hmtyast) import(qualified Data.Set as Set)
%%]

%%[(2 hmtyinfer || hmtyast) import({%{EH}VarMp},{%{EH}Substitutable})
%%]

%%[(3 hmtyinfer || hmtyast) import({%{EH}Ty.Trf.Quantify})
%%]

%%[(50 hmtyinfer || hmtyast) import(Control.Monad, UHC.Util.Binary, UHC.Util.Serialize)
%%]

%%[9999 import({%{EH}Base.ForceEval})
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% "Type of value" gam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[1.ValGam.Base export(ValGamInfo(..),ValGam)
data ValGamInfo
  = ValGamInfo
%%[[(1 hmtyinfer || hmtyast)
      { vgiTy :: Ty }		-- strictness has negative mem usage effect. Why??
%%]]
      deriving Show

type ValGam = Gam HsName ValGamInfo
%%]

%%[(50 hmtyinfer || hmtyast)
deriving instance Typeable ValGamInfo
deriving instance Data ValGamInfo
%%]

%%[(8 hmtyinfer || hmtyast) export(vgiGetSet)
vgiGetSet = (vgiTy,(\x i -> i {vgiTy = x}))
%%]

%%[1.valGamLookup export(valGamLookup)
valGamLookup :: HsName -> ValGam -> Maybe ValGamInfo
valGamLookup = gamLookup
%%]

%%[(1 hmtyinfer || hmtyast).valGamLookupTy export(valGamLookupTy)
valGamLookupTy :: HsName -> ValGam -> (Ty,ErrL)
valGamLookupTy n g
  =  case valGamLookup n g of
       Nothing    ->  (Ty_Any,[rngLift emptyRange mkErr_NamesNotIntrod "value" [n]])
       Just vgi   ->  (vgiTy vgi,[])
%%]

%%[(8 hmtyinfer || hmtyast) export(valGamLookupTyDefault)
-- | lookup Ty in ValGam, defaulting to Ty_Any
valGamLookupTyDefault :: HsName -> ValGam -> Ty
valGamLookupTyDefault n g = maybe (Ty_Dbg $ "valGamLookupTyDefault: " ++ show n) vgiTy $ valGamLookup n g
%%]

%%[4.valGamLookup -1.valGamLookup export(valGamLookup)
valGamLookup :: HsName -> ValGam -> Maybe ValGamInfo
valGamLookup nm g
  =  case gamLookup nm g of
       Nothing
%%[[(4 hmtyinfer || hmtyast)
         |  hsnIsProd nm
                 -> let pr = mkPr nm in mkRes (tyProdArgs pr `appArr` pr)
         |  hsnIsUn nm && hsnIsProd (hsnUnUn nm)
                 -> let pr = mkPr (hsnUnUn nm) in mkRes ([pr] `appArr` pr)
         where  mkPr nm  = mkTyFreshProd (hsnProdArity nm)
                mkRes t  = Just (ValGamInfo (tyQuantifyClosed t))
%%][4
         |  hsnIsProd nm
                 -> Just ValGamInfo
         |  hsnIsUn nm && hsnIsProd (hsnUnUn nm)
                 -> Just ValGamInfo
%%]]
       Just vgi  -> Just vgi
       _         -> Nothing
%%]

%%[(3 hmtyinfer || hmtyast).valGamMapTy export(valGamMapTy)
valGamMapTy :: (Ty -> Ty) -> ValGam -> ValGam
valGamMapTy f = gamMapElts (\vgi -> vgi {vgiTy = f (vgiTy vgi)})
%%]

%%[(8 hmtyinfer || hmtyast).valGamDoWithVarMp export(valGamDoWithVarMp)
-- Do something with each ty in a ValGam.
valGamDoWithVarMp :: (HsName -> (Ty,VarMp) -> VarMp -> thr -> (Ty,VarMp,thr)) -> VarMp -> thr -> ValGam -> (ValGam,VarMp,thr)
valGamDoWithVarMp = gamDoTyWithVarMp vgiGetSet
%%]

%%[66_4.valGamCloseExists
valGamCloseExists :: ValGam -> ValGam
valGamCloseExists = valGamMapTy (\t -> tyQuantify (not . tvIsEx (tyFtvMp t)) t)
%%]

%%[(7 hmtyinfer || hmtyast) export(valGamTyOfDataCon)
valGamTyOfDataCon :: HsName -> ValGam -> (Ty,Ty,ErrL)
valGamTyOfDataCon conNm g
  = (t,rt,e)
  where (t,e) = valGamLookupTy conNm g
        (_,rt) = appUnArr t
%%]

%%[(7 hmtyinfer || hmtyast) export(valGamTyOfDataFld)
valGamTyOfDataFld :: HsName -> ValGam -> (Ty,Ty,ErrL)
valGamTyOfDataFld fldNm g
  | null e    = (t,rt,e)
  | otherwise = (t,Ty_Any,e)
  where (t,e) = valGamLookupTy fldNm g
        ((rt:_),_) = appUnArr t
%%]

%%[(6 hmtyinfer || hmtyast)
%%]
-- restrict the kinds of tvars bound to value identifiers to kind *
valGamRestrictKiVarMp :: ValGam -> VarMp
valGamRestrictKiVarMp g = varmpIncMetaLev $ assocTyLToVarMp [ (v,kiStar) | vgi <- gamElts g, v <- maybeToList $ tyMbVar $ vgiTy vgi ]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Instances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[(2 hmtyinfer || hmtyast).Substitutable.inst.ValGamInfo
instance VarUpdatable ValGamInfo VarMp where
  s `varUpd`  vgi         =   vgi { vgiTy = s `varUpd` vgiTy vgi }
%%[[4
  s `varUpdCyc` vgi         =   substLift vgiTy (\i x -> i {vgiTy = x}) varUpdCyc s vgi
%%]]

instance VarExtractable ValGamInfo TyVarId where
  varFreeSet vgi         =   varFreeSet (vgiTy vgi)
%%]

%%[(1 hmtyinfer || hmtyast).PP.ValGamInfo
instance PP ValGamInfo where
  pp vgi = ppTy (vgiTy vgi)
%%]

%%[(9999 hmtyinfer || hmtyast)
instance ForceEval ValGamInfo where
  forceEval x@(ValGamInfo t) | forceEval t `seq` True = x
%%[[102
  fevCount (ValGamInfo x) = cm1 "ValGamInfo" `cmUnion` fevCount x
%%]]
%%]

%%[(50 hmtyinfer || hmtyast)
instance Serialize ValGamInfo where
  sput (ValGamInfo a) = sput a
  sget = liftM ValGamInfo sget
%%]

