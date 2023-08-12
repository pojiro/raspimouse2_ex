defmodule Raspimouse2ExTest do
  use ExUnit.Case

  test "is_motor_enable?/0 return false" do
    assert Raspimouse2Ex.is_motor_enable?() == false
  end

  test "is_motor_enable?/0 return true" do
    Raspimouse2Ex.Devices.MotorEnabler.enable()
    assert Raspimouse2Ex.is_motor_enable?() == true
  end
end
