defmodule Raspimouse2Ex.Devices.Switches do
  use GenServer

  require Logger

  alias Raspimouse2Ex.Devices.Switch

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def get_values() do
    GenServer.call(__MODULE__, :get_values)
  end

  def init(_args) do
    Process.flag(:trap_exit, true)

    send(self(), :sense)

    {:ok, %{values: %{switch0: false, switch1: false, switch2: false}}}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")
  end

  def handle_info(:sense, state) do
    values =
      [:switch0, :switch1, :switch2]
      |> Enum.reduce(%{}, fn key, acc ->
        value = Switch.get_value(key)
        Map.put(acc, key, value)
      end)

    Raspimouse2Ex.Rclex.publish_switches(values)

    Process.send_after(self(), :sense, 100)

    {:noreply, %{state | values: values}}
  end

  def handle_call(:get_values, _from, state) do
    {:reply, state.values, state}
  end
end
