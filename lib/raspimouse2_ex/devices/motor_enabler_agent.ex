defmodule Raspimouse2Ex.Devices.MotorEnablerAgent do
  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> %{enable?: false} end, name: __MODULE__)
  end

  def get() do
    Agent.get(__MODULE__, & &1.enable?)
  end

  def set(enable?) do
    Agent.update(__MODULE__, &%{&1 | enable?: enable?})
  end
end
