###########################################################################################
# Although named 'variant.mk' this file also holds lots of configuration, should be renamed someday
###########################################################################################

###########################################################################################
# aspects, EHC_ASPECTS to be configured at top level, for now here
###########################################################################################

ifeq ($(EHC_VARIANT),$(EHC_UHC_CABAL_VARIANT))
EHC_ASPECTS_MINIMAL						:= base hmtyinfer codegen core corein coreout corebackend corerun
else
EHC_ASPECTS_MINIMAL						:= base hmtyinfer codegen core grin corein coreout machdep
endif
EHC_ASPECTS								:= $(strip $(sort $(if $(ASPECTS),$(ASPECTS) \
											,$(EHC_ASPECTS_MINIMAL) \
											 $(if $(EHC_CFG_USE_RULER),,noHmTyRuler) \
											 $(if $(ENABLE_JAVA),java jazy,) \
											 $(if $(ENABLE_LLVM),llvm,) \
											 $(if $(ENABLE_CMM),cmm,) \
											 $(if $(ENABLE_WHOLEPROGC),wholeprogC,) \
											 $(if $(ENABLE_WHOLEPROGANAL),wholeprogAnal,) \
											 $(if $(ENABLE_JS),javascript,) \
											 $(if $(ENABLE_CLR),clr,) \
											 $(if $(ENABLE_TYCORE),tycore,) \
											 $(if $(ENABLE_CORESYSF),coresysf,) \
											 $(if $(ENABLE_CORE_ASINPOUTP),corebackend corerun,) \
											 $(if $(ENABLE_TAUPHI),tauphi,) \
											 $(if $(ENABLE_CONSTRAINT),constraint,) \
											)))
EHC_ASPECTS_SUFFIX						:= $(if $(ASPECTS),-$(subst $(space),-,$(ASPECTS)),)
EHC_ASPECTS_SUFFIX2						:= $(subst -,,$(EHC_ASPECTS_SUFFIX))

###########################################################################################
# variant, EHC_VARIANT to be configured at top level, by a recursive make invocation
###########################################################################################

EHC_VARIANT								:= X
EHC_VARIANT_ASPECTS						:= $(EHC_VARIANT)$(EHC_ASPECTS_SUFFIX)
EHC_VARIANT_ASPECTS_PREFIX				:= $(EHC_VARIANT_ASPECTS)/
EHC_BLD_VARIANT_ASPECTS_PREFIX			:= $(BLD_PREFIX)$(EHC_VARIANT_ASPECTS_PREFIX)
EHC_BARE_VARIANT_ASPECTS_PREFIX			:= $(BARE_PREFIX)$(EHC_VARIANT_ASPECTS_PREFIX)
EHC_BLD_LIBEHC_VARIANT_PREFIX			:= $(EHC_BLD_VARIANT_ASPECTS_PREFIX)lib-ehc/
EHC_BLD_BIN_VARIANT_PREFIX				:= $(EHC_BLD_VARIANT_ASPECTS_PREFIX)bin/
EHC_BLD_GEN_VARIANT_PREFIX				:= $(EHC_BLD_VARIANT_ASPECTS_PREFIX)gen/
EHC_BIN_PREFIX							:= $(BIN_PREFIX)
EHC_LIB_PREFIX							:= $(LIB_PREFIX)
EHC_BIN_VARIANT_ASPECTS_PREFIX			:= $(EHC_BIN_PREFIX)$(EHC_VARIANT_ASPECTS_PREFIX)
EHC_LIB_VARIANT_ASPECTS_PREFIX			:= $(EHC_LIB_PREFIX)$(EHC_VARIANT_ASPECTS_PREFIX)
EHC_VARIANT_RULER_SEL					:= ().().()

###########################################################################################
# name of executable
###########################################################################################

FUN_EHC_INSTALL_VARIANT_ASPECTS_EXEC		= $(call FUN_INSTALL_VARIANT_BIN_PREFIX,$(1))$(EHC_EXEC_NAME)$(EXEC_SUFFIX)
FUN_EHC_INSTALLABS_VARIANT_ASPECTS_EXEC		= $(call FUN_INSTALLABS_VARIANT_BIN_PREFIX,$(1))$(EHC_EXEC_NAME)$(EXEC_SUFFIX)

