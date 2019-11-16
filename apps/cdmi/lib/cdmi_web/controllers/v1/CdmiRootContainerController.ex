defmodule CdmiWeb.V1.CdmiRootContainerController do
  @moduledoc """
  Handle the root container
  """

  use CdmiWeb, :controller
  use CdmiWeb.Util.ControllerCommon
  import CdmiWeb.Util.Constants
  @api_prefix api_prefix()
  @capabilities_object capabilities_object()
  @container_object container_object()
  require Logger

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, _args) do
    Logger.debug("Showing the root container")
    Logger.debug("domain: #{inspect(conn.assigns.cdmi_domain)}")
    domain_hash = get_domain_hash(domain_uri() <> conn.assigns.cdmi_domain)
    Logger.debug("Domain hash: #{inspect(domain_hash)}")
    query = "sp:" <> domain_hash <> "/"
    {rc, data} = MetadataBackend.search(conn.assigns.metadata_backend, query)
    Logger.debug("Search returned rc: #{inspect(rc)} data: #{inspect(data, pretty: true)}")

    case rc do
      :ok ->
        conn
        |> put_status(:ok)
        |> render("show.json", cdmi_object: data)

      :not_found ->
        request_fail(conn, :not_found, "Not Found")

      other ->
        request_fail(conn, :bad_request, other)
    end
  end
end
