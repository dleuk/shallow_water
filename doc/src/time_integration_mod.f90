!> @file time_integration_mod.f90
!> Abstract interface for time-integration schemes.
!>
!> All concrete integrators (Euler, Runge-Kutta, Lax-Wendroff, …) must
!> expose a subroutine with the signature defined by the abstract interface
!> `advance_step` below.
module time_integration_mod
  use constants_mod,     only: dp
  use shallow_water_mod, only: SWEState
  implicit none
  private

  !> Abstract interface satisfied by every time-integration scheme.
  abstract interface
    subroutine advance_step(state, b, dx, dy, dt)
      import :: dp, SWEState
      type(SWEState), intent(inout) :: state    !< In: current, Out: updated
      real(dp),       intent(in)    :: b(:,:)   !< Bed elevation
      real(dp),       intent(in)    :: dx, dy   !< Spatial step sizes
      real(dp),       intent(in)    :: dt       !< Time step
    end subroutine advance_step
  end interface

  !> Procedure pointer type matching the abstract interface.
  public :: advance_step
  public :: IntegratorPtr

  type, public :: IntegratorPtr
    procedure(advance_step), pointer, nopass :: ptr => null()
  end type IntegratorPtr

end module time_integration_mod
