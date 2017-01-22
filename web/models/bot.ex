defmodule Squints.Bot do
  use Squints.Web, :model

  import Geo.PostGIS

  schema "bots" do
    field :alive, :boolean, default: false
    field :loc, Geo.Point
    field :distance, :float, virtual: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:alive, :loc])
    |> validate_required([:alive, :loc])
  end

  def within(query, point, radius_in_m) do
    {lng, lat} = point.coordinates
    #from(bot in query, where: st_dwithin(bot.loc, ^point, ^radius_in_m)) # This should work! >:|
    from(bot in query, where: fragment("ST_DWithin(?::geography, ST_SetSRID(ST_MakePoint(?, ?), ?), ?)", bot.loc, ^lng, ^lat, ^point.srid, ^radius_in_m))
  end

  def order_by_nearest(query, point) do
    {lng, lat} = point.coordinates
    from(bot in query,
      order_by: fragment("? <-> ST_SetSRID(ST_MakePoint(?, ?), ?)",
      bot.loc, ^lng, ^lat, ^point.srid))
  end

  def select_with_distance(query, point) do
    from(bot in query,
      select: %{bot | distance: st_distance_sphere(bot.loc, ^point)})
  end
end
