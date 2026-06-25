!> @file output_mod.f90
!> Routines for writing simulation results to disk.
!>
!> Supported formats:
!>   - Plain text CSV (one file per time step) – easy to read from Python/React
!>   - Simple binary (raw doubles) for performance – TODO
module output_mod
  use constants_mod,     only: dp
  use shallow_water_mod, only: SWEState
  implicit none
  private

  public :: write_csv

contains

  !> Write the current state to a CSV file.
  !>
  !> File path: <output_dir>/<prefix>_<step>.csv
  !> Columns: x_index, y_index, h, u, v, hu, hv
  subroutine write_csv(state, x, y, step, output_dir, prefix)
    type(SWEState),   intent(in) :: state
    real(dp),         intent(in) :: x(:), y(:)
    integer,          intent(in) :: step
    character(len=*), intent(in) :: output_dir
    character(len=*), intent(in) :: prefix

    character(len=512) :: filepath
    integer :: unit, i, j, nx, ny, ios
    real(dp) :: u_ij, v_ij

    nx = size(state%h, 1)
    ny = size(state%h, 2)

    write(filepath, '(A,A,A,A,I0,A)') &
      trim(output_dir), '/', trim(prefix), '_', step, '.csv'

    open(newunit=unit, file=trim(filepath), status='replace', &
         action='write', iostat=ios)
    if (ios /= 0) then
      write(*,'(A,A)') '[output] Error: cannot open file ', trim(filepath)
      return
    end if

    write(unit,'(A)') 'x,y,h,u,v,hu,hv'
    do j = 1, ny
      do i = 1, nx
        u_ij = merge(state%hu(i,j) / state%h(i,j), 0.0_dp, state%h(i,j) > 0.0_dp)
        v_ij = merge(state%hv(i,j) / state%h(i,j), 0.0_dp, state%h(i,j) > 0.0_dp)
        write(unit,'(ES15.7,6(",",ES15.7))') &
          x(i), y(j), state%h(i,j), u_ij, v_ij, state%hu(i,j), state%hv(i,j)
      end do
    end do
    close(unit)
  end subroutine write_csv

end module output_mod
