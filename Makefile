# =============================================================================
# Makefile for the Shallow Water Equations Solver
#
# Requires: gfortran (GNU Fortran compiler, part of GCC)
# Usage:
#   make           – build the solver executable
#   make tests     – build and run the test suite
#   make clean     – remove build artefacts
# =============================================================================

FC      := gfortran
FCFLAGS := -O2 -Wall -Wextra -Wno-unused-dummy-argument -std=f2008 -fcheck=all -g

# Directories
SRCDIR  := src
TESTDIR := tests
BUILDDIR := build
OUTDIR  := output

# Module search path (gfortran writes .mod files here)
MODDIR  := $(BUILDDIR)/mod

# Compiler flags with module directory
FFLAGS  := $(FCFLAGS) -I$(MODDIR) -J$(MODDIR)

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
.PHONY: all tests clean dirs

all: dirs $(BUILDDIR)/shallow_water
	@echo "Build complete: $(BUILDDIR)/shallow_water"

dirs:
	@mkdir -p $(MODDIR) $(OUTDIR)
	@mkdir -p $(BUILDDIR)/utils $(BUILDDIR)/grid $(BUILDDIR)/terrain \
	          $(BUILDDIR)/equations $(BUILDDIR)/numerics $(BUILDDIR)/io
	@mkdir -p $(BUILDDIR)/test

# Link solver executable
$(BUILDDIR)/shallow_water: $(OBJS)
	$(FC) $(FCFLAGS) -o $@ $^

# Compile solver source files
$(BUILDDIR)/%.o: $(SRCDIR)/%.f90
	$(FC) $(FFLAGS) -c $< -o $@

# Build and run tests
tests: dirs $(BUILDDIR)/test/test_runner
	@echo "--- Running tests ---"
	@$(BUILDDIR)/test/test_runner
	@echo "--- Tests done ------"

# Link test executable (link against lib objects + test objects)
$(BUILDDIR)/test/test_runner: $(LIB_OBJS) $(TEST_OBJS)
	$(FC) $(FCFLAGS) -o $@ $^

# Compile test source files
$(BUILDDIR)/test/%.o: $(TESTDIR)/%.f90
	$(FC) $(FFLAGS) -c $< -o $@

# =============================================================================
# Clean
# =============================================================================
clean:
	rm -rf $(BUILDDIR)
	@echo "Clean complete."
