!> @file constants_mod.f90
!> Physical and mathematical constants used throughout the solver.
module constants_mod
  implicit none
  private

  !> Double-precision kind parameter
  integer, parameter, public :: dp = kind(1.0d0)

  !> Pi
  real(dp), parameter, public :: PI = 3.14159265358979323846_dp

  !> Gravitational acceleration (m/s^2)
  real(dp), parameter, public :: GRAVITY = 9.81_dp

  !> A small tolerance for floating-point comparisons
  real(dp), parameter, public :: EPS = 1.0e-10_dp

end module constants_mod
