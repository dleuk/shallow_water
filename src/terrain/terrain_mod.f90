!> @file terrain_mod.f90
!> Bathymetry / terrain module.
!>
!> The bottom topography b(x,y) enters the SWE source term.
!> This module defines the data structure and provides procedures to
!> initialise b on a CartesianGrid for a selection of analytic shapes
!> (flat bottom, Gaussian hill, step, …).
module terrain_mod
  use constants_mod,       only: dp, PI
  use cartesian_grid_mod,  only: CartesianGrid
  implicit none
  private

  !> Supported terrain presets
  integer, parameter, public :: TERRAIN_FLAT          = 0
  integer, parameter, public :: TERRAIN_GAUSSIAN_HILL = 1
  integer, parameter, public :: TERRAIN_STEP          = 2

  public :: init_terrain_flat
  public :: init_terrain_gaussian_hill
  public :: init_terrain_step

contains

  !> Flat bottom: b = 0 everywhere.
  subroutine init_terrain_flat(b, grid)
    real(dp),            intent(out) :: b(:,:)
    type(CartesianGrid), intent(in)  :: grid
    b = 0.0_dp
  end subroutine init_terrain_flat

  !> Gaussian hill centred in the domain.
  !> b(x,y) = amplitude * exp( -((x-x0)^2 + (y-y0)^2) / (2*sigma^2) )
  subroutine init_terrain_gaussian_hill(b, grid, amplitude, sigma)
    real(dp),            intent(out) :: b(:,:)
    type(CartesianGrid), intent(in)  :: grid
    real(dp),            intent(in)  :: amplitude  !< Peak height (m)
    real(dp),            intent(in)  :: sigma      !< Spread parameter (m)
    integer  :: i, j
    real(dp) :: x0, y0, r2

    x0 = grid%x(grid%nx / 2)
    y0 = grid%y(grid%ny / 2)

    do j = 1, grid%ny
      do i = 1, grid%nx
        r2 = (grid%x(i) - x0)**2 + (grid%y(j) - y0)**2
        b(i,j) = amplitude * exp(-r2 / (2.0_dp * sigma**2))
      end do
    end do
  end subroutine init_terrain_gaussian_hill

  !> Step bathymetry: b = 0 for x < x_step, b = height for x >= x_step.
  subroutine init_terrain_step(b, grid, x_step, height)
    real(dp),            intent(out) :: b(:,:)
    type(CartesianGrid), intent(in)  :: grid
    real(dp),            intent(in)  :: x_step  !< Step position (m)
    real(dp),            intent(in)  :: height  !< Step height  (m)
    integer :: i, j

    do j = 1, grid%ny
      do i = 1, grid%nx
        if (grid%x(i) >= x_step) then
          b(i,j) = height
        else
          b(i,j) = 0.0_dp
        end if
      end do
    end do
  end subroutine init_terrain_step

end module terrain_mod
