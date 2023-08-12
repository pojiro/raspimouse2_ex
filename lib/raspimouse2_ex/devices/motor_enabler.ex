defmodule Raspimouse2Ex.Devices.MotorEnabler do
  use GenServer

  require Logger

  @timeout_ms 10_000

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec enable() :: :ok
  def enable() do
    GenServer.call(__MODULE__, :enable)
  end

  @spec enable?() :: boolean()
  def enable?() do
    GenServer.call(__MODULE__, :enable?)
  end

  # callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    dev_motor_enable = Keyword.fetch!(args, :device_file_path)
    dev_null = "/dev/null"

    device =
      if File.exists?(dev_motor_enable) do
        File.open!(dev_motor_enable, [:write])
      else
        File.open!(dev_null, [:write])
      end
      |> tap(&IO.write(&1, "0"))

    {:ok, %{device: device, enable?: false}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    IO.write(state.device, "0")
    File.close(state.device)
  end

  def handle_call(:enable, _from, state) do
    IO.write(state.device, "1")
    {:reply, :ok, %{state | enable?: true}, @timeout_ms}
  end

  def handle_call(:enable?, _from, state) do
    {:reply, state.enable?, state, @timeout_ms}
  end

  def handle_info(:timeout, state) do
    IO.write(state.device, "0")
    Logger.info("#{__MODULE__}: disabled due to no message received for #{@timeout_ms} ms.")
    {:noreply, %{state | enable?: false}}
  end
end
