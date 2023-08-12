defmodule Raspimouse2Ex do
  @moduledoc """
  Documentation for `Raspimouse2Ex`.
  """

  @spec is_motor_enable?() :: boolean
  def is_motor_enable?() do
    Raspimouse2Ex.Devices.MotorEnabler.enable?()
  end
end
