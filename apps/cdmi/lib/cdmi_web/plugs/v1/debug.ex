defmodule CdmiWeb.Plugs.V1.Debug do
  @moduledoc """
  Check the X-CDMI-Specification-Version request header.
  """
  require Logger

  @spec init(map()) :: map()
  def init(opts) do
    Logger.debug("Plug Debug init")
    opts
  end

  @doc """
  Check the X-CDMI-Specification-Version header against the versions in config.
  """
  @spec call(Plug.Conn.t, map()) :: Plug.Conn.t()
  def call(conn, _opts) do
    Logger.debug("Debug plug. CONN: #{inspect conn, pretty: true}")
    conn
  end
end
