# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :squints,
  ecto_repos: [Squints.Repo]

config :squints,
  fudge_factor: 1,
  default_delay: 12,
  location_url: "https://spectacles.com/locations",
  referrer_url: "https://spectacles.com/map/"

# Configures the endpoint
config :squints, Squints.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "W0Gt6x4WfCde/GVSwvyw58LpDe15B6F7oPTSCvWscPhxL18M6m9m5KXh5N1Kq2ud",
  render_errors: [view: Squints.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Squints.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
