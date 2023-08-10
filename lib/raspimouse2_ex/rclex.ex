defmodule Raspimouse2Ex.Rclex do
  use GenServer

  require Logger

  alias Raspimouse2Ex.Devices.Buzzer
  alias Raspimouse2Ex.Devices.Motor
  alias Raspimouse2Ex.Devices.MotorEnabler

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec publish_light_sensors(values :: list()) :: :ok
  def publish_light_sensors(values) do
    GenServer.call(__MODULE__, {:publish_light_sensors, values})
  end

  # callbacks

  def init(_args) do
    context = Rclex.rclexinit()
    {:ok, node} = Rclex.ResourceServer.create_node(context, ~c"rclex")

    {:ok, buzzer_subscriber} =
      Rclex.Node.create_subscriber(node, ~c"StdMsgs.Msg.Int16", ~c"buzzer")

    {:ok, velocity_subscriber} =
      Rclex.Node.create_subscriber(node, ~c"GeometryMsgs.Msg.Twist", ~c"cmd_vel")

    Rclex.Subscriber.start_subscribing(buzzer_subscriber, context, &buzzer_callback/1)
    Rclex.Subscriber.start_subscribing(velocity_subscriber, context, &velocity_callback/1)

    {:ok, light_sensors_publisher} =
      Rclex.Node.create_publisher(node, ~c"RaspimouseMsgs.Msg.LightSensors", ~c"light_sensors")

    {:ok,
     %{
       context: context,
       node: node,
       jobs: [light_sensors_publisher, buzzer_subscriber, velocity_subscriber],
       light_sensors_publisher: light_sensors_publisher,
       light_sensors_msg: Rclex.Msg.initialize(~c"RaspimouseMsgs.Msg.LightSensors")
     }}
  end

  def terminate(_reason, state) do
    Rclex.Node.finish_jobs(state.jobs)
    Rclex.ResourceServer.finish_node(state.node)
    Rclex.shutdown(state.context)
  end

  def handle_call({:publish_light_sensors, values}, _from, state) do
    [forward_r, right, left, forward_l] = values

    msg_struct = %Rclex.RaspimouseMsgs.Msg.LightSensors{
      forward_r: forward_r,
      forward_l: forward_l,
      left: left,
      right: right
    }

    Rclex.Msg.set(state.light_sensors_msg, msg_struct, ~c"RaspimouseMsgs.Msg.LightSensors")

    :ok = Rclex.Publisher.publish([state.light_sensors_publisher], [state.light_sensors_msg])

    {:reply, :ok, state}
  end

  defp buzzer_callback(msg) do
    recv_msg = Rclex.Msg.read(msg, ~c"StdMsgs.Msg.Int16")
    Logger.debug("#{__MODULE__} receive msg: #{inspect(recv_msg)}")

    :ok = Buzzer.beep(recv_msg)
  end

  defp velocity_callback(msg) do
    recv_msg = Rclex.Msg.read(msg, ~c"GeometryMsgs.Msg.Twist")
    Logger.debug("#{__MODULE__} receive msg: #{inspect(recv_msg)}")

    :ok = MotorEnabler.enable(recv_msg)

    Task.start_link(fn -> :ok = Motor.drive(:motor_l, recv_msg) end)
    Task.start_link(fn -> :ok = Motor.drive(:motor_r, recv_msg) end)
  end
end
