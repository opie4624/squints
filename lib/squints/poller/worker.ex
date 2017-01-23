defmodule Squints.Poller.Worker do
  use GenServer

  import Ecto.Query
  import Squints.Repo
  import Squints.Bot

  require Logger

  # Client API

  def start_link(state, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(%{table: table}) do
    case :ets.lookup(table, :timers) do
      [] ->
        timer = schedule(5000)
        {:ok, new_state(table, [timer])}
      [timers: timers] ->
        {:ok, new_state(table, timers)}
    end
  end

  def poll do
    GenServer.cast(__MODULE__, :poll)

  def schedule_poll(delay) do
    GenServer.cast(__MODULE__, {:schedule, delay})
  end

  # Server API

  def handle_cast(:poll, state) do
    do_poll()

    {:noreply, state}
  end

  def handle_cast({:schedule, delay}, %{table: table, timers: timers}) do
    timer = schedule(delay)

    {:ok, new_state(table, [timer|timers])}
  end

  def handle_info(:poll, %{table: table, timers: timers}) do
    remaining_timers = Enum.filter(timers, fn(x) -> Process.read_timer(x) end)

    do_poll()

    {:noreply, new_state(table, remaining_timers)}
  end

  # Private API

  defp new_state(table, timers) do
    :ets.insert(table, timers: timers)
    %{table: table, timers: timers}
  end

  defp schedule(0), do: schedule(Application.get_env(:squints, :default_delay, 60000))
  defp schedule(delay), do: Process.send_after(__MODULE__, :poll, delay)

  defp do_poll() do
    Logger.debug "Called do_poll"
  end
end
