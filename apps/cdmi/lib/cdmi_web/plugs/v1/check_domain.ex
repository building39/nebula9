defmodule CdmiWeb.Plugs.V1.CheckDomain do
  @backend Application.get_env(:cdmi, :metadata_module)
  import Plug.Conn
  import Phoenix.Controller
  import CdmiWeb.Util.Constants
  use CdmiWeb.Util.ControllerCommon
  require Logger
  alias CdmiWeb.Util.MetadataBackend

  def init(opts) do
    Logger.debug("init: opts: #{inspect opts}")
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
end
