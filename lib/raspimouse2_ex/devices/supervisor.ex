defmodule Raspimouse2Ex.Devices.Supervisor do
  use Supervisor

  alias Raspimouse2Ex.Devices.Buzzer

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {Buzzer, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
