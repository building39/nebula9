defmodule RiakMetadataTest do
  use ExUnit.Case, async: true
  import Mox
  require Logger

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
      RiakMetadata.Cache.flush()

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

      bucket_type = <<"cdmi">>
      bucket_name = <<"cdmi">>
      bucket = {bucket_type, bucket_name}

      state = %RiakMetadata.State{
        bucket_type: bucket_type,
        bucket_name: bucket_name,
        bucket: bucket,
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

    test("can delete object", %{
      expected_object: expected_object,
      riak_object: riak_object,
      sp: sp,
      state: state
    }) do
      find_counter = :counters.new(1, [])
      del_counter = :counters.new(1, [])
      put_counter = :counters.new(1, [])

      RiakMetadata.Riak.MockClient
      |> expect(:find, fn _bucket, _key ->
        :counters.add(find_counter, 1, 1)
        nil
      end)
      |> expect(:put, fn riak_object ->
        :counters.add(put_counter, 1, 1)
        riak_object
      end)
      |> expect(:delete, fn _bucket, _key ->
        :counters.add(del_counter, 1, 1)
        riak_object
      end)
      |> expect(:find, fn _bucket, _key ->
        :counters.add(find_counter, 1, 1)
        nil
      end)

      # put an object so we can then delete it.
      # this object will exist in the cache after the put, but not in riak,
      # as we have mocked out all riak calls.
      Logger.debug("PUT")

      assert RiakMetadata.Server.handle_call(
               {:put, expected_object.objectID, expected_object},
               self(),
               state
             ) ==
               {:reply, {:ok, expected_object}, state}

      cache = RiakMetadata.Cache.all()
      Logger.debug("Cache contents: #{inspect(cache)}")

      # test that we get back the object that the end user should see
      Logger.debug("DELETE 1")

      assert RiakMetadata.Server.handle_call({:delete, expected_object.objectID}, self(), state) ==
               {:reply, {:ok, expected_object.objectID}, state}

      cache = RiakMetadata.Cache.all()
      Logger.debug("Cache contents after delete: #{inspect(cache)}")

      # test that the object got cached
      assert RiakMetadata.Cache.get("sp:" <> sp) == nil
      assert RiakMetadata.Cache.get(expected_object.objectID) == nil

      # this test should get the data from the cache, and not invoke Riak.find
      Logger.debug("DELETE 2")

      assert RiakMetadata.Server.handle_call({:delete, expected_object.objectID}, self(), state) ==
               {:reply, {:not_found, expected_object.objectID}, state}

      assert 2 == :counters.get(find_counter, 1)
      assert 1 == :counters.get(del_counter, 1)
      assert 1 == :counters.get(put_counter, 1)
    end

    test("can get object", %{
      expected_object: expected_object,
      riak_object: riak_object,
      sp: sp,
      state: state
    }) do
      counter = :counters.new(1, [])

      RiakMetadata.Riak.MockClient
      |> expect(:find, fn _bucket, _key ->
        :counters.add(counter, 1, 1)
        IO.puts("First find")
        riak_object
      end)
      |> expect(:find, fn _bucket, _key ->
        :counters.add(counter, 1, 1)
        IO.puts("Second find")
        nil
      end)

      # test that we get back the object that the end user should see
      assert RiakMetadata.Server.handle_call({:get, expected_object.objectID}, self(), state) ==
               {:reply, {:ok, expected_object}, state}

      # test that the object got cached
      assert RiakMetadata.Cache.get("sp:" <> sp) == expected_object
      assert RiakMetadata.Cache.get(expected_object.objectID) == expected_object

      # this test should get the data from the cache, and not invoke Riak.find
      assert RiakMetadata.Server.handle_call({:get, expected_object.objectID}, self(), state) ==
               {:reply, {:ok, expected_object}, state}

      # this covers the not found case
      assert RiakMetadata.Cache.get("123456") == nil
      RiakMetadata.Cache.flush()

      assert RiakMetadata.Server.handle_call({:get, expected_object.objectID}, self(), state) ==
               {:reply, {:not_found, expected_object.objectID}, state}

      assert 2 == :counters.get(counter, 1)
    end

    test("can put object", %{
      expected_object: expected_object,
      sp: sp,
      state: state
    }) do
      find_counter = :counters.new(1, [])
      put_counter = :counters.new(1, [])

      RiakMetadata.Riak.MockClient
      |> expect(:find, fn _bucket, _key ->
        :counters.add(find_counter, 1, 1)
        nil
      end)
      |> expect(:put, fn riak_object ->
        :counters.add(put_counter, 1, 1)
        riak_object
      end)

      # test that we get back the object that the end user should see
      assert RiakMetadata.Server.handle_call(
               {:put, expected_object.objectID, expected_object},
               self(),
               state
             ) ==
               {:reply, {:ok, expected_object}, state}

      # test that the object got cached
      assert RiakMetadata.Cache.get("sp:" <> sp) == expected_object
      assert RiakMetadata.Cache.get(expected_object.objectID) == expected_object

      # this test should get the data from the cache, and not invoke Riak.find
      assert RiakMetadata.Server.handle_call({:get, expected_object.objectID}, self(), state) ==
               {:reply, {:ok, expected_object}, state}

      assert 1 == :counters.get(find_counter, 1)
      assert 1 == :counters.get(put_counter, 1)
    end
  end
end
