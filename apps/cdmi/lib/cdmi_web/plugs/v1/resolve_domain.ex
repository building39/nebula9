defmodule CdmiWeb.V1.ResolveDomain do
  @moduledoc """
  Resolve the user's domain.
  """

  import Plug.Conn
  import Phoenix.Controller
  use CdmiWeb.Util.ControllerCommon
  require Logger

  def init(opts) do
    opts
  end

  @doc """
  Right now, everything lives in the system domain.
  User domains will be implemented later.
  """
  def call(conn, _opts) do
    Logger.debug("ResolveDomain plug")
    auth = get_req_header(conn, "authorization")
    Logger.debug("Auth header: #{inspect(auth)}")
    # if Enum.member?(["cdmi_domains", "/"], Enum.at(conn.path_info, 2)) do
    #   conn
    #   |> assign(:cdmi_domain, "system_domain/")
    # else
    new_conn =
      case auth do
        [] ->
          Logger.debug("What are we doing here?")
          conn
          |> assign(:cdmi_domain, "system_domain/")

        x ->
          Logger.debug("AUTH: #{inspect x}")
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

                Logger.debug("XYZ options: #{inspect(options)}")
                domain = get_realm(options)
                Logger.debug("Resolved domain: #{inspect(domain)}")

                if domain == nil do
                  get_domain_from_realm_map(conn)
                else
                  domain
                end
            end

          conn
          |> assign(:cdmi_domain, domain)
      end

    Logger.debug("Domain resolved to: #{inspect(new_conn, pretty: true)}")
    new_conn
    # end
  end

  @spec get_domain_from_realm_map(Plug.Conn.t()) :: String.t()
  defp get_domain_from_realm_map(conn) do
    # TODO: handle the realm map
    domain_hash = get_domain_hash("/cdmi_domains/system_domain/")
    query = "sp:" <> domain_hash <> "/system_configuration/domain_maps"
    {:ok, domain_maps} = GenServer.call(Metadata, {:search, query})
    {:ok, domain_maps} = Jason.decode(domain_maps.value)
    {_, domain} = Enum.find(domain_maps, {"", "default_domain/"}, fn {k, _v} -> k == conn.host end)
    Logger.debug("domain map: #{inspect domain_maps, pretty: true}")
    Logger.debug("Got this domain: #{inspect domain}")
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
end
