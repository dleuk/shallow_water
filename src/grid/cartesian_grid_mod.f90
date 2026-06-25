!> @file cartesian_grid_mod.f90
!> Regular Cartesian (rectangular) grid with uniform spacing.
module cartesian_grid_mod
  use constants_mod,  only: dp
  use grid_mod,       only: GridBase
  use parameters_mod, only: SimParams
  implicit none
  private

  !> Cartesian grid type.
  type, extends(GridBase), public :: CartesianGrid
    !> 1-D arrays of cell-centre coordinates
    real(dp), allocatable :: x(:)   !< x cell-centre positions (m)
    real(dp), allocatable :: y(:)   !< y cell-centre positions (m)
  end type CartesianGrid

  public :: build_cartesian_grid
  public :: destroy_cartesian_grid

contains

  !> Allocate and populate a CartesianGrid from the simulation parameters.
  subroutine build_cartesian_grid(grid, params)
    type(CartesianGrid), intent(out) :: grid
    type(SimParams),     intent(in)  :: params
    integer :: i, j

    grid%nx = params%nx
    grid%ny = params%ny
    grid%dx = (params%x_max - params%x_min) / real(params%nx, dp)
    grid%dy = (params%y_max - params%y_min) / real(params%ny, dp)

    allocate(grid%x(params%nx))
    allocate(grid%y(params%ny))

    do i = 1, params%nx
      grid%x(i) = params%x_min + (real(i, dp) - 0.5_dp) * grid%dx
    end do
    do j = 1, params%ny
      grid%y(j) = params%y_min + (real(j, dp) - 0.5_dp) * grid%dy
    end do
  end subroutine build_cartesian_grid

  !> Deallocate arrays inside a CartesianGrid.
  subroutine destroy_cartesian_grid(grid)
    type(CartesianGrid), intent(inout) :: grid
    if (allocated(grid%x)) deallocate(grid%x)
    if (allocated(grid%y)) deallocate(grid%y)
  end subroutine destroy_cartesian_grid

end module cartesian_grid_mod
