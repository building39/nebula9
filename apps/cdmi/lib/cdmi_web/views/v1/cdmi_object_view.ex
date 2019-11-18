defmodule CdmiWeb.V1.CdmiObjectView do
  use CdmiWeb, :view
  require Logger

  def render("cdmi_object.cdmic", %{cdmi_object: cdmi_object}) do
    cdmi_object
    # "{\"data\": \"Hello world\"}"
  end

  def render("cdmi_object.cdmio", %{cdmi_object: cdmi_object}) do
    cdmi_object
  end

  def render("show.json", %{cdmi_object: cdmi_object}) do
    cdmi_object
  end

  def render(_render_type, object) do
    Logger.debug("rendering something: #{inspect(object, pretty: true)}")
    object
  end
end
