!> @file parameters_mod.f90
!> Runtime simulation parameters (read from config or set as defaults).
module parameters_mod
  use constants_mod, only: dp
  implicit none
  private

  !> Simulation parameters type bundling all run-time settings.
  type, public :: SimParams
    !> Grid dimensions
    integer  :: nx = 100      !< Number of cells in x-direction
    integer  :: ny = 100      !< Number of cells in y-direction
    !> Domain extents (metres)
    real(dp) :: x_min = 0.0_dp
    real(dp) :: x_max = 1000.0_dp
    real(dp) :: y_min = 0.0_dp
    real(dp) :: y_max = 1000.0_dp
    !> Temporal settings
    real(dp) :: t_start  = 0.0_dp    !< Start time (s)
    real(dp) :: t_end    = 100.0_dp  !< End time (s)
    real(dp) :: dt       = 0.1_dp    !< Time step (s)
    real(dp) :: cfl      = 0.5_dp    !< CFL number for adaptive time-stepping
    !> Output settings
    integer  :: output_freq = 10     !< Write output every N steps
    character(len=256) :: output_dir = 'output'
  end type SimParams

  public :: default_params

contains

  !> Return a SimParams struct filled with default values.
  function default_params() result(p)
    type(SimParams) :: p
    p%nx          = 100
    p%ny          = 100
    p%x_min       = 0.0_dp
    p%x_max       = 1000.0_dp
    p%y_min       = 0.0_dp
    p%y_max       = 1000.0_dp
    p%t_start     = 0.0_dp
    p%t_end       = 100.0_dp
    p%dt          = 0.1_dp
    p%cfl         = 0.5_dp
    p%output_freq = 10
    p%output_dir  = 'output'
  end function default_params

end module parameters_mod
