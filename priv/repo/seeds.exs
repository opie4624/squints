# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Squints.Repo.insert!(%Squints.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

bots = [
  %{alive: true, loc: %Geo.Point{coordinates: {-111.49018049199999, 40.669360211099999}, srid: 4326}},
  %{alive: false, loc: %Geo.Point{coordinates: {-73.971917, 40.765417}, srid: 4326}}
]

Enum.each(bots, fn(bot) ->
  Squints.Bot.changeset(%Squints.Bot{}, bot)
  |> Squints.Repo.insert!
end)
