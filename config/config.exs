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

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

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

  # Import environment specific config. This must remain at the bottom
  # of this file so it overrides the configuration defined above.
  import_config "#{Mix.env}.exs"
