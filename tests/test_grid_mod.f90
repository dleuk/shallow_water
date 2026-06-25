!> @file test_grid_mod.f90
!> Unit tests for cartesian_grid_mod.
module test_grid_mod
  use constants_mod,      only: dp, EPS
  use parameters_mod,     only: SimParams, default_params
  use cartesian_grid_mod, only: CartesianGrid, build_cartesian_grid, &
                                 destroy_cartesian_grid
  implicit none
  private
  public :: run_grid_tests

contains

  function run_grid_tests() result(all_ok)
    logical :: all_ok
    type(SimParams)     :: p
    type(CartesianGrid) :: g
    all_ok = .true.

    p = default_params()
    p%nx = 10;  p%ny = 20
    p%x_min = 0.0_dp;  p%x_max = 100.0_dp
    p%y_min = 0.0_dp;  p%y_max = 200.0_dp

    call build_cartesian_grid(g, p)

    ! Check dx
    if (abs(g%dx - 10.0_dp) > EPS) then
      write(*,'(A,F10.5)') '    FAIL: dx should be 10, got ', g%dx
      all_ok = .false.
    end if

    ! Check dy
    if (abs(g%dy - 10.0_dp) > EPS) then
      write(*,'(A,F10.5)') '    FAIL: dy should be 10, got ', g%dy
      all_ok = .false.
    end if

    ! First cell-centre at x_min + dx/2
    if (abs(g%x(1) - 5.0_dp) > EPS) then
      write(*,'(A,F10.5)') '    FAIL: x(1) should be 5, got ', g%x(1)
      all_ok = .false.
    end if

    ! Last cell-centre at x_max - dx/2
    if (abs(g%x(p%nx) - 95.0_dp) > EPS) then
      write(*,'(A,F10.5)') '    FAIL: x(nx) should be 95, got ', g%x(p%nx)
      all_ok = .false.
    end if

    call destroy_cartesian_grid(g)
  end function run_grid_tests

end module test_grid_mod
