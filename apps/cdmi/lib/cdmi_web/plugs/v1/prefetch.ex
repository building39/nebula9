defmodule CdmiWeb.Plugs.V1.Prefetch do
  import Plug.Conn
  import Phoenix.Controller
  import CdmiWeb.Util.Constants

  import CdmiWeb.Util.Utils, only: [get_domain_hash: 1]
  use CdmiWeb.Util.ControllerCommon
  require Logger

  @container_object container_object()

  def init(opts) do
    opts
  end

  @doc """
  Document the prefetch function
  """
  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    Logger.debug("Prefetch plug")
    Logger.debug("Prefetch: handle_object_get")
    ap = api_prefix()
    api_prefix = String.slice(ap, 0, String.length(ap) - 1)

    req_path =
      if String.starts_with?(conn.request_path, api_prefix) do
        t = String.replace_prefix(conn.request_path, api_prefix, "")

        if t == "" do
          "/"
        else
          t
        end
      else
        conn.request_path
      end

    Logger.debug(fn -> "req_path: #{inspect(req_path)}" end)
    domain = conn.assigns.cdmi_domain
    domain_hash = get_domain_hash("/cdmi_domains/" <> domain)
    Logger.debug("domain_hash: #{inspect(domain_hash)}")
    query = "sp:" <> domain_hash <> String.replace_prefix(req_path, "/api/v1", "")
    Logger.debug("query: #{inspect(query)}")
    {rc, data} = GenServer.call(Metadata, {:search, query})
    Logger.debug("rc: #{inspect(rc)} data: #{inspect(data)}")

    if rc == :ok do
      case data.objectType do
        @container_object ->
          if not String.ends_with?(conn.request_path, "/") do
            request_fail(conn, :moved_permanently, "Moved Permanently", [{"Location", req_path}])
          else
            assign_map = conn.assigns
            assign_map = Map.put_new(assign_map, :data, data)
            Map.put(conn, :assigns, assign_map)
          end

        _ ->
          assign_map = conn.assigns
          assign_map = Map.put_new(assign_map, :data, data)
          Map.put(conn, :assigns, assign_map)
      end
    else
      case conn.method do
        "DELETE" ->
          conn

        "GET" ->
          request_fail(conn, :not_found, "Not found 2")

        "PUT" ->
          conn

        "POST" ->
          conn

        _other ->
          Logger.error("Unhandled method: #{inspect(conn.method)}")
          conn
      end
    end
  end
end
