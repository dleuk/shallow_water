!> @file flux_mod.f90
!> Numerical flux computations for the SWE.
!>
!> Provides Riemann-solver-based flux routines to be used by the
!> higher-level time-integration schemes.  Currently implements:
!>   - Local Lax-Friedrichs (Rusanov) flux
module flux_mod
  use constants_mod,     only: dp, GRAVITY
  use shallow_water_mod, only: SWEState
  implicit none
  private

  public :: rusanov_flux_x
  public :: rusanov_flux_y
  public :: max_wave_speed

contains

  !> Compute the maximum wave speed across the domain.
  !> Used for CFL-limited time-step selection.
  function max_wave_speed(state) result(smax)
    type(SWEState), intent(in) :: state
    real(dp) :: smax
    real(dp) :: c, u, v
    integer  :: i, j, nx, ny

    nx   = size(state%h, 1)
    ny   = size(state%h, 2)
    smax = 0.0_dp

    do j = 1, ny
      do i = 1, nx
        if (state%h(i,j) > 0.0_dp) then
          c    = sqrt(GRAVITY * state%h(i,j))
          u    = state%hu(i,j) / state%h(i,j)
          v    = state%hv(i,j) / state%h(i,j)
          smax = max(smax, abs(u) + c, abs(v) + c)
        end if
      end do
    end do
  end function max_wave_speed

  !> Rusanov (local Lax-Friedrichs) flux in the x-direction at the
  !> interface between cell (i,j) and (i+1,j).
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

  !> Rusanov flux in the y-direction at the interface (i,j)-(i,j+1).
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

end module flux_mod
