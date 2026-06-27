!> @file runge_kutta_mod.f90
!> Classical 4th-order Runge-Kutta (RK4) time integration for the SWE.
module runge_kutta_mod
  use constants_mod,     only: dp
  use shallow_water_mod, only: SWEState, compute_rhs, &
                                allocate_state, deallocate_state
  implicit none
  private

  public :: rk4_step

contains

  !> Advance the SWE state by one time step using the classical RK4 method.
  subroutine rk4_step(state, b, dx, dy, dt, discretization_scheme)
    type(SWEState), intent(inout) :: state
    real(dp),       intent(in)    :: b(:,:)
    real(dp),       intent(in)    :: dx, dy, dt
    integer,        intent(in)    :: discretization_scheme

    type(SWEState) :: k1, k2, k3, k4, tmp

    integer :: nx, ny
    nx = size(state%h, 1)
    ny = size(state%h, 2)

    call allocate_state(tmp, nx, ny)

    ! k1 = RHS(U^n)
    call compute_rhs(k1, state, b, dx, dy, discretization_scheme)

    ! k2 = RHS(U^n + dt/2 * k1)
    tmp%h  = state%h  + 0.5_dp * dt * k1%h
    tmp%hu = state%hu + 0.5_dp * dt * k1%hu
    tmp%hv = state%hv + 0.5_dp * dt * k1%hv
    call compute_rhs(k2, tmp, b, dx, dy, discretization_scheme)

    ! k3 = RHS(U^n + dt/2 * k2)
    tmp%h  = state%h  + 0.5_dp * dt * k2%h
    tmp%hu = state%hu + 0.5_dp * dt * k2%hu
    tmp%hv = state%hv + 0.5_dp * dt * k2%hv
    call compute_rhs(k3, tmp, b, dx, dy, discretization_scheme)

    ! k4 = RHS(U^n + dt * k3)
    tmp%h  = state%h  + dt * k3%h
    tmp%hu = state%hu + dt * k3%hu
    tmp%hv = state%hv + dt * k3%hv
    call compute_rhs(k4, tmp, b, dx, dy, discretization_scheme)

    ! U^{n+1} = U^n + dt/6 * (k1 + 2*k2 + 2*k3 + k4)
    state%h  = state%h  + (dt / 6.0_dp) * (k1%h  + 2.0_dp*k2%h  + 2.0_dp*k3%h  + k4%h)
    state%hu = state%hu + (dt / 6.0_dp) * (k1%hu + 2.0_dp*k2%hu + 2.0_dp*k3%hu + k4%hu)
    state%hv = state%hv + (dt / 6.0_dp) * (k1%hv + 2.0_dp*k2%hv + 2.0_dp*k3%hv + k4%hv)

    call deallocate_state(k1)
    call deallocate_state(k2)
    call deallocate_state(k3)
    call deallocate_state(k4)
    call deallocate_state(tmp)
  end subroutine rk4_step

end module runge_kutta_mod
