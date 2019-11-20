defmodule CdmiWeb.Util.MetadataBackend.Adapter do
  @callback available(metadata_backend :: atom()) :: :pong | :connection_pool_exhausted
  @callback delete(metadata_backend :: atom(), key :: String.t()) :: {:ok | :not_found, String.t()}
  @callback get(metadata_backend :: atom(), key :: String.t()) :: {:ok | :not_found, String.t()}
  @callback put(metadata_backend :: atom(), key :: String.t(), data :: map()) :: {:ok, map()} | {atom(), String.t}
  @callback search(metadata_backend :: atom(), domain :: String.t(), path :: String.t()) :: {:ok, map()} | {:not_found, String.t} | {:multiples, term(), float()}
  @callback update(metadata_backend :: atom(), key :: String.t(), data :: map()) :: {:ok, map()} | {:not_found, String.t()}
end
