defmodule CdmiWeb.Plugs.V1.ApplyCapabilities do
  @moduledoc """
  Get the capabilities object for the current object.
  """

  import Plug.Conn
  import Phoenix.Controller
  import CdmiWeb.Util.Constants
  use CdmiWeb.Util.ControllerCommon
  require Logger

  def init(opts) do
    opts
  end

  @doc """
  Document this function
  """
  def call(conn = %{sys_capabilitiies: _s}) do
    Logger.debug("already got capabilities")
    conn
  end

  def call(conn, _opts) do
    Logger.debug("ApplyCapabilities plug")

    {rc, capabilities} = MetadataBackend.search(conn.assigns.metadata_backend, system_domain_uri(), system_capabilities_uri())

    case rc do
      :ok ->
        Logger.debug("assigning capabilities Conn: #{inspect(conn, pretty: true)}")
        c = assign(conn, :sys_capabilities, capabilities)
        Logger.debug("capabilities assigned Conn: #{inspect(conn, pretty: true)}")
        c

      _ ->
        Logger.debug("Capabilities NotFound")
        request_fail(conn, :not_found, "Not found 1")
    end
  end
end
