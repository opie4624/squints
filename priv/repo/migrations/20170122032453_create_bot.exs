defmodule Squints.Repo.Migrations.CreateBot do
  use Ecto.Migration

  def up do
    # Enable GiS extensions for PostgreSQL
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create table(:bots) do
      add :alive, :boolean, default: false, null: false

      timestamps()
    end

    # Add a field `loc` with type `geometry(Point,4326)`
    # This can store a "standard GPS" (epsg4326) coordinate pair {longitude,latitude}.
    execute "SELECT AddGeometryColumn ('bots','loc',4326,'POINT',2)"
    execute "CREATE INDEX loc_point_index on bots USING gist (loc)"
  end

  def down do
    drop table(:bots)
    execute "DROP EXTENSION IF EXISTS postgis"
  end
end
