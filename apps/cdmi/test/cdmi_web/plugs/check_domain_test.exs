defmodule CdmiWeb.Plugs.CheckDomainTest do
  use CdmiWeb.ConnCase, async: true

  import Mox
  import CdmiWeb.Util.Constants, only: [domain_object: 0]
  require Logger

  doctest Cdmi

  describe "check domain plug" do
    setup :set_mox_from_context
    setup :verify_on_exit!

    setup do
      conn = build_conn()
      |> assign(:metadata_backend, RiakMetadata)
      |> assign(:cdmi_domain, "domain_name")

      enabled_domain =
        %{
           metadata: %{
             cdmi_domain_enabled: true
           },
           objectType: domain_object()
         }
      disabled_domain =
       %{
          metadata: %{
            cdmi_domain_enabled: false
          },
          objectType: domain_object()
        }

      %{
        conn: conn,
        enabled_domain: enabled_domain,
        disabled_domain: disabled_domain
      }
    end

    test "cdmi capabilities ignore domain", %{conn: conn} do
      conn = conn
      |> assign(:data, %{objectType: "application/cdmi-capability"})

      assert conn == CdmiWeb.Plugs.V1.CheckDomain.call(conn, %{})
      assert false == conn.halted
    end

    test "gets enabled domain", %{conn: conn, enabled_domain: domain} do
      conn = conn
      |> assign(:data, %{objectType: "application/cdmi-container"})

      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _query ->
          {:ok, domain}
        end)

      assert conn == CdmiWeb.Plugs.V1.CheckDomain.call(conn, %{})
      assert false == conn.halted
    end

    test "gets disabled domain", %{conn: conn, disabled_domain: domain} do
      conn = conn
      |> assign(:data, %{objectType: "application/cdmi-container"})

      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _query ->
          {:ok, domain}
        end)

      new_conn = CdmiWeb.Plugs.V1.CheckDomain.call(conn, %{})
      assert true == new_conn.halted
      assert 403 == new_conn.status
    end

    test "looks for a nonexistent domain", %{conn: conn, disabled_domain: domain} do
      conn = conn
      |> assign(:data, %{objectType: "application/cdmi-container"})

      CdmiWeb.Util.MockMetadataBackend
      |> expect(:search, fn _module, _query ->
          {:not_found, nil}
        end)

      new_conn = CdmiWeb.Plugs.V1.CheckDomain.call(conn, %{})
      assert true == new_conn.halted
      assert 403 == new_conn.status
    end

  end

end
