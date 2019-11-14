# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configures the endpoint
config :cdmi, CdmiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CsNP28bwK3bCyXmqn616NAAku+g9EhbeT0mpfuTMxh+vxx5Ek5XyTLa4m24XkoKP",
  render_errors: [view: CdmiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Cdmi.PubSub, adapter: Phoenix.PubSub.PG2],
  cdmi_versions: ["1.1", "1.1.1"]

# Configures Elixir's Logger
config :logger,
  format: "[$level] $message\n",
  metadata: [:file, :line],
  backends: [{LoggerFileBackend, :error_log},
             {LoggerFileBackend, :debug_log},
             :console]

config :logger, :debug_log,
  colors: [enabled: :true],
  path: "log/debug.log",
  level: :debug

config :logger, :error_log,
metadata: [:file, :line],
  path: "log/error.log",
  level: :error

config :logger, :info_log,
metadata: [:file, :line],
  path: "log/info.log",
  level: :error

config :pooler, pools:
  [
    [
      name: :riaklocal1,
      group: :riak,
      max_count: 10,
      init_count: 5,
      start_mfa: { Riak.Connection, :start_link, ['nebriak1.fuzzcat.loc', 8087] }
    ]
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Custom mime types
config :mime, :types, %{
      "application/cdmi-capability" => ["cdmia"],
      "application/cdmi-container" => ["cdmic"],
      "application/cdmi-domain" => ["cdmid"],
      "application/cdmi-object" => ["cdmio"],
      "application/cdmi-queue" => ["cdmiq"]
    }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