#EHC_INSTALL_VARIANT_ASPECTS_EXEC			:= $(EHC_BIN_VARIANT_ASPECTS_PREFIX)$(EHC_EXEC_NAME)$(EXEC_SUFFIX)
EHC_ALL_PUB_EXECS							:= $(patsubst %,$(call FUN_EHC_INSTALL_VARIANT_ASPECTS_EXEC,%),$(EHC_PUB_VARIANTS))
EHC_ALL_EXECS								:= $(patsubst %,$(call FUN_EHC_INSTALL_VARIANT_ASPECTS_EXEC,%),$(EHC_VARIANTS))
EHC_INSTALL_VARIANT_ASPECTS_EXEC			:= $(call FUN_EHC_INSTALL_VARIANT_ASPECTS_EXEC,$(EHC_VARIANT_ASPECTS))
EHC_INSTALLABS_VARIANT_ASPECTS_EXEC			:= $(call FUN_EHC_INSTALLABS_VARIANT_ASPECTS_EXEC,$(EHC_VARIANT_ASPECTS))

###########################################################################################
# code generation targets, leading to target dependend locations
###########################################################################################

EHC_VARIANT_TARGETS						:= $(shell if test -x $(EHC_INSTALL_VARIANT_ASPECTS_EXEC); then $(EHC_INSTALL_VARIANT_ASPECTS_EXEC) --meta-targets; else echo bc; fi)
EHC_VARIANT_TARGET						:= $(shell if test -x $(EHC_INSTALL_VARIANT_ASPECTS_EXEC); then $(EHC_INSTALL_VARIANT_ASPECTS_EXEC) --meta-target-default; else echo bc; fi)
EHC_VARIANT_TARGET_PREFIX				:= $(EHC_VARIANT_TARGET)/

# target info as passed as cpp flag
EHC_VARIANT_TARGET_UHC_DEFINE1			:= __UHC_TARGET_$(shell echo $(EHC_VARIANT_TARGET) | tr "[a-z]" "[A-Z]")__
EHC_VARIANT_TARGET_UHC_DEFINE2			:= __UHC_TARGET__=$(EHC_VARIANT_TARGET)

# target + variant based options passed around
RTS_GCC_CC_OPTS_VARIANT_TARGET			:= -D$(EHC_VARIANT_TARGET_UHC_DEFINE1) -D$(EHC_VARIANT_TARGET_UHC_DEFINE2)

###########################################################################################
# lib/cabal/module config
###########################################################################################

# for enduser installable variants the module qualifiers are different
LIB_EHC_BASE							:= EH
ifeq ($(EHC_VARIANT),$(EHC_UHC_INSTALL_VARIANT))
# uhc compiler
LIB_EHC_QUAL							:= UHC.Compiler
else
ifeq ($(EHC_VARIANT),$(EHC_UHC_CABAL_VARIANT))
# uhc cabal/package installation
LIB_EHC_QUAL							:= UHC.Light.Compiler
else
# default
LIB_EHC_QUAL							:= $(subst _,x,$(LIB_EHC_BASE)$(EHC_VARIANT))$(EHC_ASPECTS_SUFFIX2)
endif
endif

LIB_EHC_QUAL_PREFIX						:= $(LIB_EHC_QUAL).
LIB_EHC_HS_PREFIX						:= $(subst .,$(PATH_SEP),$(LIB_EHC_QUAL_PREFIX))
LIB_EHC_PKG_NAMEBASE					:= $(GHC_PKG_NAME_PREFIX)$(subst .,-,$(LIB_EHC_QUAL))
LIB_EHC_PKG_NAME						:= $(LIB_EHC_PKG_NAMEBASE)
LIB_EHC_INS_FLAG						:= $(INSTALLFORBLDABS_FLAG_PREFIX)$(LIB_EHC_PKG_NAME)

EHC_BASE								:= $(LIB_EHC_BASE)C

###########################################################################################
# config depending on EHC_ASPECTS, EHC_VARIANT: Booleans telling whether some aspect is used
###########################################################################################

# backend uses UNIX/C facilities (or emulation thereof)
# this should coincide with targetIsOnUnixAndOrC in src/ehc/Base/Target
EHC_CFG_USE_UNIX_AND_C					:= $(filter $(EHC_VARIANT_TARGET),C bc jazy)

# grin is used?
EHC_CFG_USE_GRIN						:= $(filter grin,$(EHC_ASPECTS))

# variant does codegeneration?
EHC_CFG_USE_CODEGEN						:= $(filter $(EHC_VARIANT),$(EHC_CODE_VARIANTS))

