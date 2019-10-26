import Config

config :riak_metadata, riak_client: RiakMetadata.Riak.Client

config :riak_metadata, RiakMetadata.Cache,
  gc_interval: 60 # 60 seconds
