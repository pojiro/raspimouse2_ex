defmodule Raspimouse2Ex.Devices.Buzzer do
  use GenServer

  require Logger

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec beep(integer()) :: :ok
  def beep(hz) when is_integer(hz) and hz >= 0 and hz <= 20000 do
    GenServer.call(__MODULE__, {:beep, hz})
  end

  # callbacks

  def init(_args) do
    Process.flag(:trap_exit, true)

    buzzer = "/dev/rtbuzzer0"
    dev_null = "/dev/null"

    device_file =
      if File.exists?(buzzer) do
        File.open!(buzzer, [:write])
      else
        File.open!(dev_null, [:write])
      end

    {:ok, %{device: device_file}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{reason}.")

    IO.write(state.device, "0")
    File.close(state.device)
  end

  def handle_call({:beep, hz}, _from, state) do
    :ok = IO.write(state.device, "#{hz}")
    {:reply, :ok, state}
  end
end
