!> @file test_swe_mod.f90
!> Unit tests for shallow_water_mod (state allocation, mass conservation).
module test_swe_mod
  use constants_mod,     only: dp, EPS
  use shallow_water_mod, only: SWEState, allocate_state, deallocate_state, &
                                compute_rhs
  implicit none
  private
  public :: run_swe_tests

contains

  function run_swe_tests() result(all_ok)
    logical :: all_ok
    all_ok = .true.

    if (.not. test_allocation())     all_ok = .false.
    if (.not. test_flat_rhs_zero())  all_ok = .false.
  end function run_swe_tests

  !> State arrays should be allocated with correct sizes.
  function test_allocation() result(ok)
    logical :: ok
    type(SWEState) :: s
    ok = .true.

    call allocate_state(s, 5, 7)

    if (size(s%h, 1) /= 5 .or. size(s%h, 2) /= 7) then
      write(*,'(A)') '    FAIL: h wrong size after allocate_state'
      ok = .false.
    end if

    if (any(abs(s%h)  > 0.0_dp) .or. any(abs(s%hu) > 0.0_dp) .or. any(abs(s%hv) > 0.0_dp)) then
      write(*,'(A)') '    FAIL: arrays not initialised to zero'
      ok = .false.
    end if

    call deallocate_state(s)

    if (allocated(s%h)) then
      write(*,'(A)') '    FAIL: h still allocated after deallocate_state'
      ok = .false.
    end if
  end function test_allocation

  !> For a flat, uniform, still-water initial condition the interior RHS
  !> should be identically zero (no gradients anywhere).
  function test_flat_rhs_zero() result(ok)
    logical :: ok
    type(SWEState) :: state, rhs
    real(dp), allocatable :: b(:,:)
    integer, parameter :: N = 10
    real(dp), parameter :: dx = 10.0_dp, dy = 10.0_dp
    integer :: i, j
    ok = .true.

    call allocate_state(state, N, N)
    allocate(b(N, N))

    state%h  = 1.0_dp
    state%hu = 0.0_dp
    state%hv = 0.0_dp
    b        = 0.0_dp

    call compute_rhs(rhs, state, b, dx, dy)

    do j = 2, N-1
      do i = 2, N-1
        if (abs(rhs%h(i,j))  > EPS .or. &
            abs(rhs%hu(i,j)) > EPS .or. &
            abs(rhs%hv(i,j)) > EPS) then
          write(*,'(A,I0,A,I0)') '    FAIL: non-zero RHS at i=', i, ' j=', j
          ok = .false.
        end if
      end do
    end do

    call deallocate_state(state)
    call deallocate_state(rhs)
    deallocate(b)
  end function test_flat_rhs_zero

end module test_swe_mod
