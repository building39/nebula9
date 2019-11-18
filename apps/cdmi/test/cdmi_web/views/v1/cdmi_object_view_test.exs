defmodule CdmiWeb.V1.CdmiObjectViewTest do
  use ExUnit.Case, async: true
  require Logger

  test "cdmi object" do
    object = %{cdmi_object: %{data: "HelloWorld"}}
    rendered_view = CdmiWeb.V1.CdmiObjectView.render("cdmi_object.cdmic", object)
    Logger.debug("Rendered view: #{inspect(rendered_view)}")
  end
end
