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

  !> Compute the RHS of the SWE.
  !> scheme = 1: central differences
  !> scheme = 2: Rusanov (local Lax-Friedrichs) fluxes
  subroutine compute_rhs(rhs, state, b, dx, dy, scheme)
    type(SWEState), intent(out) :: rhs      !< Tendencies d/dt(h, hu, hv)
    type(SWEState), intent(in)  :: state    !< Current state
    real(dp),       intent(in)  :: b(:,:)   !< Bed elevation (m)
    real(dp),       intent(in)  :: dx, dy   !< Grid spacing  (m)
    integer, intent(in), optional :: scheme
    integer :: nx, ny, i, j, rhs_scheme
    real(dp) :: dFhx, dFhvy, dGhux, dGhvy
    real(dp) :: dFhux, dGhuy
    real(dp) :: src_u, src_v, h_ij
    real(dp) :: fL_h, fL_hu, fL_hv, fR_h, fR_hu, fR_hv
    real(dp) :: gB_h, gB_hu, gB_hv, gT_h, gT_hu, gT_hv

    nx = size(state%h, 1)
    ny = size(state%h, 2)
    rhs_scheme = 1
    if (present(scheme)) rhs_scheme = scheme

    call allocate_state(rhs, nx, ny)

    select case (rhs_scheme)
    case (1)
      call compute_rhs_central(rhs, state, b, dx, dy)
    case (2)
      call compute_rhs_rusanov(rhs, state, b, dx, dy)
    case default
      write(*,'(A,I0)') '[rhs] Warning: unknown discretization scheme; using 1 = central differences: ', rhs_scheme
      call compute_rhs_central(rhs, state, b, dx, dy)
    end select
  end subroutine compute_rhs

  !> Compute RHS using central differences.
  subroutine compute_rhs_central(rhs, state, b, dx, dy)
    type(SWEState), intent(out) :: rhs
    type(SWEState), intent(in)  :: state
    real(dp),       intent(in)  :: b(:,:)
    real(dp),       intent(in)  :: dx, dy
    integer :: nx, ny, i, j
    real(dp) :: dFhx, dFhvy, dGhux, dGhvy
    real(dp) :: dFhux, dGhuy
    real(dp) :: src_u, src_v, h_ij

    nx = size(state%h, 1)
    ny = size(state%h, 2)

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

  end subroutine compute_rhs_central

  !> Compute RHS using Rusanov (local Lax-Friedrichs) fluxes.
  subroutine compute_rhs_rusanov(rhs, state, b, dx, dy)
    type(SWEState), intent(out) :: rhs
    type(SWEState), intent(in)  :: state
    real(dp),       intent(in)  :: b(:,:)
    real(dp),       intent(in)  :: dx, dy
    integer :: nx, ny, i, j
    real(dp) :: fL_h, fL_hu, fL_hv, fR_h, fR_hu, fR_hv
    real(dp) :: gB_h, gB_hu, gB_hv, gT_h, gT_hu, gT_hv
    real(dp) :: src_u, src_v, h_ij

    nx = size(state%h, 1)
    ny = size(state%h, 2)

    do j = 2, ny - 1
      do i = 2, nx - 1
        h_ij = state%h(i,j)

        call rusanov_flux_x(fL_h, fL_hu, fL_hv, state, i-1, j)
        call rusanov_flux_x(fR_h, fR_hu, fR_hv, state, i,   j)
        call rusanov_flux_y(gB_h, gB_hu, gB_hv, state, i, j-1)
        call rusanov_flux_y(gT_h, gT_hu, gT_hv, state, i, j)

        rhs%h(i,j)  = -((fR_h  - fL_h ) / dx + (gT_h  - gB_h ) / dy)
        rhs%hu(i,j) = -((fR_hu - fL_hu) / dx + (gT_hu - gB_hu) / dy)
        rhs%hv(i,j) = -((fR_hv - fL_hv) / dx + (gT_hv - gB_hv) / dy)

        src_u = -GRAVITY * h_ij * (b(i+1,j) - b(i-1,j)) / (2.0_dp * dx)
        src_v = -GRAVITY * h_ij * (b(i,j+1) - b(i,j-1)) / (2.0_dp * dy)
        rhs%hu(i,j) = rhs%hu(i,j) + src_u
        rhs%hv(i,j) = rhs%hv(i,j) + src_v
      end do
    end do
  end subroutine compute_rhs_rusanov

  subroutine rusanov_flux_x(fh, fhu, fhv, state, i, j)
    real(dp),       intent(out) :: fh, fhu, fhv
    type(SWEState), intent(in)  :: state
    integer,        intent(in)  :: i, j
    real(dp) :: hL, huL, hvL, uL, cL
    real(dp) :: hR, huR, hvR, uR, cR
    real(dp) :: smax

    hL  = state%h (i,  j);  huL = state%hu(i,  j);  hvL = state%hv(i,  j)
    hR  = state%h (i+1,j);  huR = state%hu(i+1,j);  hvR = state%hv(i+1,j)

    uL  = merge(huL / hL, 0.0_dp, hL > 0.0_dp)
    uR  = merge(huR / hR, 0.0_dp, hR > 0.0_dp)
    cL  = sqrt(GRAVITY * max(hL, 0.0_dp))
    cR  = sqrt(GRAVITY * max(hR, 0.0_dp))

    smax = max(abs(uL) + cL, abs(uR) + cR)

    fh  = 0.5_dp * (huL + huR) - 0.5_dp * smax * (hR  - hL)
    fhu = 0.5_dp * (huL*uL + 0.5_dp*GRAVITY*hL**2 &
                  + huR*uR + 0.5_dp*GRAVITY*hR**2) &
          - 0.5_dp * smax * (huR - huL)
    fhv = 0.5_dp * (hvL*uL + hvR*uR) - 0.5_dp * smax * (hvR - hvL)
  end subroutine rusanov_flux_x

  subroutine rusanov_flux_y(fh, fhu, fhv, state, i, j)
    real(dp),       intent(out) :: fh, fhu, fhv
    type(SWEState), intent(in)  :: state
    integer,        intent(in)  :: i, j
    real(dp) :: hB, huB, hvB, vB, cB
    real(dp) :: hT, huT, hvT, vT, cT
    real(dp) :: smax

    hB  = state%h (i,j  );  huB = state%hu(i,j  );  hvB = state%hv(i,j  )
    hT  = state%h (i,j+1);  huT = state%hu(i,j+1);  hvT = state%hv(i,j+1)

    vB  = merge(hvB / hB, 0.0_dp, hB > 0.0_dp)
    vT  = merge(hvT / hT, 0.0_dp, hT > 0.0_dp)
    cB  = sqrt(GRAVITY * max(hB, 0.0_dp))
    cT  = sqrt(GRAVITY * max(hT, 0.0_dp))

    smax = max(abs(vB) + cB, abs(vT) + cT)

    fh  = 0.5_dp * (hvB + hvT) - 0.5_dp * smax * (hT  - hB)
    fhu = 0.5_dp * (huB*vB + huT*vT) - 0.5_dp * smax * (huT - huB)
    fhv = 0.5_dp * (hvB*vB + 0.5_dp*GRAVITY*hB**2 &
                  + hvT*vT + 0.5_dp*GRAVITY*hT**2) &
          - 0.5_dp * smax * (hvT - hvB)
  end subroutine rusanov_flux_y

end module shallow_water_mod
