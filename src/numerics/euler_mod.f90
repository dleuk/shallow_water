!> @file euler_mod.f90
!> Forward Euler (first-order explicit) time integration for the SWE.
module euler_mod
  use constants_mod,     only: dp
  use shallow_water_mod, only: SWEState, compute_rhs, &
                                allocate_state, deallocate_state
  implicit none
  private

  public :: euler_step

contains

  !> Advance the SWE state by one time step using the forward Euler method.
  !>
  !>   U^{n+1} = U^n + dt * RHS(U^n)
  subroutine euler_step(state, b, dx, dy, dt, discretization_scheme)
    type(SWEState), intent(inout) :: state
    real(dp),       intent(in)    :: b(:,:)
    real(dp),       intent(in)    :: dx, dy, dt
    integer,        intent(in)    :: discretization_scheme

    type(SWEState) :: rhs

    call compute_rhs(rhs, state, b, dx, dy, discretization_scheme)

    state%h  = state%h  + dt * rhs%h
    state%hu = state%hu + dt * rhs%hu
    state%hv = state%hv + dt * rhs%hv

    call deallocate_state(rhs)
  end subroutine euler_step

end module euler_mod
