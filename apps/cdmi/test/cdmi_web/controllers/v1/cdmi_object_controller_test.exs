defmodule CdmiObjectControllerTest do
  use CdmiWeb.ConnCase

  import Mox
  import CdmiWeb.Util.Constants, only: [domain_object: 0]
  require Logger

  @endpoint CdmiWeb.V1.CdmiObjectController

  doctest Cdmi

  describe "CDMI object controller" do
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

      capabilities_object = %{
        capabilities: %{
          cdmi_acl: "true",
          cdmi_serialize_container: "false",
          cdmi_data_autodelete: "false",
          cdmi_RPO: "false",
          cdmi_export_container_cifs: "false",
          cdmi_move_container: "false",
          cdmi_export_container_webdav: "false",
          cdmi_data_retention: "false",
          cdmi_create_container: "true",
          cdmi_data_redundancy: "",
          cdmi_data_holds: "false",
          cdmi_delete_container: "true",
          cdmi_serialize_domain: "false",
          cdmi_mcount: "false",
          cdmi_infrastructure_redundancy: "",
          cdmi_move_dataobject: "false",
          cdmi_authentication_methods: ["anonymous", "basic"],
          cdmi_assignedsize: "false",
          cdmi_read_value: "false",
          cdmi_read_value_range: "false",
          cdmi_latency: "false",
          cdmi_RTO: "false",
          cdmi_mtime: "true",
          cdmi_encryption: [],
          cdmi_size: "true",
          cdmi_immediate_redundancy: "",
          cdmi_copy_container: "false",
          cdmi_list_children_range: "true",
          cdmi_security_access_control: "true",
          cdmi_create_dataobject: "true",
          cdmi_post_dataobject: "false",
          cdmi_post_queue: "false",
          cdmi_serialize_queue: "false",
          cdmi_export_container_iscsi: "false",
          cdmi_ctime: "true",
          cdmi_throughput: "false",
          cdmi_create_reference: "false",
          cdmi_read_metadata: "true",
          cdmi_serialize_dataobject: "false",
          cdmi_export_container_nfs: "false",
          cdmi_export_container_occi: "false",
          cdmi_create_queue: "false",
          cdmi_data_dispersion: "false",
          cdmi_list_children: "true",
          cdmi_value_hash: ["MD5", "RIPEMD160"],
          cdmi_acount: "false",
          cdmi_deserialize_dataobject: "false"
        },
        children: ["permanent/"],
        childrenrange: "0-0",
        objectID: "0000b0b900287cda2b7cea0c8c414078b27b51426ff36182",
        objectName: "container/",
        objectType: "application/cdmi-capability",
        parentID: "0000b0b90028838672f8af368c3b459ca4728681f1eb06ee",
        parentURI: "/cdmi_capabilities/"
      }

      root_container = %{
        completionStatus: "complete",
        objectName: "/",
        objectID: "0000b0b900282f513ac73be740a84d75876daded6d25cb52",
        capabilitiesURI: "/cdmi_capabilities/",
        domainURI: "/cdmi_domains/system_domain/",
        childrenrange: "0-2",
        objectType: "application/cdmi-container",
        children: [
          "cdmi_domains/",
          "system_configuration/",
          "cdmi_capabilities/"
        ],
        metadata: %{
          cdmi_ctime: "2019-10-30T21:25:20.000000Z",
          cdmi_owner: "administrator",
          cdmi_mtime: "2019-10-30T21:25:20.000000Z",
          cdmi_acl: [
            %{
              acetype: "0x00",
              identifier: "OWNER@",
              aceflags: "0x03",
              acemask: "0x1f07ff"
            },
            %{
              acetype: "0x00",
              identifier: "AUTHENTICATED@",
              aceflags: "0x03",
              acemask: "0x1F"
            }
          ],
          cdmi_atime: "2019-10-30T21:25:20.000000Z"
        }
      }

      %{
        capabilities_object: capabilities_object,
        domain_map: domain_map,
        default_domain: default_domain,
        disabled_domain: disabled_domain,
        enabled_domain: enabled_domain,
        root_container: root_container,
        system_domain: system_domain
      }
    end

    test "create capabilities object fails with bad request", %{
      capabilities_object: capabilities_object
    } do
      objectID = capabilities_object.objectID
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:ok, capabilities_object}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)

      conn2 = get(conn, :delete, id: objectID)
      |> json_response(400)
      assert %{"error" => "Capabilities are immutable"} == conn2
    end
    
    test "get capabilities object by object id", %{
      capabilities_object: capabilities_object
    } do
      objectID = capabilities_object.objectID
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:ok, capabilities_object}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)


      conn2 = get(conn, :show, id: objectID)
      assert 200 = conn2.status
      assert capabilities_object == conn2.assigns.cdmi_object
    end

    test "get by object id", %{
      root_container: root_container
    } do
      objectID = root_container.objectID
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:ok, root_container}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)


      conn2 = get(conn, :show, id: objectID)
      assert 200 = conn2.status
      assert root_container == conn2.assigns.cdmi_object
    end

    test "non-existant object" do
      objectID = "0000000000000000000000000000000000000000"
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:not_found, objectID}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)

      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)

      conn2 = get(conn, :show, id: objectID)
      |> json_response(404)
      assert %{"error" => "Not found"} == conn2
    end

    test "delete non-existant object" do
      objectID = "0000000000000000000000000000000000000000"
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:not_found, objectID}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)

      conn2 = get(conn, :delete, id: objectID)
      |> json_response(404)
      assert %{"error" => "Not found"} == conn2
    end

    test "delete capabilities object fails with bad request", %{
      capabilities_object: capabilities_object
    } do
      objectID = capabilities_object.objectID
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:ok, capabilities_object}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)

      conn2 = get(conn, :delete, id: objectID)
      |> json_response(400)
      assert %{"error" => "Capabilities are immutable"} == conn2
    end

    test "update non-existant object" do
      objectID = "0000000000000000000000000000000000000000"
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:not_found, objectID}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)

      conn2 = get(conn, :delete, id: objectID)
      |> json_response(404)
      assert %{"error" => "Not found"} == conn2
    end

    test "update capabilities object fails with bad request", %{
      capabilities_object: capabilities_object
    } do
      objectID = capabilities_object.objectID
      CdmiWeb.Util.MockMetadataBackend
      |> expect(:get, fn _module, _query ->
        {:ok, capabilities_object}
      end)

      system_domain = "system_domain/"
      user = "admin"
      pswd = "secret"
      auth_string = Base.encode64(user <> ":" <> pswd <> ";realm=" <> system_domain)
      conn =
        build_conn()
        |> assign(:metadata_backend, RiakMetadata)
        |> put_req_header("authorization", "Basic " <> auth_string)

      conn2 = get(conn, :delete, id: objectID)
      |> json_response(400)
      assert %{"error" => "Capabilities are immutable"} == conn2
    end
  end
end
