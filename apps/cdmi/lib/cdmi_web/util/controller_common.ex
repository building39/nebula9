defmodule CdmiWeb.Util.ControllerCommon do
  @moduledoc """
  Functions common to all of the application's controllers
  """

  defmacro __using__(_) do
    quote do
      import CdmiWeb.Util.Constants
      import CdmiWeb.Util.Utils
      require Logger


      @doc """
      Check ACLs.
      This is a TODO.
      """
      @spec check_acls(Plug.Conn.t()) :: Plug.Conn.t()
      def check_acls(conn = %{halted: true}) do
        conn
      end

      def check_acls(conn) do
        Logger.debug(fn -> "In check_acls" end)
        # TODO: enforce acls
        conn
      end

      @doc """
      Check object capabilities.
      """
      @spec check_capabilities(Plug.Conn.t(), atom, String.t()) :: Plug.Conn.t()
      def check_capabilities(conn = %{halted: true}, _object_type, _action) do
        conn
      end

      def check_capabilities(conn, object_type, "DELETE") do
        Logger.debug(fn -> "In check_capabilities DELETE" end)
        Logger.debug("conn: #{inspect(conn, pretty: true)}")

        container = conn.assigns.data
        Logger.debug("XYZ calling get_domain_hash")

        query =
          "sp:" <> get_domain_hash("/cdmi_domains/system_domain/") <> container.capabilitiesURI

        {:ok, capabilities} = GenServer.call(Metadata, {:search, query})
        capabilities = Map.get(capabilities, :capabilities)

        can_delete =
          case object_type do
            :cdmi_object ->
              # TODO: fix this
              false

            :container ->
              Map.get(capabilities, :cdmi_delete_container, false)

            :domain ->
              Map.get(capabilities, :cdmi_delete_domain, false)
          end

        if can_delete == "true" do
          conn
        else
          request_fail(conn, :bad_request, "Deletion of #{inspect(object_type)} is forbidden")
        end
      end

      def check_capabilities(conn, object_type, "PUT") do
        Logger.debug(fn -> "In check_capabilities PUT" end)

        parent = conn.assigns.parent
        Logger.debug("parent is: #{inspect(parent)}")
        Logger.debug("parent capabilitiesURI: #{inspect(parent.capabilitiesURI)}")

        query = "sp:" <> get_domain_hash("/cdmi_domains/system_domain/") <> parent.capabilitiesURI

        {:ok, capabilities} = GenServer.call(Metadata, {:search, query})

        capabilities = Map.get(capabilities, :capabilities)
        Logger.debug("got capabilities: #{inspect(capabilities, pretty: true)}")
        Logger.debug("object_type: #{inspect(object_type)}")

        can_create =
          case object_type do
            :data_object ->
              Logger.debug("can create #{object_type}?")
              Map.get(capabilities, :cdmi_create_dataobject, false)

            :container ->
              Map.get(capabilities, :cdmi_create_container, false)

            :domain ->
              Map.get(capabilities, :cdmi_create_domain, false)
          end

        if can_create == "true" do
          conn
        else
          request_fail(conn, :bad_request, "Creation of #{inspect(object_type)} is forbidden")
        end
      end

      @doc """
      Check for mandatory Content-Type header.
      """
      @spec check_content_type_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
      def check_content_type_header(conn, resource) do
        Logger.debug(fn -> "In check_content_type_header" end)

        if List.keymember?(conn.req_headers, "content-type", 0) and
             List.keyfind(conn.req_headers, "content-type", 0) ==
               {"content-type", "application/cdmi-#{resource}"} do
          conn
        else
          request_fail(
            conn,
            :bad_request,
            "Missing Header: Content-Type: application/cdmi-#{resource}"
          )
        end
      end

      @doc """
      Document the Check Domain function
      """
      @spec check_domain(Plug.Conn.t()) :: Plug.Conn.t()
      def check_domain(conn) do
        if Map.has_key?(conn.assigns, :cdmi_domain) do
          domain = conn.assigns.cdmi_domain
          Logger.debug(fn -> "Domain is #{inspect(domain)}" end)
          domain_string = "/cdmi_domains/#{domain}"
          Logger.debug("XYZ calling get_domain_hash for #{inspect(domain_string)}")
          domain_hash = get_domain_hash(domain_string)
          query = "sp:" <> domain_hash <> domain_string
          {rc, data} = GenServer.call(Metadata, {:search, query})

          if rc == :ok and data.objectType == domain_object() do
            if Map.get(data.metadata, :cdmi_domain_enabled, false) do
              conn
            else
              request_fail(conn, :forbidden, "Forbidden1")
            end
          else
            request_fail(conn, :forbidden, "Forbidden2")
          end
        else
          # Capability objects don't have a domain object
          conn
        end
      end

      @spec construct_domain(Plug.Conn.t(), String.t()) ::
              {:ok, String.t()} | {:not_found, String.t()} | {:error, String.t()}
      defp construct_domain(conn = %{halted: true}, _domain) do
        Logger.debug("construct_domain halted")
        conn
      end

      defp construct_domain(conn, domain) do
        Logger.debug("constructing a new domain URI for domain: #{inspect(domain)}")

        hash = get_domain_hash("/cdmi_domains/" <> domain)
        query = "sp:" <> hash <> "/cdmi_domains/" <> domain
        Logger.debug("query: #{inspect(query)}")
        response = GenServer.call(Metadata, {:search, query})
        Logger.debug("search results: #{inspect(response)}")

        case tuple_size(response) do
          2 ->
            {status, _} = response

            case status do
              :not_found ->
                {:not_found, domain}

              :ok ->
                Logger.debug("MLM conn: #{inspect(conn, pretty: true)}")
                Logger.debug("domain: #{inspect(domain)}")

                if conn.assigns.cdmi_domain == domain do
                  {:ok, domain}
                else
                  if "cross_domain" in conn.assigns.cdmi_member_privileges do
                    Logger.debug("cross domain access!")
                    {:ok, domain}
                  else
                    {:error, domain}
                  end
                end
            end

          _ ->
            {:error, domain}
        end
      end

      #
      # Construct the basic object metadata
      #
      @spec construct_metadata(String.t()) :: map
      defp construct_metadata(auth_as) do
        Logger.debug(fn -> "In construct_metadata" end)
        Logger.debug(fn -> "auth_as: #{inspect(auth_as)}" end)
        timestamp = make_timestamp()
        # timestamp = List.to_string(Nebula.Util.Utils.make_timestamp())
        Logger.debug(fn -> "Hi there!" end)
        Logger.debug(fn -> "timestamp: #{inspect(timestamp)}" end)
        # Logger.debug(fn -> "assigns: #{inspect conn.assigns}" end)
        %{
          cdmi_owner: auth_as,
          cdmi_atime: timestamp,
          cdmi_ctime: timestamp,
          cdmi_mtime: timestamp,
          cdmi_acl: [
            %{
              aceflags: "0x03",
              acemask: "0x1f07ff",
              acetype: "0x00",
              identifier: "OWNER\@"
            },
            %{
              aceflags: "0x03",
              acemask: "0x1F",
              acetype: "0x00",
              identifier: "AUTHENTICATED\@"
            },
            %{
              aceflags: "0x83",
              acemask: "0x1f07ff",
              acetype: "0x00",
              identifier: "OWNER\@"
            },
            %{
              aceflags: "0x83",
              acemask: "0x1F",
              acetype: "0x00",
              identifier: "AUTHENTICATED\@"
            }
          ]
        }
      end

      @spec create_new_container(Plug.Conn.t()) :: Plug.Conn.t()
      defp create_new_container(conn = %{halted: true}) do
        conn
      end

      defp create_new_container(conn) do
        Logger.debug(fn -> "In create_new_container" end)

        object_oid = Cdmioid.generate(45241)
        object_name = List.last(conn.path_info) <> "/"
        Logger.debug("MLM path_info: #{inspect(conn.path_info)}")
        auth_as = conn.assigns.authenticated_as

        metadata =
          if Map.has_key?(conn.body_params, "metadata") do
            new_metadata = construct_metadata(auth_as)
            supplied_metadata = conn.body_params["metadata"]
            merged_metadata = Map.merge(new_metadata, supplied_metadata)
            merged_metadata
          else
            new_metadata = construct_metadata(auth_as)
            new_metadata
          end

        domain_uri =
          cond do
            # Enum.at(conn.path_info, 2) == "cdmi_domains" ->
            #   {:ok, "system_domain/"}
            Map.has_key?(conn.body_params, "domainURI") ->
              construct_domain(conn, conn.body_params["domainURI"])

            true ->
              {:ok, conn.assigns.cdmi_domain}
          end

        Logger.debug("construct_domain returned #{inspect(domain_uri)}")

        case domain_uri do
          {:ok, domain} ->
            Logger.debug("setting parentURI")
            new_container = %{
              objectType: container_object(),
              objectID: object_oid,
              objectName: object_name,
              parentURI: conn.assigns.parentURI,
              parentID: conn.assigns.parent.objectID,
              domainURI: "/cdmi_domains/" <> domain,
              capabilitiesURI: container_capabilities_uri(),
              completionStatus: "Complete",
              children: [],
              childrenrange: "",
              metadata: metadata
            }
            Logger.debug("parentURI ok")

            c = assign(conn, :newobject, new_container)
            Logger.debug("Assign 1: #{inspect c.assigns, pretty: true}")
            c

          {:not_found, _} ->
            request_fail(conn, :bad_request, "Specified domain not found")

          {_, _} ->
            request_fail(conn, :bad_request, "Bad request")
        end
      end

      @doc """
      Delete an object and all of its children
      """
      @spec delete_object(Plug.Conn.t()) :: Plug.Conn.t()
      def delete_object(conn = %{halted: true}) do
        conn
      end

      def delete_object(conn) do
        oid = conn.assigns.data.objectID
        Task.start(__MODULE__, :handle_delete, [conn.assigns.data])
        conn
      end

      @spec handle_delete(map) :: atom
      def handle_delete(obj) do
        oid = obj.objectID

        if obj.objectType == data_object() do
          GenServer.call(Metadata, {:delete, oid})
        else
          children = Map.get(obj, :children, [])
          Logger.debug("XYZ calling get_domain_hash")
          hash = get_domain_hash(obj.domainURI)
          Logger.debug("setting parentURI")
          query = "sp:" <> hash <> obj.parentURI <> obj.objectName
          Logger.debug("parentURI ok")

          if length(children) == 0 do
            GenServer.call(Metadata, {:delete, oid})
          else
            for child <- children do
              query = query <> child

              case GenServer.call(Metadata, {:search, query}) do
                {:ok, data} ->
                  handle_delete(data)

                _ ->
                  nil
              end

              GenServer.call(Metadata, {:delete, oid})
            end
          end
        end

        #        :ok
      end

      @doc """
      Get the parent of an object.
      """
      @spec get_parent(Plug.Conn.t()) :: map
      def get_parent(conn = %{halted: true}) do
        conn
      end

      def get_parent(conn) do
        Logger.debug(fn -> "In get_parent" end)

        container_path = Enum.drop(conn.path_info, 2)
        parent_path = "/" <> Enum.join(Enum.drop(container_path, -1), "/")

        parent_uri =
          if String.ends_with?(parent_path, "/") do
            parent_path
          else
            parent_path <> "/"
          end

        Logger.debug("container's parent is #{inspect(parent_uri)}")
        Logger.debug("setting parentURI")
        conn2 = assign(conn, :parentURI, parent_uri)
        Logger.debug("parentURI ok")
        Logger.debug("Assign 2: #{inspect conn2.assigns, pretty: true}")
        Logger.debug("XYZ calling get_domain_hash")

        domain_hash =
          if parent_uri == "/" do
            # Root container always resides in system_domain
            get_domain_hash("/cdmi_domains/system_domain/")
          else
            Logger.debug("conn2.assigns.cdmi_domain: #{inspect(conn2.assigns.cdmi_domain)}")
            get_domain_hash("/cdmi_domains/" <> conn2.assigns.cdmi_domain)
          end

        Logger.debug("domain_hash #{inspect(domain_hash)}")
        query = "sp:" <> domain_hash <> parent_uri
        parent_obj = GenServer.call(Metadata, {:search, query})

        case parent_obj do
          {:ok, data} ->
            Logger.debug(fn -> "get_parent found parent #{inspect(data, pretty: true)}" end)
            c = assign(conn2, :parent, data)
            Logger.debug("Assign 3: #{inspect c.assigns, pretty: true}")
            c

          {_, _} ->
            Logger.debug("couldn't find parent container #{inspect(query)}")
            request_fail(conn, :not_found, "Parent container does not exist")
        end
      end

      @doc """
      Process the query string.
      """
      @spec process_query_string(Plug.Conn.t(), map) :: map
      def process_query_string(conn, data) do
        handle_qs(conn, data, String.split(conn.query_string, ";"))
      end

      @doc """
      Fail a request.
      """
      @spec request_fail(Plug.Conn.t(), atom, String.t(), list) :: map
      def request_fail(conn, status, message, headers \\ []) do
        if length(headers) > 0 do
          Enum.reduce(headers, conn, fn {k, v}, acc ->
            put_resp_header(acc, k, v)
          end)
        else
          conn
        end
        |> put_status(status)
        |> json(%{error: message})
        |> halt()
      end

      @doc """
      Check for the existence of a query parameter.
      """
      @spec query_parm_exists?(map, atom) :: boolean
      def query_parm_exists?(data, parm) do
        Map.has_key?(data, parm)
      end

      @spec set_mandatory_response_headers(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
      def set_mandatory_response_headers(conn, resource) do
        conn
          |> put_resp_header(
              "X-CDMI-Specification-Version",
              Enum.join(Application.get_env(:cdmi, :cdmi_versions), ",")
            )
          |> put_resp_header("content-type", resource)
      end

      @doc """
      Update an object's parent.
      """
      @spec update_parent(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
      def update_parent(conn = %{halted: true}, _action) do
        conn
      end

      def update_parent(conn, "DELETE") do
        Logger.debug(fn -> "In update_parent DELETE" end)

        child = conn.assigns.data
        parent = conn.assigns.parent
        Logger.debug("parent is #{inspect(parent)}")
        index = Enum.find_index(Map.get(parent, :children), fn x -> x == child.objectName end)
        children = Enum.drop(Map.get(parent, :children), index + 1)
        parent = Map.put(parent, :children, children)
        children_range = Map.get(parent, :childrenrange)

        new_range =
          case children_range do
            "0-0" ->
              ""

            _ ->
              [first, last] = String.split(children_range, "-")
              "0-" <> Integer.to_string(String.to_integer(last) - 1)
          end

        parent = Map.put(parent, :childrenrange, new_range)
        result = GenServer.call(Metadata, {:update, parent.objectID, parent})
        c = assign(conn, :parent, parent)
        Logger.debug("Assign 4: #{inspect c.assigns, pretty: true}")
        c
      end

      def update_parent(conn, "PUT") do
        Logger.debug(fn -> "XYZ In update_parent PUT" end)
        Logger.debug("update parent conn: #{inspect(conn, pretty: true)}")

        child = conn.assigns.newobject
        parent_obj = get_parent(conn)
        Logger.debug("parent_obj: #{inspect(parent_obj, pretty: true)}")
        parent = parent_obj.assigns.parent
        Logger.debug("updating parent #{inspect(parent, pretty: true)}")
        children = Enum.concat([child.objectName], Map.get(parent, :children, []))
        Logger.debug("new child list: #{inspect(children)}")
        new_parent = Map.put(parent, :children, children)
        Logger.debug("parent is #{inspect(new_parent)}")
        children_range = Map.get(new_parent, :childrenrange, "")

        Logger.debug(fn ->
          "XYZ parent: #{inspect(new_parent)} children: #{inspect(children)} range: #{
            inspect(children_range)
          }"
        end)

        new_range =
          case children_range do
            "" ->
              "0-0"

            _ ->
              [first, last] = String.split(children_range, "-")
              "0-" <> Integer.to_string(String.to_integer(last) + 1)
          end

        new_parent2 = Map.put(new_parent, :childrenrange, new_range)

        case GenServer.call(Metadata, {:update, new_parent2.objectID, new_parent2}) do
          {:ok, new_parent2} ->
            Logger.debug("XYZ parent update succeeded: #{inspect(new_parent2, pretty: true)}")
            new_conn = assign(conn, :parent, new_parent2)
            Logger.debug("Assign 5: #{inspect new_conn.assigns, pretty: true}")
            Logger.debug("XYZ New conn: #{inspect(new_conn)}")
            new_conn

          {other, reason} ->
            # TODO: handle errors here
            Logger.debug("XYZ update parent failed: #{inspect(other)} #{inspect(reason)}")
            conn
        end
      end

      @spec write_new_object(Plug.Conn.t()) :: Plug.Conn.t()
      def write_new_object(conn = %{halted: true}) do
        conn
      end

      def write_new_object(conn) do
        Logger.debug(fn -> "XYZ In write_new_object" end)

        new_domain = conn.assigns.newobject
        key = new_domain.objectID
        parent = conn.assigns.parent
        Logger.debug("parent is #{inspect(parent)}")
        {rc, data} = GenServer.call(Metadata, {:put, key, new_domain})

        if rc == :ok do
          Logger.debug("wrote the new object")
          conn
        else
          request_fail(conn, :service_unavailable, "Service Unavailable")
        end
      end

      @spec handle_qs(Plug.Conn.t(), map, list) :: map
      defp handle_qs(conn, data, qs) when qs == [""] do
        data
      end

      defp handle_qs(conn, data, qs) do
        Enum.reduce(qs, %{}, fn qp, acc ->
          if String.contains?(qp, ":") do
            handle_subparms(qp, acc, data)
          else
            if query_parm_exists?(data, String.to_atom(qp)) do
              Map.put(acc, qp, Map.get(data, String.to_atom(qp)))
            end
          end
        end)
      end

      @spec handle_subparms(String.t(), list, map) :: map
      defp handle_subparms(qp, acc, data) do
        [qp2, val] = String.split(qp, ":")

        if query_parm_exists?(data, String.to_atom(qp2)) do
          handle_subparm(acc, data, qp2, val)
        else
          %{}
        end
      end

      @spec handle_subparm(list, map, String.t(), String.t()) :: list
      defp handle_subparm(acc, data, qp, val) when qp == "children" do
        [idx0, idx1] = String.split(val, "-")
        s = String.to_integer(idx0)
        e = String.to_integer(idx1)

        childlist =
          Enum.reduce(s..e, [], fn i, acc ->
            acc ++ List.wrap(Enum.at(data.children, i))
          end)

        Map.put(acc, String.to_atom(qp), childlist)
      end

      defp handle_subparm(acc, data, qp, val) when qp == "metadata" do
        metadata =
          Enum.reduce(data.metadata, %{}, fn {k, v}, md ->
            if String.starts_with?(Atom.to_string(k), val) do
              Map.put(md, k, v)
            else
              md
            end
          end)

        Map.put(acc, :metadata, metadata)
      end

      defp handle_subparm(acc, _data, qp, _val) do
        acc
      end
    end
  end
end
