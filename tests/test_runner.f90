!> @file test_runner.f90
!> Minimal test harness.  Each test_* subroutine returns .true. on pass.
program test_runner
  use test_constants_mod, only: run_constants_tests
  use test_grid_mod,      only: run_grid_tests
  use test_swe_mod,       only: run_swe_tests
  implicit none

  integer :: passed, failed
  logical :: ok

  passed = 0
  failed = 0

  write(*,'(A)') '=== Shallow Water Test Suite ==='

  ok = run_constants_tests(); call tally(ok, 'constants', passed, failed)
  ok = run_grid_tests();      call tally(ok, 'grid',      passed, failed)
  ok = run_swe_tests();       call tally(ok, 'swe',       passed, failed)

  write(*,'(A)') '================================'
  write(*,'(A,I0,A,I0)') 'PASSED: ', passed, '  FAILED: ', failed
  if (failed > 0) stop 1

contains

  subroutine tally(ok, name, passed, failed)
    logical,          intent(in)    :: ok
    character(len=*), intent(in)    :: name
    integer,          intent(inout) :: passed, failed
    if (ok) then
      write(*,'(A,A)') '  [PASS] ', name
      passed = passed + 1
    else
      write(*,'(A,A)') '  [FAIL] ', name
      failed = failed + 1
    end if
  end subroutine tally

end program test_runner
