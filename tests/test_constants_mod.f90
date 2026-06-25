!> @file test_constants_mod.f90
!> Unit tests for constants_mod.
module test_constants_mod
  use constants_mod, only: dp, PI, GRAVITY, EPS
  implicit none
  private
  public :: run_constants_tests

contains

  function run_constants_tests() result(all_ok)
    logical :: all_ok
    all_ok = .true.

    ! PI should agree with 4*atan(1) to machine precision
    if (abs(PI - 4.0_dp * atan(1.0_dp)) > EPS) then
      write(*,'(A)') '    FAIL: PI value incorrect'
      all_ok = .false.
    end if

    ! Gravity should be positive
    if (GRAVITY <= 0.0_dp) then
      write(*,'(A)') '    FAIL: GRAVITY must be positive'
      all_ok = .false.
    end if

    ! EPS should be small
    if (EPS >= 1.0e-6_dp) then
      write(*,'(A)') '    FAIL: EPS is too large'
      all_ok = .false.
    end if
  end function run_constants_tests

end module test_constants_mod
