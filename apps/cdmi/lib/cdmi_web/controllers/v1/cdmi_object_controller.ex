defmodule CdmiWeb.V1.CdmiObjectController do
  @moduledoc """
  Handle cdmi_object resources
  """
  @backend Application.get_env(:cdmi, :metadata_module)
  use CdmiWeb, :controller
  use CdmiWeb.Util.ControllerCommon

  require Logger

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    handle_show(conn, @backend.get(conn.assigns.metadata_backend, id))
  end

  @spec handle_show(Plug.Conn.t(), {atom, map}) :: Plug.Conn.t()
  defp handle_show(conn, {:ok, data}) do
    handle_show_object(conn, data)
  end

  defp handle_show(conn, {:not_found, _}) do
    request_fail(conn, :not_found, "Not found")
  end

  @spec handle_show_object(Plug.Conn.t(), map) :: Plug.Conn.t()
  defp handle_show_object(conn, data) do
    set_mandatory_response_headers(conn, data.objectType)
    data = process_query_string(conn, data)
    conn
    |> put_status(:ok)
    |> render("show.json", cdmi_object: data)
  end

end
