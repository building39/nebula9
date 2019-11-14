defmodule CdmiWeb.Util.UtilsTest do
  use ExUnit.Case, async: true
  require Logger

  test "string encryption" do
    assert "a02a25b0f24bfcab979ab0a6fec9e29a7a512e10" == CdmiWeb.Util.Utils.encrypt("a key", "a message")
  end

  test "get a domain hash" do
    "e1507bdb4c20f9162d49d02ab9e818d292cf0711" = CdmiWeb.Util.Utils.get_domain_hash("system_domain")
  end

  test "timestamp creation" do
    assert "2001-03-17T13:45:21.000000Z" == CdmiWeb.Util.Utils.make_timestamp()
  end

end
