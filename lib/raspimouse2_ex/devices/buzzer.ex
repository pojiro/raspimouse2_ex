defmodule Raspimouse2Ex.Devices.Buzzer do
  use GenServer

  require Logger

  # api

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec beep(msg :: map()) :: :ok
  def beep(%{data: hz} = _msg) do
    GenServer.call(__MODULE__, {:beep, hz})
  end

  # callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    dev_buzzer = Keyword.fetch!(args, :device_file_path)
    dev_null = "/dev/null"

    device =
      if File.exists?(dev_buzzer) do
        File.open!(dev_buzzer, [:write])
      else
        File.open!(dev_null, [:write])
      end
      |> tap(&IO.write(&1, "0"))

    {:ok, %{device: device}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    IO.write(state.device, "0")
    File.close(state.device)
  end

  def handle_call({:beep, hz}, _from, state) do
    with true <- is_integer(hz),
         true <- hz >= 0 and hz <= 20000 do
      IO.write(state.device, "#{hz}")
    else
      _ -> raise BadArityError
    end

    {:reply, :ok, state}
  end
end
