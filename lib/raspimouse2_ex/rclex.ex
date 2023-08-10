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

    {:ok, %{context: context, node: node, jobs: [buzzer_subscriber, velocity_subscriber]}}
  end

  def terminate(_reason, state) do
    Rclex.Node.finish_jobs(state.jobs)
    Rclex.ResourceServer.finish_node(state.node)
    Rclex.shutdown(state.context)
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
