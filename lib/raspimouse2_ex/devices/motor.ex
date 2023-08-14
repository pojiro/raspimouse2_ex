defmodule Raspimouse2Ex.Devices.Motor do
  use GenServer

  require Logger

  @wheel_dia_meter 0.048
  @wheel_tread_meter 0.0925

  # api

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @spec drive(motor_name :: atom(), msg :: map()) :: :ok
  def drive(motor_name, %{linear: %{x: x}, angular: %{z: z}} = _msg) do
    GenServer.call(motor_name, {:drive, {x, z}})
  end

  @spec get_state(motor_name :: atom()) :: map()
  def get_state(motor_name) do
    GenServer.call(motor_name, :get_state)
  end

  # callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    coeff = Keyword.fetch!(args, :coeff)
    dev_motor = Keyword.fetch!(args, :device_file_path)
    dev_null = "/dev/null"

    device =
      if File.exists?(dev_motor) do
        File.open!(dev_motor, [:write])
      else
        File.open!(dev_null, [:write])
      end
      |> tap(&IO.write(&1, "0"))

    {:ok, %{device: device, coeff: coeff, velocity: 0, pwm_hz: 0}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    IO.write(state.device, "0")
    File.close(state.device)
  end

  def handle_call({:drive, {x, z}}, _from, %{coeff: coeff} = state) do
    # ref. https://github.com/rt-net/raspimouse2/blob/2bac95b37d32ea28e8db5c83e2b70b8c46f14d79/raspimouse/src/raspimouse_component.cpp#L442-L445
    # リンク先の計算式だと velocity 物理量の単位が正しくないので計算式を修正している
    # 修正による、指示値 pwm_hz は変更なし
    velocity = x + coeff * z * @wheel_tread_meter / 2
    pwm_hz = round(velocity / (@wheel_dia_meter * :math.pi()) * 400)

    # ref. https://github.com/rt-net/RaspberryPiMouse#pwm-frequency-for-leftright-motor-driver-output
    with true <- abs(pwm_hz) <= 10000 do
      Logger.debug("#{__MODULE__}: pwm_hz is #{pwm_hz}.")
      :ok = IO.write(state.device, "#{pwm_hz}")
    else
      _ -> raise BadArityError
    end

    {:reply, :ok, %{state | velocity: velocity, pwm_hz: pwm_hz}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
