!> @file main.f90
!> Entry point for the shallow water equations solver.
!>
!> Usage:
!>   ./shallow_water [config.nml]
!>
!> If no config file is given, default parameters are used.
program main
  use constants_mod,       only: dp
  use parameters_mod,      only: SimParams, default_params
  use input_mod,           only: read_namelist
  use cartesian_grid_mod,  only: CartesianGrid, build_cartesian_grid, &
                                  destroy_cartesian_grid
  use terrain_mod,         only: init_terrain_flat
  use shallow_water_mod,   only: SWEState, allocate_state, deallocate_state
  use euler_mod,           only: euler_step
  use output_mod,          only: write_csv
  implicit none

  type(SimParams)     :: params
  type(CartesianGrid) :: grid
  type(SWEState)      :: state
  real(dp), allocatable :: b(:,:)     ! bed elevation

  character(len=256)  :: config_file
  integer             :: step
  real(dp)            :: t
  logical             :: do_output

  ! ---- Parse command-line argument ----------------------------------------
  if (command_argument_count() >= 1) then
    call get_command_argument(1, config_file)
    call read_namelist(params, trim(config_file))
  else
    params = default_params()
    write(*,'(A)') '[main] No config file given – using defaults.'
  end if

  ! ---- Build grid ----------------------------------------------------------
  call build_cartesian_grid(grid, params)

  ! ---- Allocate state and terrain -----------------------------------------
  call allocate_state(state, params%nx, params%ny)
  allocate(b(params%nx, params%ny))

  ! Default terrain: flat bottom
  call init_terrain_flat(b, grid)

  ! Default initial condition: still water of uniform depth = 1 m
  state%h  = 1.0_dp
  state%hu = 0.0_dp
  state%hv = 0.0_dp

  write(*,'(A,I0,A,I0,A)') '[main] Grid: ', params%nx, ' x ', params%ny, ' cells'
  write(*,'(A,F8.1,A,F8.1,A)') '[main] Time: ', params%t_start, ' -> ', params%t_end, ' s'

  ! ---- Time loop ----------------------------------------------------------
  t    = params%t_start
  step = 0

  do while (t < params%t_end)
    ! Clamp last step
    if (t + params%dt > params%t_end) params%dt = params%t_end - t

    call euler_step(state, b, grid%dx, grid%dy, params%dt)

    t    = t    + params%dt
    step = step + 1

    do_output = (mod(step, params%output_freq) == 0)
    if (do_output) then
      call write_csv(state, grid%x, grid%y, step, &
                     trim(params%output_dir), 'swe')
      write(*,'(A,I6,A,F10.3)') '[main] step ', step, '  t = ', t
    end if
  end do

  write(*,'(A)') '[main] Simulation complete.'

  ! ---- Clean up -----------------------------------------------------------
  call deallocate_state(state)
  call destroy_cartesian_grid(grid)
  deallocate(b)

end program main