# variant uses prelude
EHC_CFG_USE_PRELUDE						:= $(filter $(EHC_VARIANT),$(EHC_PREL_VARIANTS) $(EHC_OTHER_PREL_VARIANTS))

#
EHC_CFG_IS_A_VARIANT					:= $(filter $(EHC_VARIANT),$(EHC_VARIANTS))

###########################################################################################
# ehc runtime config
###########################################################################################

# assumed packages, useful only for prelude variants; order matters.
# EHC_PACKAGES_ALL						:= uhcbase base array filepath old-locale old-time unix directory random
EHC_PACKAGES_ASSUMED					:= uhcbase base array \
											$(if $(EHC_CFG_USE_UNIX_AND_C),filepath old-locale old-time unix directory random,)

###########################################################################################
# installation locations for ehc building time
###########################################################################################

INSTALLFORBLD_VARIANT_ASPECTS_PREFIX	:= $(INSTALLFORBLD_PREFIX)$(EHC_VARIANT_ASPECTS_PREFIX)
INSTALLFORBLDABS_VARIANT_ASPECTS_PREFIX	:= $(INSTALLFORBLDABS_PREFIX)$(EHC_VARIANT_ASPECTS_PREFIX)
INSTALLFORBLD_EHC_LIB_PREFIX			:= $(INSTALLFORBLD_PREFIX)lib/$(LIB_EHC_PKG_NAME)-$(EH_VERSION_SHORT)/
INSTALLFORBLDABS_EHC_LIB_PREFIX			:= $(INSTALLFORBLDABS2_PREFIX)lib/$(LIB_EHC_PKG_NAME)-$(EH_VERSION_SHORT)/
INSTALLFORBLD_EHC_LIB_AG_PREFIX			:= $(INSTALLFORBLD_EHC_LIB_PREFIX)ag/
INSTALLFORBLDABS_EHC_LIB_AG_PREFIX		:= $(INSTALLFORBLDABS2_EHC_LIB_PREFIX)ag/

###########################################################################################
# installation locations for ehc running time
###########################################################################################

# expanded to current variant
INSTALL_VARIANT_PREFIX					:= $(call FUN_INSTALL_VARIANT_PREFIX,$(EHC_VARIANT))
INSTALLABS_VARIANT_PREFIX				:= $(call FUN_INSTALLABS_VARIANT_PREFIX,$(EHC_VARIANT))
INSTALL_VARIANT_LIB_PREFIX				:= $(call FUN_INSTALL_VARIANT_LIB_PREFIX,$(EHC_VARIANT))
INSTALLABS_VARIANT_LIB_PREFIX			:= $(call FUN_INSTALLABS_VARIANT_LIB_PREFIX,$(EHC_VARIANT))
#INSTALL_VARIANT_LIB_TARGET_PREFIX		:= $(call FUN_INSTALL_VARIANT_LIB_TARGET_PREFIX,$(EHC_VARIANT),$(EHC_VARIANT_TARGET))
#INSTALL_VARIANT_PKGLIB_TARGET_PREFIX	:= $(call FUN_INSTALL_VARIANT_PKGLIB_TARGET_PREFIX,$(EHC_VARIANT),$(EHC_VARIANT_TARGET))

###########################################################################################
# installation locations for ehc after building time, for ehc (compiler) library access,
# in particular AG files of AG data types, to be included when writing AG semantics.
# The corresponding HS file for the data type is already in the library/package.
###########################################################################################

INSTALL_VARIANT_LIB_AG_PREFIX			:= $(INSTALL_VARIANT_LIB_PREFIX)ag/
INSTALLABS_VARIANT_LIB_AG_PREFIX		:= $(INSTALLABS_VARIANT_LIB_PREFIX)ag/

###########################################################################################
# further derived info
###########################################################################################

EHC_BLD_LIB_HS_VARIANT_PREFIX			:= $(EHC_BLD_LIBEHC_VARIANT_PREFIX)$(LIB_EHC_HS_PREFIX)
SRC_EHC_LIB_PREFIX						:= $(SRC_EHC_PREFIX)$(LIB_EHC_BASE)

###########################################################################################
# shuffle commandline config for building the building time ehc library
###########################################################################################

LIB_EHC_SHUFFLE_DEFS					:= --def=EH:$(LIB_EHC_QUAL_PREFIX) --def=VARIANT:$(EHC_VARIANT) --def="ASPECTS:$(EHC_ASPECTS)"

