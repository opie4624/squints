defmodule Squints.Poller.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    table = :ets.new(:poller_timers, [:set, :public, :named_table])

    children = [
      worker(Squints.Poller.Worker, [%{table: table}], [name: Squints.Poller.Worker])
    ]

    opts = [strategy: :one_for_one, name: Squints.Poller.Supervisor]
    supervise(children, opts)
  end
end
