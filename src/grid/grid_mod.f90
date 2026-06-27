!> @file grid_mod.f90
!> Abstract grid interface.
!> To be extenden for different grid types

module grid_mod
  use constants_mod, only: dp
  implicit none
  private

  !> Minimal grid descriptor shared by all grid types.
  type, public :: GridBase
    integer  :: nx             !< Number of interior cells in x
    integer  :: ny             !< Number of interior cells in y
    real(dp) :: dx             !< Cell width  (m)
    real(dp) :: dy             !< Cell height (m)
  end type GridBase

end module grid_mod
