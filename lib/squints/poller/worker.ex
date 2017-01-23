defmodule Squints.Poller.Worker do
  use GenServer

  import Ecto.Query

  alias Squints.Repo
  alias Squints.Bot

  require Logger

  # Client API

  def start_link(state, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(%{table: table}) do
    case :ets.lookup(table, :timers) do
      [] ->
        poll()
        {:ok, new_state(table, [])}
      [timers: timers] ->
        {:ok, new_state(table, timers)}
    end
  end

  def poll do
    GenServer.cast(__MODULE__, :poll)
  end

  def schedule_poll(delay) do
    GenServer.cast(__MODULE__, {:schedule, delay})
  end

  def get_timers do
    GenServer.call(__MODULE__, :get_timers)
  end

  def get_timers_raw do
    GenServer.call(__MODULE__, :get_timers_raw)
  end

  def clear_timers do
    GenServer.cast(__MODULE__, :clear_timers)
  end

  def kill_bots do
    GenServer.cast(__MODULE__, {:kill_bots, []})
  end

  # Server API

  def handle_call(:get_timers, _from, state) do
    %{timers: timers} = state
    timers_info = Enum.map(timers, fn(x) -> Process.read_timer(x) end)
    {:reply, timers_info, state}
  end

  def handle_call(:get_timers_raw, _from, state) do
    %{timers: timers} = state
    {:reply, timers, state}
  end

  def handle_cast(:poll, state) do
    do_poll()
    |> handle_json()

    {:noreply, state}
  end

  def handle_cast({:schedule, delay}, state) do
    new_timer = schedule(delay)

    {:noreply, new_state(state, new_timer)}
  end

  def handle_cast(:clear_timers, %{table: table, timers: timers}) do
    cancel_timers(timers)
    {:noreply, new_state(table, [])}
  end

  def handle_cast({:kill_bots, exceptions}, state) do
    kill_bots(exceptions)
    {:noreply, state}
  end

  def handle_info(:poll, state) do
    poll()

    {:noreply, state}
  end

  # Private API

  defp new_state(%{table: table, timers: timers}), do: new_state(table, timers)
  defp new_state(%{table: table, timers: timers}, new_timers),
    do: check_timers(%{table: table, timers: [new_timers|timers]})
  defp new_state(table, timers) do
    :ets.insert(table, timers: timers)
    %{table: table, timers: timers}
  end

  defp check_timers(table, timers), do: new_state(%{table: table, timers: check_timers(timers)})
  defp check_timers(%{table: table, timers: timers}), do: check_timers(table, timers)
  defp check_timers(timers) when is_list(timers) do
    Enum.filter(timers, fn(x) -> Process.read_timer(x) end)
  end

  defp schedule(0), do: schedule(Application.get_env(:squints, :default_delay, 60000))
  defp schedule(delay), do: Process.send_after(__MODULE__, :poll, delay)

  defp do_poll do
    location_url = Application.get_env(:squints, :location_url, "http://localhost/locations")
    %HTTPotion.Response{body: json, status_code: 200} =
      case Application.get_env(:squints, :referrer_url, :nil) do
        :nil ->
          HTTPotion.get(location_url)
        referrer_url ->
          HTTPotion.get(location_url, headers: [referrer: referrer_url])
      end

    Logger.debug(Time.utc_now)
    Logger.debug(json)

    Poison.decode(json)
  end

  defp handle_json({:ok, %{"coordinates" => coords, "countdown" => countdown}}) do
    schedule_poll(countdown)
    store_coordinates(coords)
  end

  defp store_coordinates([]), do: kill_bots([])
  defp store_coordinates(coords) when is_list(coords) do
    #kill_bots(coords)
    Enum.each(coords, fn(coord) -> store_coordinates(coord) end)
  end
  defp store_coordinates(%{"lat" => lat, "lng" => lng}) do
    coord = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
    entry = %{alive: true, loc: coord}
    query = Bot
    |> Bot.within(coord, Application.get_env(:squints, :fudge_factor))
    result =
      case Repo.one(query) do
        :nil -> %Bot{}
        bot -> bot
      end
      |> Bot.changeset(entry)
      |> Repo.insert_or_update

    Logger.debug(coord)
    Logger.debug("Ins/Upd: #{result}")
  end
  defp store_coordinates(coord) do
    Logger.error("Coordinate not in known format.")
    Logger.debug(Poison.encode!(coord))
  end

  # Eventually kill_bots(exceptions) will leave alive the exceptions
  defp kill_bots([]) do
    from(b in Bot, where: b.alive == true)
    |> Repo.update_all(set: [alive: false])
  end

  defp cancel_timers(timers) do
    Enum.each(timers, fn(x) -> Process.cancel_timer(x) end)
  end
end
