defmodule Raspimouse2Ex.Devices.LightSensors do
  use GenServer

  require Logger

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec get_values() :: map()
  def get_values() do
    GenServer.call(__MODULE__, :get_values)
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

    {:ok, %{device_file_path: device_file_path, values: %{fr: 0, r: 0, l: 0, fl: 0}}}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")
  end

  def handle_info(:sense, state) do
    values =
      case File.read!(state.device_file_path) do
        "" ->
          [0, 0, 0, 0]

        binary ->
          binary
          |> String.trim_trailing()
          |> String.split(" ")
          |> Enum.map(&String.to_integer/1)
      end

    Raspimouse2Ex.Rclex.publish_light_sensors(values)

    Process.send_after(self(), :sense, 100)

    [fr, r, l, fl] = values
    {:noreply, %{state | values: %{fr: fr, r: r, l: l, fl: fl}}}
  end

  def handle_call(:get_values, _from, state) do
    {:reply, state.values, state}
  end
end
