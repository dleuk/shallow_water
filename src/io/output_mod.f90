!> @file output_mod.f90
!> Routines for writing simulation results to disk.
!>
!> Supported format:
!>   - NetCDF (multiple time steps per file with rollover)
module output_mod
  use constants_mod,     only: dp
  use shallow_water_mod, only: SWEState
  use netcdf, only: nf90_close, nf90_clobber, nf90_create, nf90_def_dim,     &
                    nf90_def_var, nf90_double, nf90_enddef, nf90_int,         &
                    nf90_noerr, nf90_put_att, nf90_put_var, nf90_strerror,    &
                    nf90_unlimited
  implicit none
  private

  public :: write_netcdf
  public :: close_netcdf_writer

  integer, save :: current_ncid = -1
  integer, save :: current_file_index = 0
  integer, save :: records_in_file = 0
  integer, save :: cached_nx = -1
  integer, save :: cached_ny = -1
  character(len=512), save :: current_filepath = ''

  integer, save :: var_h_id = -1
  integer, save :: var_hu_id = -1
  integer, save :: var_hv_id = -1
  integer, save :: var_u_id = -1
  integer, save :: var_v_id = -1
  integer, save :: var_step_id = -1
  integer, save :: var_time_id = -1

contains

  !> Write the current state to a NetCDF file, rolling over after a
  !> configurable number of snapshots.
  !>
  !> File path: <output_dir>/<prefix>_partNNNN.nc
  !> Variables: x(x), y(y), h(x,y,time), hu(x,y,time), hv(x,y,time),
  !>            u(x,y,time), v(x,y,time), step(time), time(time)
  subroutine write_netcdf(state, x, y, step, time, max_time_steps_per_file, output_dir, prefix)
    type(SWEState),   intent(in) :: state
    real(dp),         intent(in) :: x(:), y(:)
    integer,          intent(in) :: step
    real(dp),         intent(in) :: time
    integer,          intent(in) :: max_time_steps_per_file
    character(len=*), intent(in) :: output_dir
    character(len=*), intent(in) :: prefix

    integer :: nx, ny
    integer :: status
    integer :: record_index, max_per_file
    integer, dimension(3) :: start3, count3
    integer, dimension(1) :: start1, count1
    integer, dimension(1) :: step_arr
    real(dp), dimension(1) :: time_arr
    real(dp), allocatable :: u(:,:), v(:,:)

    nx = size(state%h, 1)
    ny = size(state%h, 2)

    max_per_file = max(1, max_time_steps_per_file)

    if (max_time_steps_per_file <= 0) then
      write(*,'(A,I0)') '[output] Warning: max_time_steps_per_file <= 0, using ', max_per_file
    end if

    if (current_ncid < 0) then
      call start_new_netcdf_file(x, y, output_dir, prefix)
    else
      if (nx /= cached_nx .or. ny /= cached_ny) then
        write(*,'(A)') '[output] Error: grid size changed while writer is active.'
        write(*,'(A)') '[output] Call close_netcdf_writer before switching grid size.'
        error stop
      end if
    end if

    if (records_in_file >= max_per_file) then
      call close_netcdf_writer()
      call start_new_netcdf_file(x, y, output_dir, prefix)
    end if

    allocate(u(nx, ny), v(nx, ny))
    u = 0.0_dp
    v = 0.0_dp
    where (state%h > 0.0_dp)
      u = state%hu / state%h
      v = state%hv / state%h
    end where

    record_index = records_in_file + 1
    start3 = (/ 1, 1, record_index /)
    count3 = (/ nx, ny, 1 /)
    start1 = (/ record_index /)
    count1 = (/ 1 /)
    step_arr(1) = step
    time_arr(1) = time

    status = nf90_put_var(current_ncid, var_h_id, state%h, start=start3, count=count3)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(h)', status)
    status = nf90_put_var(current_ncid, var_hu_id, state%hu, start=start3, count=count3)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(hu)', status)
    status = nf90_put_var(current_ncid, var_hv_id, state%hv, start=start3, count=count3)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(hv)', status)
    status = nf90_put_var(current_ncid, var_u_id, u, start=start3, count=count3)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(u)', status)
    status = nf90_put_var(current_ncid, var_v_id, v, start=start3, count=count3)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(v)', status)
    status = nf90_put_var(current_ncid, var_step_id, step_arr, start=start1, count=count1)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(step)', status)
    status = nf90_put_var(current_ncid, var_time_id, time_arr, start=start1, count=count1)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(time)', status)

    records_in_file = record_index
    deallocate(u, v)
  end subroutine write_netcdf

  subroutine start_new_netcdf_file(x, y, output_dir, prefix)
    real(dp),         intent(in) :: x(:), y(:)
    character(len=*), intent(in) :: output_dir
    character(len=*), intent(in) :: prefix

    integer :: status
    integer :: dim_x_id, dim_y_id, dim_t_id
    integer :: var_x_id, var_y_id
    integer, dimension(3) :: dimids_xyt
    integer, dimension(1) :: dimids_t

    cached_nx = size(x)
    cached_ny = size(y)

    current_file_index = current_file_index + 1
    records_in_file = 0
    write(current_filepath, '(A,A,A,A,I4.4,A)') &
      trim(output_dir), '/', trim(prefix), '_part', current_file_index, '.nc'

    status = nf90_create(trim(current_filepath), nf90_clobber, current_ncid)
    if (status /= nf90_noerr) call report_netcdf_error('create', status)

    status = nf90_def_dim(current_ncid, 'x', cached_nx, dim_x_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_dim(x)', status)
    status = nf90_def_dim(current_ncid, 'y', cached_ny, dim_y_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_dim(y)', status)
    status = nf90_def_dim(current_ncid, 'time', nf90_unlimited, dim_t_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_dim(time)', status)

    dimids_xyt = (/ dim_x_id, dim_y_id, dim_t_id /)
    dimids_t = (/ dim_t_id /)

    status = nf90_def_var(current_ncid, 'x', nf90_double, dim_x_id, var_x_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(x)', status)
    status = nf90_def_var(current_ncid, 'y', nf90_double, dim_y_id, var_y_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(y)', status)
    status = nf90_def_var(current_ncid, 'h', nf90_double, dimids_xyt, var_h_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(h)', status)
    status = nf90_def_var(current_ncid, 'hu', nf90_double, dimids_xyt, var_hu_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(hu)', status)
    status = nf90_def_var(current_ncid, 'hv', nf90_double, dimids_xyt, var_hv_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(hv)', status)
    status = nf90_def_var(current_ncid, 'u', nf90_double, dimids_xyt, var_u_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(u)', status)
    status = nf90_def_var(current_ncid, 'v', nf90_double, dimids_xyt, var_v_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(v)', status)
    status = nf90_def_var(current_ncid, 'step', nf90_int, dimids_t, var_step_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(step)', status)
    status = nf90_def_var(current_ncid, 'time', nf90_double, dimids_t, var_time_id)
    if (status /= nf90_noerr) call report_netcdf_error('def_var(time)', status)

    status = nf90_put_att(current_ncid, var_x_id, 'units', 'm')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(x.units)', status)
    status = nf90_put_att(current_ncid, var_y_id, 'units', 'm')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(y.units)', status)
    status = nf90_put_att(current_ncid, var_h_id, 'units', 'm')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(h.units)', status)
    status = nf90_put_att(current_ncid, var_hu_id, 'units', 'm2 s-1')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(hu.units)', status)
    status = nf90_put_att(current_ncid, var_hv_id, 'units', 'm2 s-1')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(hv.units)', status)
    status = nf90_put_att(current_ncid, var_u_id, 'units', 'm s-1')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(u.units)', status)
    status = nf90_put_att(current_ncid, var_v_id, 'units', 'm s-1')
    if (status /= nf90_noerr) call report_netcdf_error('put_att(v.units)', status)

    status = nf90_enddef(current_ncid)
    if (status /= nf90_noerr) call report_netcdf_error('enddef', status)

    status = nf90_put_var(current_ncid, var_x_id, x)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(x)', status)
    status = nf90_put_var(current_ncid, var_y_id, y)
    if (status /= nf90_noerr) call report_netcdf_error('put_var(y)', status)
  end subroutine start_new_netcdf_file

  subroutine close_netcdf_writer()
    integer :: status
    if (current_ncid >= 0) then
      status = nf90_close(current_ncid)
      if (status /= nf90_noerr) then
        write(*,'(A,A)') '[output] Warning closing NetCDF file: ', trim(current_filepath)
        write(*,'(A,A)') '[output] NetCDF says: ', trim(nf90_strerror(status))
      end if
    end if

    current_ncid = -1
    records_in_file = 0
    cached_nx = -1
    cached_ny = -1
    current_filepath = ''

    var_h_id = -1
    var_hu_id = -1
    var_hv_id = -1
    var_u_id = -1
    var_v_id = -1
    var_step_id = -1
    var_time_id = -1
  end subroutine close_netcdf_writer

  subroutine report_netcdf_error(action, status)
    character(len=*), intent(in) :: action
    integer,          intent(in) :: status
    write(*,'(A,A,A,A)') '[output] NetCDF error in ', trim(action), ': ', trim(current_filepath)
    write(*,'(A,A)') '[output] NetCDF says: ', trim(nf90_strerror(status))
    call close_netcdf_writer()
    error stop
  end subroutine report_netcdf_error

end module output_mod
