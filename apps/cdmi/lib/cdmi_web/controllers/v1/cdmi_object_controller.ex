defmodule CdmiWeb.V1.CdmiObjectController do
  @moduledoc """
  Handle cdmi_object resources
  """
  @metadata_client Application.get_env(:cdmi, :metadatabackend)
  use CdmiWeb, :controller
  use CdmiWeb.Util.ControllerCommon
  import CdmiWeb.Util.Constants, only: [capabilities_object: 0]

  alias CdmiWeb.Util.Constants
  require Logger

  @capabilities_object Constants.capabilities_object()

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"cdmi_object" => object}) do
    handle_create(conn, object)
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    Logger.debug("Deleting a CDMI object with id #{inspect(id)}")
    handle_delete(conn, @metadata_client.get(conn.assigns.metadata_backend, id))
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    handle_show(conn, @metadata_client.get(conn.assigns.metadata_backend, id))
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"id" => id}) do
    handle_update(conn, @metadata_client.get(conn.assigns.metadata_backend, id))
  end

  @spec handle_create(Plug.Conn.t(), {atom, map}) :: Plug.Conn.t()
  defp handle_create(conn, {:ok, %{objectType: @capabilities_object}}) do
    conn
    |> request_fail(:bad_request, "Cannot create new capabilities")
  end
  defp handle_create(conn, _data) do
    conn
    |> request_fail(:bad_request, "not implemented")
  end

  @spec handle_delete(Plug.Conn.t(), {atom, map}) :: Plug.Conn.t()
  defp handle_delete(conn, {:ok, data}) do
    Logger.debug("In handle_delete")
    handle_delete_object(conn, data)
  end

  defp handle_delete(conn, {:not_found, _}) do
    request_fail(conn, :not_found, "Not found")
  end

  defp handle_delete(conn, {rc, data}) do
    Logger.debug("RC: #{inspect rc} Data: #{inspect data}")
    request_fail(conn, :rc, "Bad Request")
  end

  @spec handle_delete_object(Plug.Conn.t(), map) :: Plug.Conn.t()
  defp handle_delete_object(conn, %{objectType: @capabilities_object}) do
    Logger.debug("In handle_delete object 1")
    conn
    |> request_fail(:bad_request, "Capabilities are immutable")
  end

  defp handle_delete_object(conn, data) do
    Logger.debug("In handle_delete object2")
    Logger.debug("Conn: #{inspect conn, pretty: true}")
    Logger.debug("Data: #{inspect data, pretty: true}")
    conn2 =
      conn
      |> get_parent()
      |> check_capabilities(:cdmi_object, conn.method)
      |> check_acls()
      |> delete_object()
      |> update_parent(conn.method)

    if not conn2.halted do
      conn
      |> put_status(:no_content)
      |> json(nil)
    else
      conn2
    end
  end

  @spec handle_show(Plug.Conn.t(), {atom, map}) :: Plug.Conn.t()
  defp handle_show(conn, {:ok, data}) do
    handle_show_object(conn, data)
  end

  defp handle_show(conn, {:not_found, _}) do
    request_fail(conn, :not_found, "Not found")
  end

  defp handle_show(conn, {rc, data}) do
    Logger.debug("RC: #{inspect rc} Data: #{inspect data}")
    request_fail(conn, :rc, "Bad Request")
  end

  @spec handle_show_object(Plug.Conn.t(), map) :: Plug.Conn.t()
  defp handle_show_object(conn, data) do
    set_mandatory_response_headers(conn, data.objectType)
    data = process_query_string(conn, data)
    conn
    |> put_status(:ok)
    |> render("show.json", cdmi_object: data)
  end

  @spec handle_update(Plug.Conn.t(), {atom, map}) :: Plug.Conn.t()
  defp handle_update(conn, {:ok, data}) do
    handle_update_object(conn, data)
  end

  defp handle_update(conn, {:not_found, _}) do
    request_fail(conn, :not_found, "Not found")
  end

  defp handle_update(conn, {rc, data}) do
    Logger.debug("RC: #{inspect rc} Data: #{inspect data}")
    request_fail(conn, :rc, "Bad Request")
  end

  @spec handle_update_object(Plug.Conn.t(), map) :: Plug.Conn.t()
  defp handle_update_object(conn, %{objectType: @capabilities_object}) do
    conn
    |> request_fail(:bad_request, "Capabilities are immutable")
  end

end
