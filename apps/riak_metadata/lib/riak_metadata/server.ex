defmodule RiakMetadata.Server do
  @riak_client Application.get_env(:riak_metadata, :riak_client)
  @compile if Mix.env() == :test, do: :export_all

  use GenServer
  require Logger
  import RiakMetadata.State

  def start_link(state) do
    GenServer.start_link(__MODULE__, [state], name: Metadata)
  end

  def init([state]) do
    {:ok, state}
  end

  def handle_call(:available, _from, state) do
    {:reply, available(), state}
  end

  def handle_call({:delete, key}, _from, state) do
    Logger.debug("handle_call: :delete")
    {:reply, delete(key, state), state}
  end

  def handle_call({:get, key}, _from, state) do
    Logger.debug("handle_call: :get")
    obj = get(key, state)
    {:reply, obj, state}
  end

  def handle_call({:put, key, data}, _from, state) do
    Logger.debug("handle_call: :put")
    {:reply, put(key, data, state), state}
  end

  def handle_call({:search, query}, _from, state) do
    Logger.debug("handle_call: :search")
    s = search(query, state)
    Logger.debug("Search returned: #{inspect(s, pretty: true)}")
    {:reply, s, state}
    # {:reply, search(query, state), state}
  end

  def handle_call({:update, key, data}, _from, state) do
    Logger.debug("handle_call: :update")
    {:reply, update(key, data, state), state}
  end

  def handle_call(request, _from, state) do
    Logger.debug("handle_call: unknown request: #{inspect(request)}")
    {:reply, {:badrequest, request}, state}
  end

  @spec available() :: atom()
  defp available() do
    @riak_client.ping()
  end

  @spec delete(String.t(), map()) :: map()
  defp delete(id, state) do
    Logger.debug("Deleting #{inspect(id)}")
    {rc, obj} = get(id, state)

    case rc do
      :ok ->
        Logger.debug("Found the bastard")
        RiakMetadata.Cache.delete(id)
        hash = get_domain_hash(obj.domainURI)
        query = "sp:" <> hash <> obj.parentURI <> obj.objectName
        x = RiakMetadata.Cache.delete(query)
        x2 = RiakMetadata.Cache.delete(id)
        Logger.debug("Cache delete 1 #{inspect(x)}")
        Logger.debug("Cache delete 2 #{inspect(x2)}")
        # key (id) needs to be reversed for Riak datastore.
        key = String.slice(id, -16..-1) <> String.slice(id, 0..31)
        @riak_client.delete(state.bucket, key)
        {:ok, id}

      other ->
        Logger.debug("Get for delete failed: #{inspect(other)}")
        {:not_found, id}
    end
  end

  @spec get(String.t(), map(), boolean()) :: {atom(), map()}
  defp get(id, state, flip \\ true) do
    Logger.debug("metadata get key #{inspect(id)}")
    response = RiakMetadata.Cache.get(id)
    Logger.debug("Cache get returned #{inspect(response)}")

    case response do
      nil ->
        key =
          if flip do
            # key (id) needs to be reversed for Riak datastore.
            String.slice(id, -16..-1) <> String.slice(id, 0..31)
          else
            id
          end

        Logger.debug("Finding key #{inspect(key)}")
        obj = @riak_client.find(state.bucket, key)
        Logger.debug("riak find returned #{inspect(obj)}")

        case obj do
          nil ->
            Logger.debug("Get not found")
            {:not_found, id}

          other ->
            Logger.debug("get found this bastard: #{inspect(other)}")
            {:ok, data} = Jason.decode(obj.data, keys: :atoms)
            RiakMetadata.Cache.set("sp:" <> data.sp, data.cdmi)
            RiakMetadata.Cache.set(data.cdmi.objectID, data.cdmi)

            {:ok, data.cdmi}
        end

      obj ->
        Logger.debug("Got a cache hit")
        {:ok, obj}
    end
  end

  @spec put(String.t(), map(), map()) :: tuple()
  defp put(id, data, state) when is_map(data) do
    # key (id) needs to be reversed for Riak datastore.
    key = String.slice(id, -16..-1) <> String.slice(id, 0..31)
    wrapped_data = wrap_object(data)
    {:ok, stringdata} = Jason.encode(wrapped_data)
    {rc, new_data} = put(key, stringdata, state)

    if rc == :ok do
      RiakMetadata.Cache.set(id, new_data.cdmi)
      RiakMetadata.Cache.set("sp:" <> new_data.sp, new_data.cdmi)
    else
      Logger.debug("PUT failed: #{inspect(rc)}")
    end

    {rc, new_data.cdmi}
  end

  @spec put(String.t(), String.t(), map()) :: {:ok | :dupkey, any(), any()}
  defp put(key, data, state) when is_binary(data) do
    obj = @riak_client.find(state.bucket, key)
    Logger.debug("put find returned #{inspect(obj)}")

    case obj do
      nil ->
        # this call will return a riak object.
        ro = @riak_client.put(Riak.Object.create(bucket: state.bucket, key: key, data: data))
        Jason.decode(ro.data, keys: :atoms)

      error ->
        Logger.debug("PUT find failed: #{inspect(error)}")
        {:dupkey, key, data}
    end
  end

  @spec search(String.t(), map()) :: {atom(), map()}
  defp search(query, state) do
    Logger.debug("Searching for #{inspect(query)}")
    response = RiakMetadata.Cache.get(query)

    case response.status do
      :ok ->
        obj = :erlang.binary_to_term(response.value)
        {:ok, obj}

      _status ->
        Logger.debug("Cache miss")

        {:ok, {:search_results, results, _score, count}} =
          @riak_client.query(state.cdmi_index, query)

        case count do
          1 ->
            {:ok, data} = get_data(results, state)
            Logger.debug(fn -> "got data: #{inspect(data)}" end)
            RiakMetadata.Cache.set(query, data)
            RiakMetadata.Cache.set(data.objectID, data)
            {:ok, data}

          0 ->
            Logger.debug("Search not found: #{inspect(query)}")
            {:not_found, query}

          _ ->
            Logger.debug("Multiple results found")
            {:multiples, results, count}
        end
    end
  end

  @spec get_data(list(), map()) :: {atom(), map()}
  defp get_data(results, state) do
    {_, rlist} = List.keyfind(results, state.cdmi_index, 0)
    {_, key} = List.keyfind(rlist, "_yz_rk", 0)
    get(key, state, false)
  end

  @spec update(String.t(), map(), map()) :: any()
  defp update(id, data, state) when is_map(data) do
    Logger.debug("Update key: #{inspect(id)}")
    Logger.debug("Update data: #{inspect(data, pretty: true)}")
    # key (id) needs to be reversed for Riak datastore.
    key = String.slice(id, -16..-1) <> String.slice(id, 0..31)
    new_data = wrap_object(data)
    {:ok, stringdata} = Jason.encode(new_data)
    Logger.debug("JSON data: #{inspect(stringdata)}")
    {rc, _} = update(key, stringdata, state)

    if rc == :ok do
      Logger.debug("update ok")
      hash = get_domain_hash(data.domainURI)

      query =
        if Map.has_key?(data, :parentURI) do
          "sp:" <> hash <> data.parentURI <> data.objectName
        else
          # Must be the root container
          "sp:" <> hash <> data.objectName
        end

      RiakMetadata.Cache.set(query, data)
      RiakMetadata.Cache.set(id, data)
    else
      Logger.debug("Update failed: #{inspect(rc)}")
    end

    # Logger.debug("update returning #{inspect({rc, new_data.cdmi})}")
    {rc, new_data.cdmi}
  end

  @spec update(String.t(), String.t(), map()) :: any()
  defp update(key, data, state) do
    Logger.debug("updating with string data: #{inspect(data)}")
    obj = @riak_client.find(state.bucket, key)
    Logger.debug("Update find returned #{inspect(obj)}")

    case obj do
      nil ->
        # Logger.debug("Update not found")
        {:not_found, nil}

      _ ->
        obj = %{obj | data: data}
        {:ok, @riak_client.put(obj).data}
    end
  end

  @doc """
  Calculate a hash for a domain.
  """
  @spec get_domain_hash(binary()) :: binary()
  def get_domain_hash(domain) when is_binary(domain) do
    Logger.debug("get_domain_hash for #{inspect(domain)}")

    :crypto.hmac(:sha, <<"domain">>, domain)
    |> Base.encode16()
    |> String.downcase()
  end

  @spec wrap_object(map()) :: map()
  defp wrap_object(data) do
    domain =
      if data.objectName == "/" do
        "/cdmi_domains/system_domain/"
      else
        Map.get(data, :domainURI, "/cdmi_domains/system_domain/")
      end

    Logger.debug("Domain: #{inspect(domain, pretty: true)}")
    hash = get_domain_hash(domain)

    sp =
      if Map.has_key?(data, :parentURI) do
        hash <> data.parentURI <> data.objectName
      else
        # must be the root container
        hash <> data.objectName
      end

    %{
      sp: sp,
      cdmi: data
    }
  end
end
