defmodule CdmiWeb.Plugs.CdmiVersionTest do
  use CdmiWeb.ConnCase
  require Logger

  doctest Cdmi

  describe "test for cdmi version validation" do
    test "fails when header not present" do
      Application.put_env(:cdmi, :cdmi_versions, ["1.1", "1.1.1"])
      conn = build_conn()
      |> CdmiWeb.Plugs.V1.CDMIVersion.call(%{})

      assert 400 == conn.status
      assert true == conn.halted
    end

    test "fails for unsupported cdmi version" do
      Application.put_env(:cdmi, :cdmi_versions, ["1.1", "1.1.1"])
      conn = build_conn()
      |> Map.put(:req_headers, [{"x-cdmi-specification-version", "2.1.1"}])
      |> CdmiWeb.Plugs.V1.CDMIVersion.call(%{})

      assert 400 == conn.status
      assert true == conn.halted
    end

    test "suceeds for supported cdmi version" do
      Application.put_env(:cdmi, :cdmi_versions, ["1.1", "1.1.1"])
      conn = build_conn()
      |> Map.put(:req_headers, [{"x-cdmi-specification-version", "1.1.1"}])
      |> CdmiWeb.Plugs.V1.CDMIVersion.call(%{})

      assert nil == conn.status
      assert false == conn.halted
    end

  end

end
