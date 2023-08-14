defmodule Raspimouse2Ex.Devices.Led do
  use GenServer

  require Logger

  # api

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @spec drive(led_name :: atom(), msg :: map()) :: :ok
  def drive(led_name, msg) do
    %{^led_name => on_off} = msg
    GenServer.call(led_name, {:drive, on_off})
  end

  @spec get_value(led_name :: atom()) :: map()
  def get_value(led_name) do
    GenServer.call(led_name, :get_value)
  end

  # callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    dev_led = Keyword.fetch!(args, :device_file_path)
    dev_null = "/dev/null"

    device =
      if File.exists?(dev_led) do
        File.open!(dev_led, [:write])
      else
        File.open!(dev_null, [:write])
      end
      |> tap(&IO.write(&1, "0"))

    {:ok, %{device: device, on_off: false}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    IO.write(state.device, "0")
    File.close(state.device)
  end

  def handle_call({:drive, on_off}, _from, state) do
    if on_off do
      :ok = IO.write(state.device, "1")
    else
      :ok = IO.write(state.device, "0")
    end

    {:reply, :ok, %{state | on_off: on_off}}
  end

  def handle_call(:get_value, _from, state) do
    {:reply, state.on_off, state}
  end
end
