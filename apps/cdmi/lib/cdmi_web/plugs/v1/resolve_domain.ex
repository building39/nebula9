defmodule CdmiWeb.Plugs.V1.ResolveDomain do
  @moduledoc """
  Resolve the user's domain.

  This only works with basic authentication at this time.
  The user may authenticate like:
    "user:password"
  or
    "user:password;realm=domain"

  In the first case, the domain will resolve to "default_domain/".
  In the second case, the domain specified will be used.
  In either case, the domain itself will be validated later in the
  "CheckDomain" plug.
  """
  @backend Application.get_env(:cdmi, :metadata_module)
  import Plug.Conn
  import Phoenix.Controller
  use CdmiWeb.Util.ControllerCommon
  require Logger

  def init(opts) do
    opts
  end

  @doc """

  """
  def call(conn, _opts) do
    Logger.debug("ResolveDomain plug")
    auth = get_req_header(conn, "authorization")

    resolve(conn, auth)
    |> validate()
  end

  @spec get_domain_from_realm_map(Plug.Conn.t()) :: String.t()
  defp get_domain_from_realm_map(conn) do
    {:ok, domain_maps} = @backend.search(conn.assigns.metadata_backend, "system_domain/", "/system_configuration/domain_maps")
    {:ok, domain_maps} = Jason.decode(domain_maps.value)

    {_, domain} =
      Enum.find(domain_maps, {"", "default_domain/"}, fn {k, _v} -> k == conn.host end)

    domain
  end

  @spec get_realm(list) :: String.t() | nil
  defp get_realm([]) do
    nil
  end

  defp get_realm([option | rest]) do
    if String.starts_with?(option, "realm=") do
      [_, domain] = String.split(option, "=")

      if String.ends_with?(domain, "/") do
        domain
      else
        domain <> "/"
      end
    else
      get_realm(rest)
    end
  end

  @spec resolve(Plug.Conn.t(), list()) :: Plug.Conn.t()
  defp resolve(conn, []) do
    request_fail(conn, :forbidden, "Forbidden")
  end

  defp resolve(conn, auth) do
    [method, authstring] = String.split(List.to_string(auth))
    authstring = Base.decode64!(authstring)

    domain =
      case method do
        "Basic" ->
          options =
            authstring
            |> String.split(";")
            |> List.last()
            |> String.split(",")

          domain = get_realm(options)

          if domain == nil do
            get_domain_from_realm_map(conn)
          else
            domain
          end
      end

    conn
    |> assign(:cdmi_domain, domain)
  end

  @spec validate(Plug.Conn.t()) :: Plug.Conn.t()
  defp validate(conn = %{status: 403}) do
    conn
  end

  defp validate(conn) do
    domain = conn.assigns.cdmi_domain
    {rc, data} = @backend.search(conn.assigns.metadata_backend, domain, "/cdmi_domains/#{domain}")

    if rc == :ok and data.objectType == domain_object() do
      if Map.get(data.metadata, :cdmi_domain_enabled, true) do
        conn
      else
        request_fail(conn, :forbidden, "Forbidden")
      end
    else
      request_fail(conn, :forbidden, "Forbidden")
    end
  end
end
