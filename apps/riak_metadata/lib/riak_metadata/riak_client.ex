defmodule RiakMetadata.Riak.Client do

  def ping() do
    Riak.ping()
  end

  def delete(bucket, key) do
    Riak.delete(bucket, key)
  end

  def find(bucket, key) do
    Riak.find(bucket, key)
  end

  def put(obj) do
    Riak.put(obj)
  end

  def query(cdmi_index, query) do
    Riak.Search.query(cdmi_index, query)
  end
end
