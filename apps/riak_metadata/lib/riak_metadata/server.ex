defmodule RiakMetadata.Server do
  @riak_client Application.get_env(:riak_metadata, :riak_client)
  @compile if Mix.env() == :test, do: :export_all

  use GenServer
  require Logger
  @domain_uri "/cdmi_domains/"
  import RiakMetadata.State

  def start_link(state) do
    GenServer.start_link(__MODULE__, [state], name: RiakMetadata)
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
    Logger.debug("handle_call: :get Key: #{inspect(key)}")
    obj = get(key, state)
    {:reply, obj, state}
  end

  def handle_call({:put, key, data}, _from, state) do
    Logger.debug("handle_call: :put")
    {:reply, put(key, data, state), state}
  end

  def handle_call({:search, domain, path}, _from, state) do
    Logger.debug("handle_call: :search")
    domain_hash = get_domain_hash(@domain_uri <> domain)
    query = "sp:" <> domain_hash <> path
    s = search(query, state)
    {:reply, s, state}
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
        RiakMetadata.Cache.delete(id)
        hash = get_domain_hash(obj.domainURI)
        query = "sp:" <> hash <> obj.parentURI <> obj.objectName
        RiakMetadata.Cache.delete(query)
        RiakMetadata.Cache.delete(id)
        # key (id) needs to be reversed for Riak datastore.
        key = String.slice(id, -16..-1) <> String.slice(id, 0..31)
        @riak_client.delete(state.bucket, key)
        {:ok, id}

      _other ->
        {:not_found, id}
    end
  end

  @spec get(String.t(), map(), boolean()) :: {atom(), map()}
  defp get(id, state, flip \\ true) do
    response = RiakMetadata.Cache.get(id)

    case response do
      nil ->
        key =
          if flip do
            # key (id) needs to be reversed for Riak datastore.
            String.slice(id, -16..-1) <> String.slice(id, 0..31)
          else
            id
          end

        obj = @riak_client.find(state.bucket, key)

        case obj do
          nil ->
            {:not_found, id}

          _other ->
            {:ok, data} = Jason.decode(obj.data, keys: :atoms)
            RiakMetadata.Cache.set("sp:" <> data.sp, data.cdmi)
            RiakMetadata.Cache.set(data.cdmi.objectID, data.cdmi)

            {:ok, data.cdmi}
        end

      obj ->
        {:ok, obj}
    end
  end

  @spec put(String.t(), String.t() | map(), map()) :: tuple()
  defp put(id, data, state) when is_map(data) do
    # key (id) needs to be reversed for Riak datastore.
    key = String.slice(id, -16..-1) <> String.slice(id, 0..31)
    wrapped_data = wrap_object(data)
    {:ok, stringdata} = Jason.encode(wrapped_data)

    case put(key, stringdata, state) do
      {:ok, new_data} ->
        RiakMetadata.Cache.set(id, new_data.cdmi)
        RiakMetadata.Cache.set("sp:" <> new_data.sp, new_data.cdmi)
        {:ok, new_data.cdmi}

      {rc, _} ->
        {rc, id}
    end
  end

  defp put(key, data, state) when is_binary(data) do
    obj = @riak_client.find(state.bucket, key)

    case obj do
      nil ->
        # this call will return a riak object.
        ro = @riak_client.put(Riak.Object.create(bucket: state.bucket, key: key, data: data))
        Jason.decode(ro.data, keys: :atoms)

      _error ->
        {:dupkey, key}
    end
  end

  @spec search(String.t(), map()) :: {atom(), map()}
  defp search(query, state) do
    response = RiakMetadata.Cache.get(query)

    case response do
      nil ->
        {:ok, {:search_results, results, _score, count}} =
          @riak_client.query(state.cdmi_index, query)

        case count do
          1 ->
            {:ok, data} = get_data(results, state)
            RiakMetadata.Cache.set(query, data)
            RiakMetadata.Cache.set(data.objectID, data)
            {:ok, data}

          0 ->
            {:not_found, query}

          _ ->
            {:multiples, results, count}
        end

      obj ->
        {:ok, obj}
    end
  end

  @spec get_data(list(), map()) :: {atom(), map()}
  defp get_data(results, state) do
    {_, rlist} = List.keyfind(results, state.cdmi_index, 0)
    {_, key} = List.keyfind(rlist, "_yz_rk", 0)
    get(key, state, false)
  end

  @spec update(String.t(), map(), map()) :: any()
  defp update(id, new_data, state) do
    # Get the old stuff from Riak
    case get(id, state) do
      {:ok, old_data} ->
        do_update(old_data, new_data, state)

      other ->
        other
    end
  end

  @spec do_update(map(), map(), map()) :: any()
  defp do_update(old_data, new_data, state) do
    id = old_data.objectID
    # Delete the old stuff from the cache
    old_wrapped = wrap_object(old_data)

    RiakMetadata.Cache.delete(old_wrapped.sp)
    RiakMetadata.Cache.delete(id)

    # key (id) needs to be reversed for Riak datastore.
    key = String.slice(id, -16..-1) <> String.slice(id, 0..31)
    new_data = Map.merge(old_data, new_data)
    wrapped_data = wrap_object(new_data)
    {:ok, stringdata} = Jason.encode(wrapped_data)

    _updated_object =
      @riak_client.put(Riak.Object.create(bucket: state.bucket, key: key, data: stringdata))

    RiakMetadata.Cache.set("sp:" <> wrapped_data.sp, wrapped_data.cdmi)
    RiakMetadata.Cache.set(wrapped_data.cdmi.objectID, wrapped_data.cdmi)

    {:ok, wrapped_data.cdmi}
  end

  @doc """
  Calculate a hash for a domain.
  """
  @spec get_domain_hash(binary()) :: binary()
  def get_domain_hash(domain) when is_binary(domain) do
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
