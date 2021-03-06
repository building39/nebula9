defmodule CdmiWeb.Plugs.V1.MetadataBackend do
  @moduledoc """
  Sets the backend metadata application from the config.

  The default backend is Riak
  """
  import Plug.Conn
  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    Logger.debug("MetadataBackend plug")
    metadata_backend = Application.get_env(:cdmi, :metadata_backend, RiakMetadata)
    assign(conn, :metadata_backend, metadata_backend)
  end
end
