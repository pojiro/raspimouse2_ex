defmodule Raspimouse2Ex.Rclex do
  use GenServer

  require Logger

  alias Raspimouse2Ex.Devices.Led
  alias Raspimouse2Ex.Devices.Buzzer
  alias Raspimouse2Ex.Devices.Motor
  alias Raspimouse2Ex.Devices.MotorEnabler

  alias Rclex.Pkgs.{RaspimouseMsgs, StdMsgs, GeometryMsgs}

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec publish_switches(values :: map()) :: :ok
  def publish_switches(values) do
    GenServer.call(__MODULE__, {:publish_switches, values})
  end

  @spec publish_light_sensors(values :: list()) :: :ok
  def publish_light_sensors(values) do
    GenServer.call(__MODULE__, {:publish_light_sensors, values})
  end

  # callbacks

  def init(_args) do
    :ok = Rclex.start_node("rclex")

    :ok =
      Rclex.start_subscription(&leds_callback/1, RaspimouseMsgs.Msg.Leds, "/leds", "rclex")

    :ok =
      Rclex.start_subscription(&buzzer_callback/1, StdMsgs.Msg.Int16, "/buzzer", "rclex")

    :ok =
      Rclex.start_subscription(&velocity_callback/1, GeometryMsgs.Msg.Twist, "/cmd_vel", "rclex")

    :ok =
      Rclex.start_publisher(RaspimouseMsgs.Msg.Switches, "/switches", "rclex")

    :ok =
      Rclex.start_publisher(RaspimouseMsgs.Msg.LightSensors, "/light_sensors", "rclex")

    {:ok, %{}}
  end

  def terminate(_reason, _state) do
  end

  def handle_call({:publish_switches, values}, _from, state) do
    msg_struct = struct(RaspimouseMsgs.Msg.Switches, values)

    :ok = Rclex.publish(msg_struct, "/switches", "rclex")

    {:reply, :ok, state}
  end

  def handle_call({:publish_light_sensors, values}, _from, state) do
    [forward_r, right, left, forward_l] = values

    msg_struct =
      struct(RaspimouseMsgs.Msg.LightSensors, %{
        forward_r: forward_r,
        forward_l: forward_l,
        left: left,
        right: right
      })

    :ok = Rclex.publish(msg_struct, "/light_sensors", "rclex")

    {:reply, :ok, state}
  end

  defp leds_callback(msg) do
    Logger.debug("#{__MODULE__} receive msg: #{inspect(msg)}")

    Task.start_link(fn -> :ok = Led.drive(:led0, msg) end)
    Task.start_link(fn -> :ok = Led.drive(:led1, msg) end)
    Task.start_link(fn -> :ok = Led.drive(:led2, msg) end)
    Task.start_link(fn -> :ok = Led.drive(:led3, msg) end)
  end

  defp buzzer_callback(msg) do
    Logger.debug("#{__MODULE__} receive msg: #{inspect(msg)}")

    :ok = Buzzer.beep(msg)
  end

  defp velocity_callback(msg) do
    Logger.debug("#{__MODULE__} receive msg: #{inspect(msg)}")

    :ok = MotorEnabler.enable()

    Task.start_link(fn -> :ok = Motor.drive(:motor_l, msg) end)
    Task.start_link(fn -> :ok = Motor.drive(:motor_r, msg) end)
  end
end
