!> @file shallow_water_mod.f90
!> Core module defining the SWE state vector and the right-hand-side (RHS)
!> of the 2-D shallow water equations.
!>
!> The 2-D SWE in conservation form are:
!>
!>   ∂h/∂t   + ∂(hu)/∂x + ∂(hv)/∂y  = 0
!>   ∂(hu)/∂t + ∂(hu²+g h²/2)/∂x + ∂(huv)/∂y = -g h ∂b/∂x
!>   ∂(hv)/∂t + ∂(huv)/∂x + ∂(hv²+g h²/2)/∂y = -g h ∂b/∂y
!>
!> where h = water depth, u = x-velocity, v = y-velocity, b = bed elevation,
!> g = gravitational acceleration.
module shallow_water_mod
  use constants_mod, only: dp, GRAVITY
  implicit none
  private

  !> SWE state on a 2-D grid.
  type, public :: SWEState
    real(dp), allocatable :: h(:,:)    !< Water depth         (m)
    real(dp), allocatable :: hu(:,:)   !< x-momentum (h*u)    (m²/s)
    real(dp), allocatable :: hv(:,:)   !< y-momentum (h*v)    (m²/s)
  end type SWEState

  public :: allocate_state
  public :: deallocate_state
  public :: compute_rhs

contains

  !> Allocate state arrays for an nx × ny grid.
  subroutine allocate_state(state, nx, ny)
    type(SWEState), intent(out) :: state
    integer,        intent(in)  :: nx, ny
    allocate(state%h (nx, ny))
    allocate(state%hu(nx, ny))
    allocate(state%hv(nx, ny))
    state%h  = 0.0_dp
    state%hu = 0.0_dp
    state%hv = 0.0_dp
  end subroutine allocate_state

  !> Deallocate state arrays.
  subroutine deallocate_state(state)
    type(SWEState), intent(inout) :: state
    if (allocated(state%h))  deallocate(state%h)
    if (allocated(state%hu)) deallocate(state%hu)
    if (allocated(state%hv)) deallocate(state%hv)
  end subroutine deallocate_state

  !> Compute the RHS of the SWE using simple central differences.
  !> This is a placeholder; production code should use a proper
  !> Riemann-solver-based flux (see flux_mod.f90).
  subroutine compute_rhs(rhs, state, b, dx, dy)
    type(SWEState), intent(out) :: rhs      !< Tendencies d/dt(h, hu, hv)
    type(SWEState), intent(in)  :: state    !< Current state
    real(dp),       intent(in)  :: b(:,:)   !< Bed elevation (m)
    real(dp),       intent(in)  :: dx, dy   !< Grid spacing  (m)
    integer :: nx, ny, i, j
    real(dp) :: dFhx, dFhvy, dGhux, dGhvy
    real(dp) :: dFhux, dGhuy
    real(dp) :: src_u, src_v, h_ij

    nx = size(state%h, 1)
    ny = size(state%h, 2)

    call allocate_state(rhs, nx, ny)

    do j = 2, ny - 1
      do i = 2, nx - 1
        h_ij = state%h(i,j)

        ! Mass equation: ∂h/∂t = -∂(hu)/∂x - ∂(hv)/∂y
        dFhx  = (state%hu(i+1,j) - state%hu(i-1,j)) / (2.0_dp * dx)
        dFhvy = (state%hv(i,j+1) - state%hv(i,j-1)) / (2.0_dp * dy)
        rhs%h(i,j) = -dFhx - dFhvy

        ! x-momentum: ∂(hu)/∂t = -∂F_x/∂x - ∂(huv)/∂y + src_x
        dFhux = (state%hu(i+1,j)**2 / max(state%h(i+1,j), 1.0e-6_dp) &
               + 0.5_dp * GRAVITY * state%h(i+1,j)**2               &
               - state%hu(i-1,j)**2 / max(state%h(i-1,j), 1.0e-6_dp) &
               - 0.5_dp * GRAVITY * state%h(i-1,j)**2) / (2.0_dp * dx)
        dGhuy = (state%hu(i,j+1) * state%hv(i,j+1) / max(state%h(i,j+1), 1.0e-6_dp) &
               - state%hu(i,j-1) * state%hv(i,j-1) / max(state%h(i,j-1), 1.0e-6_dp)) &
               / (2.0_dp * dy)
        src_u = -GRAVITY * h_ij * (b(i+1,j) - b(i-1,j)) / (2.0_dp * dx)
        rhs%hu(i,j) = -dFhux - dGhuy + src_u

        ! y-momentum: ∂(hv)/∂t = -∂(huv)/∂x - ∂G_y/∂y + src_y
        dGhux = (state%hu(i+1,j) * state%hv(i+1,j) / max(state%h(i+1,j), 1.0e-6_dp) &
               - state%hu(i-1,j) * state%hv(i-1,j) / max(state%h(i-1,j), 1.0e-6_dp)) &
               / (2.0_dp * dx)
        dGhvy = (state%hv(i,j+1)**2 / max(state%h(i,j+1), 1.0e-6_dp) &
               + 0.5_dp * GRAVITY * state%h(i,j+1)**2               &
               - state%hv(i,j-1)**2 / max(state%h(i,j-1), 1.0e-6_dp) &
               - 0.5_dp * GRAVITY * state%h(i,j-1)**2) / (2.0_dp * dy)
        src_v = -GRAVITY * h_ij * (b(i,j+1) - b(i,j-1)) / (2.0_dp * dy)
        rhs%hv(i,j) = -dGhux - dGhvy + src_v
      end do
    end do
  end subroutine compute_rhs

end module shallow_water_mod
