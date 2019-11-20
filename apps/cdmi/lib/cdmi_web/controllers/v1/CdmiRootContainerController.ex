defmodule CdmiWeb.V1.CdmiRootContainerController do
  @moduledoc """
  Handle the root container
  """

  use CdmiWeb, :controller
  use CdmiWeb.Util.ControllerCommon

  require Logger

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, _args) do
    conn
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, _args) do
    Logger.debug("Showing the root container")
    {rc, data} = MetadataBackend.search(conn.assigns.metadata_backend, conn.assigns.cdmi_domain, "/")
    Logger.debug("Search returned rc: #{inspect(rc)} data: #{inspect(data, pretty: true)}")

    case rc do
      :ok ->
        conn
        |> put_status(:ok)
        |> render("show.json", cdmi_object: data)

      :not_found ->
        request_fail(conn, :not_found, "Not Found")

    end
  end
end
