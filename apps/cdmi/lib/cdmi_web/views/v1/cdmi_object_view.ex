defmodule CdmiWeb.V1.CdmiObjectView do
  use CdmiWeb, :view
  require Logger

  def render("cdmi_object.cdmic", %{cdmi_object: cdmi_object}) do
    Logger.debug("container view cdmi: #{inspect(cdmi_object, pretty: true)}")
    cdmi_object
    # "{\"data\": \"Hello world\"}"
  end

  def render("cdmi_object.cdmio", %{cdmi_object: cdmi_object}) do
    Logger.debug("object view cdmio: #{inspect(cdmi_object, pretty: true)}")
    cdmi_object
  end

  def render("show.json", %{cdmi_object: cdmi_object}) do
    Logger.debug("object view cdmio: #{inspect(cdmi_object, pretty: true)}")
    cdmi_object
  end

  def render(_render_type, object) do
    Logger.debug("rendering something: #{inspect(object, pretty: true)}")
    object
  end
end
