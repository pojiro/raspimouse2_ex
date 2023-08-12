defmodule Raspimouse2ExTest do
  use ExUnit.Case

  test "is_motor_enable?/0 return false" do
    Raspimouse2Ex.Devices.MotorEnabler.disable()
    assert Raspimouse2Ex.is_motor_enable?() == false
  end

  test "is_motor_enable?/0 return true" do
    Raspimouse2Ex.Devices.MotorEnabler.enable()
    assert Raspimouse2Ex.is_motor_enable?() == true
  end

  test "get_left_motor_state/0" do
    assert %{velocity: 0, pwm_hz: 0} = Raspimouse2Ex.get_left_motor_state()
  end

  test "get_right_motor_state/0" do
    assert %{velocity: 0, pwm_hz: 0} = Raspimouse2Ex.get_right_motor_state()
  end
end
