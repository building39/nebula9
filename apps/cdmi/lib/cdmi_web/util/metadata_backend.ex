defmodule CdmiWeb.Util.MetadataBackend do
  @moduledoc """
  Wrapper for the metadata backend module.

  """
  require Logger

  @spec available(atom()) :: :pong | :connection_pool_exhausted
  def available(metadata_backend) do
    GenServer.call(metadata_backend, {:available})
  end

  @spec delete(atom, String.t()) :: {:ok | :not_found, String.t()}
  def delete(metadata_backend, key) do
    GenServer.call(metadata_backend, {:delete, key})
  end

  @spec get(atom(), String.t()) :: {:ok | :not_found, map()}
  def get(metadata_backend, key) do
    Logger.debug("In CdmiWeb.Util.MetadataBackend.get")
    GenServer.call(metadata_backend, {:get, key})
  end

  @spec put(atom(), String.t(), map()) :: {:ok, map()} | {atom(), String.t()}
  def put(metadata_backend, key, data) do
    GenServer.call(metadata_backend, {:put, key, data})
  end

  @spec search(atom(), String.t(), String.t()) ::
          {:ok, map()} | {:not_found, String.t()} | {:multiples, term(), float()}
  def search(metadata_backend, domain, path) do
    GenServer.call(metadata_backend, {:search, domain, path})
  end

  @spec update(atom(), String.t(), map()) :: {:ok, map()} | {:not_found, String.t()}
  def update(metadata_backend, key, data) do
    GenServer.call(metadata_backend, {:update, key, data})
  end
end
