defmodule RiakMetadataTest do
  use ExUnit.Case
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

      search_results = {
        :search_results,
        [
          {"cdmi_idx",
           [
             {"score", "3.15948409999999979547e+00"},
             {"_yz_rb", "cdmi"},
             {"_yz_rt", "cdmi"},
             {"_yz_rk", "9d6d779c9db34df70000b0b90028a2c90a21964acf4d4143"},
             {"_yz_id", "1*cdmi*cdmi*9d6d779c9db34df70000b0b90028a2c90a21964acf4d4143*23"}
           ]}
        ],
        3.1594841480255127,
        1
      }

      search_results_not_found = {
        :search_results,
        [],
        0.0,
        0
      }

      search_results_dup_key = {
        :search_results,
        [],
        0.0,
        2
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
        search_results: search_results,
        search_results_dup_key: search_results_dup_key,
        search_results_not_found: search_results_not_found,
        sp: cdmi_object.sp,
        state: state
      }
    end

    test("bogus request") do
      assert RiakMetadata.Server.handle_call(:bogus, self(), %{}) ==
               {:reply, {:badrequest, :bogus}, %{}}
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
      assert RiakMetadata.Server.handle_call(
               {:put, expected_object.objectID, expected_object},
               self(),
               state
             ) ==
               {:reply, {:ok, expected_object}, state}

      # test that we get back the object that the end user should see
      assert RiakMetadata.Server.handle_call({:delete, expected_object.objectID}, self(), state) ==
               {:reply, {:ok, expected_object.objectID}, state}

      # test that the object got cached
      assert RiakMetadata.Cache.get("sp:" <> sp) == nil
      assert RiakMetadata.Cache.get(expected_object.objectID) == nil

      # this test should get the data from the cache, and not invoke Riak.find
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
        riak_object
      end)
      |> expect(:find, fn _bucket, _key ->
        :counters.add(counter, 1, 1)
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
      riak_object: riak_object,
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
      |> expect(:find, fn _bucket, _key ->
        :counters.add(find_counter, 1, 1)
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

      # try to put an object that's already there
      assert RiakMetadata.Server.handle_call(
               {:put, expected_object.objectID, expected_object},
               self(),
               state
             ) ==
               {:reply, {:dupkey, expected_object.objectID}, state}

      assert 2 == :counters.get(find_counter, 1)
      assert 1 == :counters.get(put_counter, 1)
    end

    test("can search for an object", %{
      expected_object: expected_object,
      riak_object: riak_object,
      search_results: search_results,
      search_results_dup_key: search_results_dup_key,
      search_results_not_found: search_results_not_found,
      state: state
    }) do
      find_counter = :counters.new(1, [])
      query_counter = :counters.new(1, [])

      RiakMetadata.Riak.MockClient
      |> expect(:query, fn _index, _query ->
        :counters.add(query_counter, 1, 1)
        {:ok, search_results}
      end)
      |> expect(:find, fn _bucket, _key ->
        :counters.add(find_counter, 1, 1)
        riak_object
      end)
      |> expect(:query, fn _index, _query ->
        :counters.add(query_counter, 1, 1)
        {:ok, search_results_not_found}
      end)
      |> expect(:query, fn _index, _query ->
        :counters.add(query_counter, 1, 1)
        {:ok, search_results_dup_key}
      end)

      # test that we get back the object that the end user searched for
      assert RiakMetadata.Server.handle_call(
               {:search,
                "system_domain/",
                "/system_configuration/domain_maps"},
               self(),
               state
             ) ==
               {:reply, {:ok, expected_object}, state}

      assert RiakMetadata.Cache.get(expected_object.objectID) == expected_object

      # test that we get a not found condition for a query on a non-existant object
      {:reply, {rc, data}, _} = assert RiakMetadata.Server.handle_call(
               {:search,
                "system/_domain/",
                "/system_configuration/domain_maps"},
               self(),
               state
              )
      Logger.debug("rc: #{inspect rc} Data: #{inspect data}")
      assert rc == :not_found

      # test for duplicate record found
      RiakMetadata.Cache.flush()
      assert RiakMetadata.Server.handle_call(
               {:search,
                "system_domain/",
                "/system_configuration/domain_maps"},
               self(),
               state
             ) ==
               {:reply, {:multiples, [], 2}, state}

      assert 3 == :counters.get(query_counter, 1)
      assert 1 == :counters.get(find_counter, 1)
    end

    test("can update object", %{
      expected_object: expected_object,
      riak_object: riak_object,
      state: state
    }) do
      find_counter = :counters.new(1, [])
      put_counter = :counters.new(1, [])
      new_object = Map.put(expected_object, :objectName, "new_name")

      {:ok, old_riak_data} = Jason.decode(riak_object.data, keys: :atoms)
      hash = RiakMetadata.Server.get_domain_hash(new_object.domainURI)
      query = "sp:" <> hash <> new_object.parentURI <> new_object.objectName

      {:ok, new_riak_data} =
        old_riak_data
        |> Map.put(:sp, query)
        |> Map.put(:data, new_object)
        |> Jason.encode()

      new_riak_object = Map.put(riak_object, :data, new_riak_data)

      RiakMetadata.Riak.MockClient
      |> expect(:put, fn _riak_object ->
        :counters.add(put_counter, 1, 1)
        new_riak_object
      end)
      |> expect(:find, fn _bucket, _key ->
        :counters.add(find_counter, 1, 1)
        nil
      end)

      # put an object so we can then update it.
      # this object will exist in the cache after the put, but not in riak,
      # as we have mocked out all riak calls.
      RiakMetadata.Cache.set(expected_object.objectID, expected_object)

      # test that we get back the object that the end user updated
      assert RiakMetadata.Server.handle_call(
               {:update, expected_object.objectID, new_object},
               self(),
               state
             ) ==
               {:reply, {:ok, new_object}, state}

      # test that the object got cached
      assert RiakMetadata.Cache.get(query) == new_object
      assert RiakMetadata.Cache.get(expected_object.objectID) == new_object

      # try to update a non-existing object
      assert RiakMetadata.Server.handle_call(
               {:update, "1234", new_object},
               self(),
               state
             ) ==
               {:reply, {:not_found, "1234"}, state}

      assert 1 == :counters.get(put_counter, 1)
      assert 1 == :counters.get(find_counter, 1)
    end
  end
end
