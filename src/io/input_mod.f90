!> @file input_mod.f90
!> Routines for reading simulation configuration from a namelist file.
!>
!> Expected namelist file format (FORTRAN NAMELIST):
!>
!>   &sim_params
!>     nx = 200,
!>     ny = 200,
!>     dx = 2.5,
!>     discretization_scheme = 2,
!>     time_integration_scheme = 2,
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
    type(SimParams) :: defaults

    integer  :: nx, ny, output_freq, max_time_steps_per_file, unit, ios
    integer  :: discretization_scheme, time_integration_scheme
    real(dp) :: dx, dy
    real(dp) :: t_end, dt, cfl
    character(len=256) :: output_dir

    namelist /sim_params/ nx, ny, dx, dy, discretization_scheme, &
          time_integration_scheme, t_end, dt, cfl, output_freq, &
          max_time_steps_per_file, output_dir

    ! Start from defaults
    defaults = default_params()
    params   = defaults

    ! Mirror defaults into local variables so unset keys keep defaults
    nx          = params%nx
    ny          = params%ny
    dx          = params%dx
    dy          = params%dy
    discretization_scheme = params%discretization_scheme
    time_integration_scheme = params%time_integration_scheme
    t_end       = params%t_end
    dt          = params%dt
    cfl         = params%cfl
    output_freq = params%output_freq
    max_time_steps_per_file = params%max_time_steps_per_file
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
    params%dx          = dx
    params%dy          = dy
    params%discretization_scheme = discretization_scheme
    params%time_integration_scheme = time_integration_scheme
    params%t_end       = t_end
    params%dt          = dt
    params%cfl         = cfl
    params%output_freq = output_freq
    params%max_time_steps_per_file = max_time_steps_per_file
    params%output_dir  = output_dir

    if (params%dx <= 0.0_dp) then
      write(*,'(A,F10.4)') '[input] Warning: invalid dx; using default dx = ', defaults%dx
      params%dx = defaults%dx
    end if
    if (params%dy <= 0.0_dp) then
      write(*,'(A,F10.4)') '[input] Warning: invalid dy; using default dy = ', defaults%dy
      params%dy = defaults%dy
    end if
    if (params%discretization_scheme < 1 .or. params%discretization_scheme > 2) then
      write(*,'(A,I0)') '[input] Warning: invalid discretization_scheme; using default = ', &
                        defaults%discretization_scheme
      params%discretization_scheme = defaults%discretization_scheme
    end if
    if (params%time_integration_scheme < 1 .or. params%time_integration_scheme > 2) then
      write(*,'(A,I0)') '[input] Warning: invalid time_integration_scheme; using default = ', &
                        defaults%time_integration_scheme
      params%time_integration_scheme = defaults%time_integration_scheme
    end if
    if (params%max_time_steps_per_file <= 0) then
      write(*,'(A,I0)') '[input] Warning: invalid max_time_steps_per_file; using default = ', &
                        defaults%max_time_steps_per_file
      params%max_time_steps_per_file = defaults%max_time_steps_per_file
    end if

    ! Fixed start time by design.
    params%t_start = 0.0_dp
  end subroutine read_namelist

end module input_mod
