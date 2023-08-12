defmodule Raspimouse2Ex do
  @moduledoc """
  Documentation for `Raspimouse2Ex`.
  """

  @spec is_motor_enable?() :: boolean
  def is_motor_enable?() do
    Raspimouse2Ex.Devices.MotorEnabler.enable?()
  end

  @spec get_left_motor_state() :: map()
  def get_left_motor_state() do
    Raspimouse2Ex.Devices.Motor.get_state(:motor_l)
  end

  @spec get_right_motor_state() :: map()
  def get_right_motor_state() do
    Raspimouse2Ex.Devices.Motor.get_state(:motor_r)
  end
end
