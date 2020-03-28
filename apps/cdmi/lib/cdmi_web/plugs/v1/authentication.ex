defmodule CdmiWeb.Plugs.V1.Authentication do
  @moduledoc """
  Handle user authentication.
  """

  import Plug.Conn
  import Phoenix.Controller
  use CdmiWeb.Util.ControllerCommon

  alias Cdmi.Authenticate

  require Logger

  def init(opts) do
    opts
  end

  @doc """
  Document the authenticate function
  """
  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    Logger.debug("Authentication plug. Conn: #{inspect(conn, pretty: true)}")
    auth = get_req_header(conn, "authorization")

    case auth do
      [] ->
        authentication_failed(conn, "Basic")

      _ ->
        [method, authstring] = String.split(List.to_string(auth))
        authstring = Base.decode64!(authstring)

        case method do
          "Basic" ->
            Logger.debug("doing basic authentication")
            {user, privileges} = basic_authentication(conn, authstring)
            Logger.debug("Authentication result: #{inspect(user)}")

            if user == :unauthorized do
              authentication_failed(conn, method)
            else
              conn
              |> assign(:authenticated_as, user)
              |> assign(:cdmi_member_privileges, privileges)
            end

          _ ->
            authentication_failed(conn, method)
        end
    end
  end

  @spec authentication_failed(map, String.t()) :: map
  defp authentication_failed(conn, method) do
    request_fail(conn, :unauthorized, "Unauthorized", [{"WWW-Authenticate", method}])
  end

  @spec basic_authentication(Plug.Conn.t(), String.t()) ::
          {String.t(), String.t()} | {:unauthorized, nil}
  defp basic_authentication(conn, authstring) do
    domain = conn.assigns.cdmi_domain
    [user_name, rest] = String.split(authstring, ":")
    [password | _] = String.split(rest, ";")
    Logger.debug("password is #{inspect(password)}")
    Logger.debug("user is #{inspect(user_name)}")
    Logger.debug("domain is #{inspect(domain)}")
    Authenticate.authenticate_user_and_domain(conn, user_name, password, domain)
  end


end
