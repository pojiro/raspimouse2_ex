defmodule Raspimouse2Ex.Devices.Switch do
  use GenServer

  require Logger

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def get_value(name) do
    GenServer.call(name, :get_value)
  end

  def init(args) do
    Process.flag(:trap_exit, true)

    dev_switch = Keyword.fetch!(args, :device_file_path)
    dev_null = "/dev/null"

    device_file_path =
      if File.exists?(dev_switch) do
        dev_switch
      else
        dev_null
      end

    send(self(), :sense)

    {:ok, %{device_file_path: device_file_path, value: false}}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")
  end

  def handle_info(:sense, state) do
    value =
      case File.read!(state.device_file_path) do
        "0\n" -> true
        "1\n" -> false
        _ -> false
      end

    Process.send_after(self(), :sense, 100)

    {:noreply, %{state | value: value}}
  end

  def handle_call(:get_value, _from, state) do
    {:reply, state.value, state}
  end
end
