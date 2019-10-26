defmodule RiakMetadataTest do
  use ExUnit.Case, async: true
  import Mox

  doctest RiakMetadata

  describe "test helper functions" do
    test "gets a domain hash" do
      assert RiakMetadata.Server.get_domain_hash("/cdmi_domains/system_domain/") ==
               "c8c17baf9a68a8dbc75b818b24269ebca06b0f31"
    end

    test "wraps an object" do
      object = %{objectName: "/test_object", parentURI: "/parent"}

      wrapped_object = %{
        cdmi: object,
        sp: "c8c17baf9a68a8dbc75b818b24269ebca06b0f31/parent/test_object"
      }

      assert RiakMetadata.Server.wrap_object(object) == wrapped_object
    end

    test "wraps the root object" do
      object = %{objectName: "/"}

      wrapped_object = %{
        cdmi: %{objectName: "/"},
        sp: "c8c17baf9a68a8dbc75b818b24269ebca06b0f31/"
      }

      assert RiakMetadata.Server.wrap_object(object) == wrapped_object
    end
  end

  describe("test server functions") do
    setup :set_mox_from_context
    setup :verify_on_exit!

    setup do
      # expected_object =
      #   {:ok,
      #    %{
      #      capabilitiesURI: "/cdmi_capabilities/dataobject/permanent/",
      #      completionStatus: "complete",
      #      domainURI: "/cdmi_domains/system_domain/",
      #      metadata: %{
      #        cdmi_: "84",
      #        cdmi_acl: [
      #          %{aceflags: "0x03", acemask: "0x1f07ff", acetype: "0x00", identifier: "OWNER@"},
      #          %{
      #            aceflags: "0x03",
      #            acemask: "0x1F",
      #            acetype: "0x00",
      #            identifier: "AUTHENTICATED@"
      #          },
      #          %{aceflags: "0x83", acemask: "0x1f07ff", acetype: "0x00", identifier: "OWNER@"},
      #          %{aceflags: "0x83", acemask: "0x1F", acetype: "0x00", identifier: "AUTHENTICATED@"}
      #        ],
      #        cdmi_atime: "2019-10-26T15:02:37.000000Z",
      #        cdmi_ctime: "2019-10-26T15:02:37.000000Z",
      #        cdmi_hash:
      #          "fc7a9ed10a97b0a041b4623275a1eeb8d600f6c56fd765963580bde40b1115c6f58ac7f2ce0688e4dfc053e268f107a25aec8182af3552cf8a9855bb285a99ee",
      #        cdmi_mtime: "2019-10-26T15:02:37.000000Z",
      #        cdmi_owner: "administrator"
      #      },
      #      objectID: "0000b0b900281a487e3d1279bdf74681a64412dcb6f893a4",
      #      objectName: "domain_maps",
      #      objectType: "application/cdmi-object",
      #      parentID: "0000b0b90028f0cf95b331546d4941dfadfc4b8dd36c62ba",
      #      parentURI: "/system_configuration/",
      #      value:
      #        "{\"cdmi.localhost.net\": \"system_domain/\", \"default.localhost.net\": \"default_domain/\"}",
      #      valuetransferencoding: "utf-8"
      #    }}

      riak_object = %Riak.Object{
        bucket: {"cdmi", "cdmi"},
        content_type: 'application/json',
        data:
          "{\"sp\":\"c8c17baf9a68a8dbc75b818b24269ebca06b0f31/system_configuration/domain_maps\",\"cdmi\":{\"valuetransferencoding\":\"utf-8\",\"value\":\"{\\\"cdmi.localhost.net\\\": \\\"system_domain/\\\", \\\"default.localhost.net\\\": \\\"default_domain/\\\"}\",\"parentURI\":\"/system_configuration/\",\"parentID\":\"0000b0b90028f0cf95b331546d4941dfadfc4b8dd36c62ba\",\"objectType\":\"application/cdmi-object\",\"objectName\":\"domain_maps\",\"objectID\":\"0000b0b900281a487e3d1279bdf74681a64412dcb6f893a4\",\"metadata\":{\"cdmi_owner\":\"administrator\",\"cdmi_mtime\":\"2019-10-26T15:02:37.000000Z\",\"cdmi_hash\":\"fc7a9ed10a97b0a041b4623275a1eeb8d600f6c56fd765963580bde40b1115c6f58ac7f2ce0688e4dfc053e268f107a25aec8182af3552cf8a9855bb285a99ee\",\"cdmi_ctime\":\"2019-10-26T15:02:37.000000Z\",\"cdmi_atime\":\"2019-10-26T15:02:37.000000Z\",\"cdmi_acl\":[{\"identifier\":\"OWNER@\",\"acetype\":\"0x00\",\"acemask\":\"0x1f07ff\",\"aceflags\":\"0x03\"},{\"identifier\":\"AUTHENTICATED@\",\"acetype\":\"0x00\",\"acemask\":\"0x1F\",\"aceflags\":\"0x03\"},{\"identifier\":\"OWNER@\",\"acetype\":\"0x00\",\"acemask\":\"0x1f07ff\",\"aceflags\":\"0x83\"},{\"identifier\":\"AUTHENTICATED@\",\"acetype\":\"0x00\",\"acemask\":\"0x1F\",\"aceflags\":\"0x83\"}],\"cdmi_\":\"84\"},\"domainURI\":\"/cdmi_domains/system_domain/\",\"completionStatus\":\"complete\",\"capabilitiesURI\":\"/cdmi_capabilities/dataobject/permanent/\"}}",
        key: "a64412dcb6f893a40000b0b900281a487e3d1279bdf74681",
        metadata:
          {:dict, 3, 16, 16, 8, 80, 48,
           {[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []},
           {{[], [], [], [], [], [], [], [], [], [],
             [
               [
                 "content-type",
                 97,
                 112,
                 112,
                 108,
                 105,
                 99,
                 97,
                 116,
                 105,
                 111,
                 110,
                 47,
                 106,
                 115,
                 111,
                 110
               ],
               [
                 "X-Riak-VTag",
                 55,
                 55,
                 75,
                 66,
                 112,
                 112,
                 57,
                 83,
                 65,
                 83,
                 66,
                 81,
                 86,
                 106,
                 75,
                 84,
                 89,
                 121,
                 106,
                 77,
                 97
               ]
             ], [], [], [["X-Riak-Last-Modified" | {1572, 102_159, 62211}]], [], []}}},
        type: "cdmi",
        vclock:
          <<107, 206, 97, 96, 96, 96, 204, 96, 202, 5, 82, 60, 19, 166, 37, 138, 196, 93, 251,
            182, 150, 129, 105, 70, 65, 6, 83, 34, 99, 30, 43, 3, 255, 29, 141, 235, 124, 89, 0>>
      }

      {:ok, cdmi_object} = Jason.decode(riak_object.data, keys: :atoms)
      # {:ok, sp} = Jason.decode(riak_object)
      state = %RiakMetadata.State{
        host: "localhost",
        port: 8888
      }

      %{
        expected_object: cdmi_object.cdmi,
        riak_object: riak_object,
        sp: cdmi_object.sp,
        state: state
      }
    end

    test("can ping") do
      RiakMetadata.Riak.MockClient
      |> expect(:ping, fn -> :pong end)

      assert RiakMetadata.Server.handle_call(:available, self(), %{}) == {:reply, :pong, %{}}
    end

    test("can get object", %{
      expected_object: expected_object,
      riak_object: riak_object,
      sp: sp,
      state: state
    }) do
      counter = :counters.new(1, [])

      RiakMetadata.Riak.MockClient
      |> expect(:find, fn bucket, key ->
        :counters.add(counter, 1, 1)
        riak_object
      end)

      # test that we get back the object that the end user should see
      assert RiakMetadata.Server.handle_call({:get, expected_object.objectID}, self(), state) ==
               {:reply, {:ok, expected_object}, state}

      # test that the object got cached
      assert RiakMetadata.Cache.get("sp:" <> sp) == expected_object

      # this test should get the data from the cache, and not invoke Riak.find
      assert RiakMetadata.Server.handle_call({:get, expected_object.objectID}, self(), state) ==
               {:reply, expected_object, state}

      assert 1 == :counters.get(counter, 1)
    end
  end
end
