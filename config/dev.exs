import Config

config :riak_metadata, riak_client: RiakMetadata.Riak.Client

config :riak_metadata, RiakMetadata.Cache,
  gc_interval: 60 # 60 seconds

config :cdmi, CdmiWeb.Endpoint,
  http: [port: 4000],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :cdmi,
  cdmi_versions: ["1.1", "1.1.1"]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
