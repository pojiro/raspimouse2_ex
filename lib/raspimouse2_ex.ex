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

  @spec get_switches_values() :: map()
  def get_switches_values() do
    Raspimouse2Ex.Devices.Switches.get_values()
  end

  @spec get_light_sensors_values() :: map()
  def get_light_sensors_values() do
    Raspimouse2Ex.Devices.LightSensors.get_values()
  end

  @spec get_leds_values() :: map()
  def get_leds_values() do
    [:led0, :led1, :led2, :led3]
    |> Enum.reduce(%{}, fn key, acc ->
      value = Raspimouse2Ex.Devices.Led.get_value(key)
      Map.put(acc, key, value)
    end)
  end

  @spec get_buzzer_tone() :: integer()
  def get_buzzer_tone() do
    Raspimouse2Ex.Devices.Buzzer.get_tone()
  end
end
