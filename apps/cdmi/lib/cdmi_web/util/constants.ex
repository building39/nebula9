defmodule CdmiWeb.Util.Constants do
  @moduledoc """
  Define system-wide constants here.
  """

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
  @system_domain "system_domain/"
  @system_capabilities_uri "/cdmi_capabilities/"
  @system_domain_uri "/cdmi_domains/system_domain/"
  @render_object_type [
    {@capabilities_object(), "cdmi_capabilities.json"},
    {@container_object(), "cdmi_container.json"},
    {@data_object(), "cdmi_object.json"},
    {@domain_object(), "cdmi_domain.json"}
  ]

  @enterprise_number 45241

  def api_prefix() do
    @api_prefix
  end

  def capabilities_object() do
    @capabilities_object
  end

  def container_object() do
    @container_object
  end

  def data_object() do
    @data_object
  end

  def domain_object() do
    @domain_object
  end

  def enterprise_number() do
    @enterprise_number
  end

  def multipart_mixed() do
    @multipart_mixed
  end

  def container_capabilities_uri() do
    @container_capabilities_uri
  end

  def dataobject_capabilities_uri() do
    @dataobject_capabilities_uri
  end

  def domain_uri() do
    @domain_uri
  end

  def domain_capabilities_uri() do
    @domain_capabilities_uri
  end

  def system_capabilities_uri() do
    @system_capabilities_uri
  end

  def system_domain() do
    @system_domain
  end

  def system_domain_uri() do
    @system_domain_uri
  end

  def render_object_type() do
    @render_object_type
  end
end
