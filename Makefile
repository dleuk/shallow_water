# =============================================================================
# Makefile for the Shallow Water Equations Solver
#
# Requires: gfortran (GNU Fortran compiler, part of GCC)
# Usage:
#   make           – build the solver executable
#   make tests     – build and run the test suite
#   make clean     – remove build artefacts
# =============================================================================

FCFLAGS := -O2 -Wall -Wextra -Wno-unused-dummy-argument -std=f2008 -fcheck=all -g
NETCDF_FCFLAGS ?=
NETCDF_LIBS ?= -lnetcdff -lnetcdf

# OS-specific command helpers
ifeq ($(OS),Windows_NT)
EXE_EXT := .exe
MKDIR_P = if not exist "$(subst /,\,$1)" mkdir "$(subst /,\,$1)"
RM_RF = if exist "$(subst /,\,$1)" rmdir /S /Q "$(subst /,\,$1)"
FC ?= gfortran
MSYS2_BIN_DIR := $(firstword $(wildcard C:/msys64/ucrt64/bin) $(wildcard C:/msys64/mingw64/bin))
ifneq ($(MSYS2_BIN_DIR),)
export PATH := $(MSYS2_BIN_DIR);$(PATH)
endif
FC_CANDIDATES := $(strip $(wildcard C:/msys64/ucrt64/bin/gfortran.exe) $(wildcard C:/msys64/mingw64/bin/gfortran.exe))
ifneq (,$(findstring /,$(FC))$(findstring \,$(FC)))
FC_PATH := $(strip $(wildcard $(FC)))
else ifneq ($(FC_CANDIDATES),)
FC_PATH := $(firstword $(FC_CANDIDATES))
else
FC_PATH := $(strip $(shell where $(FC) 2>NUL))
endif
ifneq ($(FC_PATH),)
FC := $(firstword $(FC_PATH))
endif
else
FC ?= gfortran
EXE_EXT :=
MKDIR_P = mkdir -p "$1"
RM_RF = rm -rf "$1"
FC_PATH := $(strip $(shell command -v $(FC) 2>/dev/null))
endif

# Directories
SRCDIR  := src
TESTDIR := tests
BUILDDIR := build
OUTDIR  := output

# Module search path (gfortran writes .mod files here)
MODDIR  := $(BUILDDIR)/mod

# Compiler flags with module directory
FFLAGS  := $(FCFLAGS) $(NETCDF_FCFLAGS) -I$(MODDIR) -J$(MODDIR)

# =============================================================================
# Source files – ORDER MATTERS: modules must be compiled before dependents
# =============================================================================
SRC_UTILS := \
	$(SRCDIR)/utils/constants_mod.f90   \
	$(SRCDIR)/utils/parameters_mod.f90

SRC_GRID := \
	$(SRCDIR)/grid/grid_mod.f90          \
	$(SRCDIR)/grid/cartesian_grid_mod.f90

SRC_TERRAIN := \
	$(SRCDIR)/terrain/terrain_mod.f90

SRC_EQN := \
	$(SRCDIR)/equations/shallow_water_mod.f90 \
	$(SRCDIR)/equations/flux_mod.f90

SRC_NUM := \
	$(SRCDIR)/numerics/time_integration_mod.f90 \
	$(SRCDIR)/numerics/euler_mod.f90             \
	$(SRCDIR)/numerics/runge_kutta_mod.f90       \
	$(SRCDIR)/numerics/lax_wendroff_mod.f90

SRC_IO := \
	$(SRCDIR)/io/input_mod.f90  \
	$(SRCDIR)/io/output_mod.f90

SRC_MAIN := $(SRCDIR)/main.f90

SRCS := $(SRC_UTILS) $(SRC_GRID) $(SRC_TERRAIN) $(SRC_EQN) $(SRC_NUM) $(SRC_IO) $(SRC_MAIN)

# =============================================================================
# Object files
# =============================================================================
OBJS := $(patsubst $(SRCDIR)/%.f90,$(BUILDDIR)/%.o,$(SRCS))

# =============================================================================
# Test sources (same ordering rule)
# =============================================================================
TEST_SUPPORT := \
	$(TESTDIR)/test_constants_mod.f90 \
	$(TESTDIR)/test_grid_mod.f90      \
	$(TESTDIR)/test_swe_mod.f90

TEST_MAIN := $(TESTDIR)/test_runner.f90

TEST_SRCS := $(TEST_SUPPORT) $(TEST_MAIN)
TEST_OBJS := $(patsubst $(TESTDIR)/%.f90,$(BUILDDIR)/test/%.o,$(TEST_SRCS))

# Library objects (all solver objects except the main program)
LIB_OBJS := $(filter-out $(BUILDDIR)/main.o,$(OBJS))

# =============================================================================
# Targets
# =============================================================================

.PHONY: all tests clean dirs check_fc

all: check_fc dirs $(BUILDDIR)/shallow_water$(EXE_EXT)
	@echo "Build complete: $(BUILDDIR)/shallow_water$(EXE_EXT)"

check_fc:
ifeq ($(FC_PATH),)
	$(error [make] Error: compiler '$(FC)' not found in PATH. Install gfortran and ensure it is available in your shell.)
endif

dirs:
	@$(call MKDIR_P,$(MODDIR))
	@$(call MKDIR_P,$(OUTDIR))
	@$(call MKDIR_P,$(BUILDDIR)/utils)
	@$(call MKDIR_P,$(BUILDDIR)/grid)
	@$(call MKDIR_P,$(BUILDDIR)/terrain)
	@$(call MKDIR_P,$(BUILDDIR)/equations)
	@$(call MKDIR_P,$(BUILDDIR)/numerics)
	@$(call MKDIR_P,$(BUILDDIR)/io)
	@$(call MKDIR_P,$(BUILDDIR)/test)

# Link solver executable
$(BUILDDIR)/shallow_water$(EXE_EXT): $(OBJS)
	$(FC) $(FCFLAGS) -o $@ $^ $(NETCDF_LIBS)

# Compile solver source files
$(BUILDDIR)/%.o: $(SRCDIR)/%.f90
	$(FC) $(FFLAGS) -c $< -o $@

# Build and run tests
tests: check_fc dirs $(BUILDDIR)/test/test_runner$(EXE_EXT)
	@echo "--- Running tests ---"
	@$(BUILDDIR)/test/test_runner$(EXE_EXT)
	@echo "--- Tests done ------"

# Link test executable (link against lib objects + test objects)
$(BUILDDIR)/test/test_runner$(EXE_EXT): $(LIB_OBJS) $(TEST_OBJS)
	$(FC) $(FCFLAGS) -o $@ $^ $(NETCDF_LIBS)

# Compile test source files
$(BUILDDIR)/test/%.o: $(TESTDIR)/%.f90
	$(FC) $(FFLAGS) -c $< -o $@

# =============================================================================
# Clean
# =============================================================================
clean:
	@$(call RM_RF,$(BUILDDIR))
	@echo "Clean complete."
