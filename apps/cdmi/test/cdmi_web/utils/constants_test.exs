defmodule CdmiWeb.Util.ConstantsTest do
  use ExUnit.Case, async: true
  @api_prefix "/cdmi/v1/"
  @capabilities_object "application/cdmi-capability"
  @container_object "application/cdmi-container"
  @data_object "application/cdmi-object"
  @domain_object "application/cdmi-domain"
  @multipart_mixed "application/cdmi-domain"
  @container_capabilities_uri "/cdmi_capabilities/container/"
  @dataobject_capabilities_uri "/cdmi_capabilities/dataobject/"
  @domain_uri "/cdmi_domains/"
  @domain_capabilities_uri "/cdmi_capabilities/domain/"
  @system_capabilities_uri "/cdmi_capabilities/"
  @system_domain_uri "/cdmi_domains/system_domain/"
  @render_object_type [
    {@capabilities_object(), "cdmi_capabilities.json"},
    {@container_object(), "cdmi_container.json"},
    {@data_object(), "cdmi_object.json"},
    {@domain_object(), "cdmi_domain.json"}
  ]

  @enterprise_number 45241

  alias CdmiWeb.Util.Constants

  describe "constants" do
    test "api prefix" do
      assert @api_prefix == Constants.api_prefix()
    end

    test "capabilities object" do
      assert @capabilities_object == Constants.capabilities_object()
    end

    test "container object" do
      assert @container_object == Constants.container_object()
    end

    test "data object" do
      assert @data_object == Constants.data_object()
    end

    test "domain object" do
      assert @domain_object == Constants.domain_object()
    end

    test "multipart mixed" do
      assert @multipart_mixed == Constants.multipart_mixed()
    end

    test "container capabilities uri" do
      assert @container_capabilities_uri == Constants.container_capabilities_uri()
    end

    test "dataobject capabilities uri" do
      assert @dataobject_capabilities_uri == Constants.dataobject_capabilities_uri()
    end

    test "domain  uri" do
      assert @domain_uri == Constants.domain_uri()
    end

    test "domain capabilities uri" do
      assert @domain_capabilities_uri == Constants.domain_capabilities_uri()
    end

    test "system capabilities uri" do
      assert @system_capabilities_uri == Constants.system_capabilities_uri()
    end

    test "system domain uri" do
      assert @system_domain_uri == Constants.system_domain_uri()
    end

    test "render object type" do
      assert @render_object_type == Constants.render_object_type()
    end

    test "enterprise number" do
      assert @enterprise_number == Constants.enterprise_number()
    end
  end
end
