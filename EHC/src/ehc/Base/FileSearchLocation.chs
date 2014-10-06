%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% UHC search locations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[doesWhat doclatex
Encoding of searchable locations for files, in particular HS and derived files.
In principle such files reside in directories or packages.
%%]

%%[8 module {%{EH}Base.FileSearchLocation}
%%]

%%[8 import({%{EH}Base.Common})
%%]

-- parsing
%%[99 import(UU.Parsing, UHC.Util.ParseUtils)
%%]
-- scanning
%%[99 import(UHC.Util.ScanUtils, {%{EH}Base.HsName})
%%]


-- general imports 
%%[8 import(qualified Data.Set as Set, qualified Data.Map as Map, Data.Maybe, Data.Version, Data.List)
%%]

%%[99 import({%{EH}Base.Target}, qualified {%{EH}ConfigInstall} as Cfg)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Kind of location
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FileLocKind indicates where something can be found. After found, a FileLocKind_PkgDb will be replaced by a FileLocKind_Pkg.

%%[99 export(FileLocKind(..))
data FileLocKind
  = FileLocKind_Dir									-- plain directory
  | FileLocKind_Pkg	PkgKey							-- specific package
  					String							-- with the dir inside package it was found
  | FileLocKind_PkgDb								-- yet unknown package in the package database
  deriving Eq

instance Show FileLocKind where
  show  FileLocKind_Dir		    = "directory"
  show (FileLocKind_Pkg p d)	= "package: " ++ showPkgKey p ++ "(in: " ++ d ++ ")"
  show  FileLocKind_PkgDb    	= "package database"
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% File location, used for search locations as well
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8.FileLoc export(FileLoc,filelocDir,emptyFileLoc)
type FileLoc = String

emptyFileLoc :: FileLoc
emptyFileLoc = ""

filelocDir :: FileLoc -> String
filelocDir = id
%%]

%%[99 -8.FileLoc export(FileLoc(..),emptyFileLoc,fileLocPkgDb)
data FileLoc
  = FileLoc
      {	filelocKind		:: FileLocKind
      , filelocDir		:: String
      }
  deriving Eq

instance Show FileLoc where
  show (FileLoc k d) = d ++ " (" ++ show k ++ ")"

emptyFileLoc :: FileLoc
emptyFileLoc = FileLoc FileLocKind_Dir ""

fileLocPkgDb :: FileLoc
fileLocPkgDb = FileLoc FileLocKind_PkgDb ""
%%]

%%[8 export(mkDirFileLoc)
mkDirFileLoc
%%[[8
  = id
%%][99
  = FileLoc FileLocKind_Dir
%%]]
%%]

%%[99 export(mkPkgFileLoc)
mkPkgFileLoc :: PkgKey -> String -> FileLoc
mkPkgFileLoc p d = FileLoc (FileLocKind_Pkg p d) d
%%]

%%[99 export(filelocIsPkg)
filelocIsPkg :: FileLoc -> Bool
filelocIsPkg (FileLoc (FileLocKind_Pkg _ _) _) = True
filelocIsPkg (FileLoc  FileLocKind_PkgDb    _) = True
filelocIsPkg _                                 = False
%%]

%%[8 export(StringPath,FileLocPath)
type StringPath  = [String]
type FileLocPath = [FileLoc]
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% File search location
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(FileSearchLoc)
type FileSearchLoc = FileLoc
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Package key
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(PkgKey,PkgKey1,PkgKey2)
type PkgKey1 = PkgName
type PkgKey2 = Maybe Version
type PkgKey  = (PkgKey1,PkgKey2)

instance HSNM PkgKey where
  mkHNm (n,Just v) =   mkHNmBase (n ++ "-" ++ (concat $ intersperse "." $ map show $ versionBranch v))
  mkHNm (n,_     ) =   mkHNm      n
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Showing the package name as it is used
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(showPkgKey)
showPkgKey :: PkgKey -> String
showPkgKey = show . mkHNm
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Package search filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(PackageSearchFilter(..))
-- | Description of hiding/exposing pkgs, determining the used packages for looking up modules.
data PackageSearchFilter
  -- Note: the below order is important, it is used for sorting just before having its effect on searchable packages.
  -- The current order means that in its filtering hiding is done first, thereby starting out with all available pkgs, then hide (all), then expose selectively
  = PackageSearchFilter_HideAll
  | PackageSearchFilter_HidePkg			[PkgKey]
  | PackageSearchFilter_ExposePkg		[PkgKey]
  deriving (Show, Eq, Ord)
%%]

%%[99 export(pkgSearchFilter)
pkgSearchFilter :: (x -> Maybe PkgKey) -> ([PkgKey] -> PackageSearchFilter) -> [x] -> [PackageSearchFilter]
pkgSearchFilter mkKey mk ss
  = if null ps then [] else [mk ps]
  where ps = catMaybes $ map mkKey ss
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Package database
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(PackageCfgKeyVals,PackageInfo(..),PackageMp,Module2PackageMp,PackageDatabase(..),emptyPackageMp,emptyPackageDatabase)
type PackageCfgKeyVals = Map.Map String String

-- | Per package info
data PackageInfo
  = PackageInfo
      { pkginfoLoc					:: !FileLoc						-- ^ directory location
      , pkginfoOrder				:: !Int							-- ^ for multiple packages the relative order
      -- , pkginfoKeyVals				:: PackageCfgKeyVals			-- key/value pairs of pkg config info
      , pkginfoExposedModules		:: !HsNameS						-- ^ exposed modules
      , pkginfoBuildDepends			:: !(Set.Set PkgKey)			-- ^ pkgs dependend on
      , pkginfoIsExposed		    :: !Bool						-- ^ pkg is exposed?
      }
      deriving Show

-- | content of a package (keys are name, then version)
type PackageMp = Map.Map PkgKey1 (Map.Map PkgKey2 [PackageInfo])

emptyPackageMp :: PackageMp
emptyPackageMp = Map.empty

-- | reverse map from module name to package key
type Module2PackageMp = Map.Map HsName [PkgKey]

-- | A package database contains an actual package map, plus a function
-- that maps modules to associated package maps. The latter is computed
-- by "freezing" the package database using "pkgDbFreeze".
data PackageDatabase
  = PackageDatabase
      { pkgDbPkgMp		:: PackageMp
      , pkgDbMod2PkgMp	:: Module2PackageMp
      }
      deriving Show

emptyPackageDatabase :: PackageDatabase
emptyPackageDatabase = PackageDatabase emptyPackageMp Map.empty
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Constructing paths for specific files in package databases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[99 export(mkInternalPkgFileBase)

mkInternalPkgFileBase :: PkgKey -> String {- compiler name/version -} -> Target -> TargetFlavor -> FilePath
mkInternalPkgFileBase pkgKey compversion tgt tgtv =
  Cfg.mkInternalPkgFileBase (showPkgKey pkgKey) compversion (show tgt) (show tgtv)

%%]
