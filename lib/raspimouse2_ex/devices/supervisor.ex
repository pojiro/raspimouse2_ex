defmodule Raspimouse2Ex.Devices.Supervisor do
  use Supervisor

  alias Raspimouse2Ex.Devices.Led
  alias Raspimouse2Ex.Devices.Buzzer
  alias Raspimouse2Ex.Devices.Motor
  alias Raspimouse2Ex.Devices.MotorEnablerAgent
  alias Raspimouse2Ex.Devices.MotorEnabler
  alias Raspimouse2Ex.Devices.Switch
  alias Raspimouse2Ex.Devices.Switches
  alias Raspimouse2Ex.Devices.LightSensors

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      led(:led0, "/dev/rtled0"),
      led(:led1, "/dev/rtled1"),
      led(:led2, "/dev/rtled2"),
      led(:led3, "/dev/rtled3"),
      {Buzzer, [device_file_path: "/dev/rtbuzzer0"]},
      motor(:motor_l, "/dev/rtmotor_raw_l0", -1),
      motor(:motor_r, "/dev/rtmotor_raw_r0", 1),
      {MotorEnablerAgent, []},
      {MotorEnabler, [device_file_path: "/dev/rtmotoren0"]},
      switch(:switch0, "/dev/rtswitch0"),
      switch(:switch1, "/dev/rtswitch1"),
      switch(:switch2, "/dev/rtswitch2"),
      {Switches, []},
      {LightSensors, [device_file_path: "/dev/rtlightsensor0"]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp led(id, device_file_path) do
    Supervisor.child_spec(
      {Led,
       [
         name: id,
         device_file_path: device_file_path
       ]},
      id: id
    )
  end

  defp motor(id, device_file_path, coeff) do
    Supervisor.child_spec(
      {Motor,
       [
         name: id,
         device_file_path: device_file_path,
         coeff: coeff
       ]},
      id: id
    )
  end

  defp switch(id, device_file_path) do
    Supervisor.child_spec(
      {Switch,
       [
         name: id,
         device_file_path: device_file_path
       ]},
      id: id
    )
  end
end
