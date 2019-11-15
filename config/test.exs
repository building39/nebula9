
import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cdmi, CdmiWeb.Endpoint,
  http: [port: 4002],
  server: false

config :cdmi,
  metadata_module: CdmiWeb.Util.MockMetadataBackend,
  metadata_backend: RiakMetadata

config :riak_metadata, riak_client: RiakMetadata.Riak.MockClient

config :riak_metadata, RiakMetadata.Cache,
  gc_interval: 60 # 60 seconds
