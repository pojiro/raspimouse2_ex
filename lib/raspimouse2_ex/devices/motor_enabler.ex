defmodule Raspimouse2Ex.Devices.MotorEnabler do
  use GenServer

  require Logger

  alias Raspimouse2Ex.Devices.MotorEnablerAgent

  @timeout_ms 10_000

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec enable() :: :ok
  def enable() do
    GenServer.call(__MODULE__, :enable)
  end

  @spec disable() :: :ok
  def disable() do
    GenServer.call(__MODULE__, :disable)
  end

  @spec enable?() :: boolean()
  def enable?() do
    MotorEnablerAgent.get()
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

    IO.write(device, "0")
    MotorEnablerAgent.set(false)

    {:ok, %{device: device}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    IO.write(state.device, "0")
    MotorEnablerAgent.set(false)
    File.close(state.device)
  end

  def handle_call(:enable, _from, state) do
    IO.write(state.device, "1")
    MotorEnablerAgent.set(true)
    {:reply, :ok, state, @timeout_ms}
  end

  def handle_call(:disable, _from, state) do
    IO.write(state.device, "0")
    MotorEnablerAgent.set(false)
    {:reply, :ok, state}
  end

  def handle_info(:timeout, state) do
    IO.write(state.device, "0")
    MotorEnablerAgent.set(false)
    Logger.info("#{__MODULE__}: disabled due to no message received for #{@timeout_ms} ms.")
    {:noreply, state}
  end
end
