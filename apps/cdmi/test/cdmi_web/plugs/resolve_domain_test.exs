defmodule CdmiWeb.Plugs.ResolveDomainTest do
  use CdmiWeb.ConnCase, async: true

  import Mox
  import CdmiWeb.Util.Constants, only: [domain_object: 0]
  require Logger

  doctest Cdmi

  describe "resolve domain plug" do
    setup :set_mox_from_context
    setup :verify_on_exit!

    setup do
      system_domain = "system_domain/"
      default_domain = "default_domain/"

      domain_map =
        %{
          value: "{\"cdmi.localhost.net\": \"" <> system_domain <> "\", \"default.localhost.net\": \"" <> default_domain <> "\"}"
        }
      %{
        domain_map: domain_map,
        default_domain: default_domain,
        system_domain: system_domain
      }
    end

    test "resolve to default domain", %{domain_map: domain_map, default_domain: domain} do
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _query ->
          {:ok, domain_map}
        end)

      user = "guido"
      pswd = "pasta"
      auth_string = Base.encode64(user <> ":" <> pswd)

      conn = build_conn()
      |> assign(:metadata_backend, RiakMetadata)
      |> put_req_header("authorization", "Basic " <> auth_string)
      |> CdmiWeb.V1.ResolveDomain.call(%{})
      assert domain == conn.assigns.cdmi_domain
    end

    test "resolve to system domain", %{domain_map: domain_map, system_domain: domain} do

      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> domain)

      conn = build_conn()
      |> assign(:metadata_backend, RiakMetadata)
      |> put_req_header("authorization", "Basic " <> auth_string)
      |> CdmiWeb.V1.ResolveDomain.call(%{})

      assert domain == conn.assigns.cdmi_domain
    end

    test "ensure domain name ends with '/'", %{domain_map: domain_map, system_domain: domain} do

      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> "system_domain")

      conn = build_conn()
      |> assign(:metadata_backend, RiakMetadata)
      |> put_req_header("authorization", "Basic " <> auth_string)
      |> CdmiWeb.V1.ResolveDomain.call(%{})

      assert domain == conn.assigns.cdmi_domain
    end

    test "fail resolution if no auth string", %{domain_map: domain_map, system_domain: domain} do

      conn = build_conn()
      |> assign(:metadata_backend, RiakMetadata)
      |> CdmiWeb.V1.ResolveDomain.call(%{})

      assert true == conn.halted
      assert 403 == conn.status
    end
  end
end
