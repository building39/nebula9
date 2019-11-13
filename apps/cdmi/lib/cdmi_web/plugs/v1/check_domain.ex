defmodule CdmiWeb.Plugs.V1.CheckDomain do
  import Plug.Conn
  import Phoenix.Controller
  import CdmiWeb.Util.Constants
  import CdmiWeb.Util.Utils, only: [get_domain_hash: 1]
  use CdmiWeb.Util.ControllerCommon
  require Logger

  def init(opts) do
    opts
  end

  @doc """
  Document the Check Domain function
  """
  def call(conn, _opts) do
    data = conn.assigns.data

    if data.objectType == capabilities_object() do
      # Capability objects don't have a domain object
      conn
    else
      domain = conn.assigns.cdmi_domain
      domain_hash = get_domain_hash("/cdmi_domains/" <> domain)
      query = "sp:" <> domain_hash <> "/cdmi_domains/#{domain}"
      {rc, data} = GenServer.call(Metadata, {:search, query})

      if rc == :ok and data.objectType == domain_object() do
        if Map.get(data.metadata, :cdmi_domain_enabled, false) do
          conn
        else
          request_fail(conn, :forbidden, "Forbidden")
        end
      else
        request_fail(conn, :forbidden, "Forbidden")
      end
    end
  end
end
