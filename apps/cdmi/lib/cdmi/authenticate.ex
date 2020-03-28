defmodule Cdmi.Authenticate do

  alias CdmiWeb.Util.MetadataBackend
  alias CdmiWeb.Util.Utils
  require Logger

  @spec authenticate_user_and_domain(Plug.Conn.t(), String.t(), String.t(), String.t()) ::
    {String.t(), String.t()} | {:unauthorized, nil}
  def authenticate_user_and_domain(conn, user_name, password, domain) do
    auth_string = "/cdmi_domains/" <> domain <> "cdmi_domain_members/" <> user_name
    case MetadataBackend.search(conn.assigns.metadata_backend, domain, auth_string) do
      {:ok, data} ->
        Logger.debug("Auth Data: #{inspect(data, pretty: true)}")
        creds = data.metadata.cdmi_member_credentials

        if creds == Utils.encrypt(user_name, password) do
          {user_name, data.metadata.cdmi_member_privileges}
        else
          {:unauthorized, nil}
        end

      {:not_found, _} ->
        {:unauthorized, nil}
    end
  end
end
