!> @file input_mod.f90
!> Routines for reading simulation configuration from a namelist file.
!>
!> Expected namelist file format (FORTRAN NAMELIST):
!>
!>   &sim_params
!>     nx = 200,
!>     ny = 200,
!>     x_max = 500.0,
!>     t_end = 200.0,
!>   /
module input_mod
  use constants_mod,  only: dp
  use parameters_mod, only: SimParams, default_params
  implicit none
  private

  public :: read_namelist

contains

  !> Read simulation parameters from a NAMELIST file.
  !> Falls back to default_params() values for any unset keys.
  subroutine read_namelist(params, filename)
    type(SimParams),  intent(out) :: params
    character(len=*), intent(in)  :: filename

    integer  :: nx, ny, output_freq, unit, ios
    real(dp) :: x_min, x_max, y_min, y_max
    real(dp) :: t_start, t_end, dt, cfl
    character(len=256) :: output_dir

    namelist /sim_params/ nx, ny, x_min, x_max, y_min, y_max, &
                          t_start, t_end, dt, cfl,            &
                          output_freq, output_dir

    ! Start from defaults
    params = default_params()

    ! Mirror defaults into local variables so unset keys keep defaults
    nx          = params%nx
    ny          = params%ny
    x_min       = params%x_min
    x_max       = params%x_max
    y_min       = params%y_min
    y_max       = params%y_max
    t_start     = params%t_start
    t_end       = params%t_end
    dt          = params%dt
    cfl         = params%cfl
    output_freq = params%output_freq
    output_dir  = params%output_dir

    open(newunit=unit, file=trim(filename), status='old', action='read', iostat=ios)
    if (ios /= 0) then
      write(*,'(A,A)') '[input] Warning: cannot open namelist file: ', trim(filename)
      write(*,'(A)')   '[input] Using default parameters.'
      return
    end if

    read(unit, nml=sim_params, iostat=ios)
    close(unit)

    if (ios /= 0) then
      write(*,'(A,A)') '[input] Warning: error reading namelist: ', trim(filename)
    end if

    params%nx          = nx
    params%ny          = ny
    params%x_min       = x_min
    params%x_max       = x_max
    params%y_min       = y_min
    params%y_max       = y_max
    params%t_start     = t_start
    params%t_end       = t_end
    params%dt          = dt
    params%cfl         = cfl
    params%output_freq = output_freq
    params%output_dir  = output_dir
  end subroutine read_namelist

end module input_mod
