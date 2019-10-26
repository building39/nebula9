defmodule RiakMetadata.Riak.Adapter do
  @callback ping() :: :pong | :connection_pool_exhausted
  @callback delete(bucket :: tuple(), key :: String.t()) :: term()
  @callback find(bucket :: tuple(), key :: String.t()) :: term()
  @callback put(obj :: term()) :: term()
end
