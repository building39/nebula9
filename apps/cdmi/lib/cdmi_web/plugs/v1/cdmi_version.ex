defmodule CdmiWeb.Plugs.V1.CDMIVersion do
  @moduledoc """
  Check the X-CDMI-Specification-Version request header.
  """

  import Plug.Conn
  import Phoenix.Controller
  import CdmiWeb.Util.Constants
  use CdmiWeb.Util.ControllerCommon
  require Logger

  def init(opts) do
    Logger.debug("CDMIVersion init")
    opts
  end

  @doc """
  Check the X-CDMI-Specification-Version header against the versions in config.
  """
  def call(conn, _opts) do
    Logger.debug("CDMIVersion plug")
    x_cdmi_header = get_req_header(conn, "x-cdmi-specification-version")
    server_versions = Enum.join(Application.get_env(:cdmi, :cdmi_versions), ",")
    conn = put_resp_header(conn, "x-cdmi-specification-version", server_versions)

    if length(x_cdmi_header) == 0 do
      request_fail(
        conn,
        :bad_request,
        "Bad Request: Must supply X-CDMI-Specification-Version header"
      )
    else
      client_cdmi_versions = MapSet.new(x_cdmi_header)
      server_cdmi_versions = MapSet.new(Application.get_env(:cdmi, :cdmi_versions))
      valid_versions = MapSet.intersection(client_cdmi_versions, server_cdmi_versions)

      if MapSet.size(valid_versions) > 0 do
        conn
      else
        request_fail(
          conn,
          :bad_request,
          "Bad Request: Supplied CDMI Specification Version not supported"
        )
      end
    end
  end
end
