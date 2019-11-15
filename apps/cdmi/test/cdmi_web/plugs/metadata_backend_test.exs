defmodule CdmiWeb.Plugs.MetadataBackendTest do
  use CdmiWeb.ConnCase

  describe "test the metadata backend plug" do
    test "default is riak" do
      Application.delete_env(:cdmi, :metadata_backend)
      conn = build_conn()
      |> CdmiWeb.Plugs.V1.MetadataBackend.call(%{})
      assert conn.assigns.metadata_backend == RiakMetadata
    end

    test "gets backend from application environment" do
      backend = MyBackend
      Application.put_env(:cdmi, :metadata_backend, backend)
      conn = build_conn()
      |> CdmiWeb.Plugs.V1.MetadataBackend.call(%{})
      assert conn.assigns.metadata_backend == backend
    end
  end
end
