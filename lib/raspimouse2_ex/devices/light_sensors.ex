defmodule Raspimouse2Ex.Devices.LightSensors do
  use GenServer

  require Logger

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec drive(motor_name :: atom(), msg :: map()) :: :ok
  def drive(motor_name, %{linear: %{x: x}, angular: %{z: z}} = _msg) do
    GenServer.call(motor_name, {:drive, {x, z}})
  end

  # callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    dev_light_sensors = Keyword.fetch!(args, :device_file_path)
    dev_null = "/dev/null"

    device_file_path =
      if File.exists?(dev_light_sensors) do
        dev_light_sensors
      else
        dev_null
      end

    send(self(), :sense)

    {:ok, %{device_file_path: device_file_path}}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")
  end

  def handle_info(:sense, state) do
    case File.read!(state.device_file_path) do
      "" ->
        [0, 0, 0, 0]

      binary ->
        binary
        |> String.trim_trailing()
        |> String.split(" ")
        |> Enum.map(&String.to_integer/1)
    end
    |> Raspimouse2Ex.Rclex.publish_light_sensors()

    Process.send_after(self(), :sense, 100)

    {:noreply, state}
  end
end
