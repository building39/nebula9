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

      domain_map = %{
        value:
          "{\"cdmi.localhost.net\": \"" <>
            system_domain <> "\", \"default.localhost.net\": \"" <> default_domain <> "\"}"
      }

      enabled_domain = %{
        metadata: %{
          cdmi_domain_enabled: true
        },
        objectType: domain_object()
      }

      disabled_domain = %{
        metadata: %{
          cdmi_domain_enabled: false
        },
        objectType: domain_object()
      }

      %{
        domain_map: domain_map,
        default_domain: default_domain,
        disabled_domain: disabled_domain,
        enabled_domain: enabled_domain,
        system_domain: system_domain
      }
    end

    test "resolve to default domain", %{
      domain_map: domain_map,
      default_domain: domain,
      enabled_domain: enabled_domain
    } do
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _domain, _path ->
        {:ok, domain_map}
      end)
      |> expect(:search, fn _module, _domain, _path ->
        {:ok, enabled_domain}
      end)

      user = "guido"
      pswd = "pasta"
      auth_string = Base.encode64(user <> ":" <> pswd)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert domain == conn.assigns.cdmi_domain
    end

    test "resolve to system domain", %{
      enabled_domain: enabled_domain,
      system_domain: domain
    } do
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _domain, _path ->
        {:ok, enabled_domain}
      end)

      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> domain)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert domain == conn.assigns.cdmi_domain
    end

    test "fail on disabled domain", %{
      disabled_domain: disabled_domain,
      system_domain: domain
    } do
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _domain, _path ->
        {:ok, disabled_domain}
      end)

      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> domain)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert true == conn.halted
      assert 403 == conn.status
    end

    test "fail on nonexistant domain", %{
      system_domain: domain
    } do
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _domain, _path ->
        {:not_found, nil}
      end)

      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> domain)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert true == conn.halted
      assert 403 == conn.status
    end

    test "fail on no authorization" do
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert true == conn.halted
      assert 403 == conn.status
    end

    test "ensure domain name ends with '/'", %{
      enabled_domain: enabled_domain,
      system_domain: domain
    } do
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _domain, _path ->
        {:ok, enabled_domain}
      end)

      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> "system_domain")

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert domain == conn.assigns.cdmi_domain
    end

    test "fail resolution if no auth string", %{} do
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> CdmiWeb.Plugs.V1.ResolveDomain.call(%{})

      assert true == conn.halted
      assert 403 == conn.status
    end
  end
end
