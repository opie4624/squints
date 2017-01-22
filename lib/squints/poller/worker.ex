defmodule Squints.Poller.Worker do
  use GenServer

  import Ecto.Query
  import Squints.Repo
  import Squints.Bot

  require Logger

  # Client API

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(%{table: table}) do
    case :ets.lookup(table, :timers) do
      [] ->
        timer = schedule(5000)
        {:ok, %{table: table, timers: [timer]}}
      [timers: timers] ->
        {:ok, %{table: table, timers: timers}}
    end
  end

  def poll do
    GenServer.cast(PollerWorker, :poll)
  end

  # Server API

  def handle_cast(:poll, state) do
    do_poll()

    {:noreply, state}
  end

  def handle_info(:poll, %{table: table, timers: timers}) do
    remaining_timers = Enum.filter(timers, fn(x) -> Process.read_timer(x) end)
    :ets.insert(table, timers: remaining_timers)

    do_poll()

    {:noreply, %{table: table, timers: remaining_timers}}
  end

  # Private API

  defp schedule(0), do: schedule(Application.get_env(:squints, :default_delay, 60000))
  defp schedule(delay), do: Process.send_after(PollerWorker, :poll, delay)

  defp do_poll() do
    Logger.debug "Called do_poll"
  end
end
