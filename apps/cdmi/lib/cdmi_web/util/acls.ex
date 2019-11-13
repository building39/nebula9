defmodule CdmiWeb.Util.ACLs do
  @moduledoc """
  All things related to ACLs
  """

  import Bitwise

  @doc """
  Allow access rights for a principal.
  """

  defmacro cdmi_ace_access_allow do
    0x00000000
  end

  @doc """
  Deny access rights for a principal.
  """
  defmacro cdmi_ace_access_deny do
    0x00000001
  end

  @doc """
  Generate an audit record when the principal attempts to exercise the
  specified access rights.
  """
  defmacro cdmi_ace_system_audit do
    0x00000002
  end

  @doc """
  No flags are set.
  """
  defmacro cdmi_ace_flags_no_flags do
    0x00000000
  end

  @doc """
  An ACE on which OBJECT_INHERIT is set is inherited by objects as an effective
  ACE: OBJECT_INHERIT is cleared on the child object. When the ACE is inherited
  by a container, OBJECT_INHERIT is retained for the purpose of inheritance, and
  additionally, INHERIT_ONLY is set.
  """
  defmacro cdmi_ace_flags_object_inherit do
    0x00000001
  end

  @doc """
  An ACE on which CONTAINER_INHERIT is set is inherited by a subcontainer as an
  effective ACE. Both INHERIT_ONLY and CONTAINER_INHERIT are cleared on the
  child container.
  """
  defmacro cdmi_ace_flags_container_inherit do
    0x00000002
  end

  @doc """
  An ACE on which NO_PROPAGATE is set is not inherited by any objects or
  subcontainers. It applies only to the container on which it is set.
  """
  defmacro cdmi_ace_flags_no_propagate do
    0x00000004
  end

  @doc """
  An ACE on which INHERIT_ONLY is set is propagated to children during ACL
  inheritance as specified by OBJECT_INHERIT and CONTAINER_INHERIT. The ACE
  is ignored when evaluating access to the container on which it is set and is
  always ignored when set on objects.
  """
  defmacro cdmi_ace_flags_inherit_only do
    0x00000008
  end

  @doc """
  An ACE on which IDENTIFIER_GROUP is set indicates that the "who" refers to a
  group identifier.
  """
  defmacro cdmi_ace_flags_identifier_group do
    0x00000040
  end

  @doc """
  An ACE on which INHERITED is set indicates that this ACE is inherited from a
  parent directory. A server that supports automatic inheritance will place this
  flag on any ACEs inherited from the parent directory when creating a new
  object.
  """
  defmacro cdmi_ace_flags_inherited do
    0x00000080
  end

  @doc """
  Permission to read the value of an object.

  If "READ_OBJECT" is not permitted:
    • A CDMI GET that requests all fields shall return all fields with the
      exception of the value field.
    • A CDMI GET that requests specific fields shall return the requested fields
      with the exception of the value field.
    • A CDMI GET for only the value field shall return an HTTP status code of
      403 Forbidden.
    • A non-CDMI GET shall return an HTTP status code of 403 Forbidden.
  """
  defmacro cdmi_ace_read_object do
    0x00000001
  end

  @doc """
  Permission to list the children of an object.

  If "LIST_CONTAINER" is not permitted:
    • A CDMI GET that requests all fields shall return all fields with the
      exception of the children field and childrenrange field.
    • A CDMI GET that requests specific fields shall return the requested fields
      with the exception of the children field and childrenrange field.
    • A CDMI GET for only the children field and/or childrenrange field shall
      return an HTTP status code of 403 orbidden.
  """
  defmacro cdmi_ace_list_container do
    0x00000001
  end

  @doc """
  Permission to modify the value of an object.

  If "WRITE_OBJECT" is not permitted, a PUT that requests modification of the
  value of an object shall return an HTTP status code of 403 Forbidden.
  """
  defmacro cdmi_ace_write_object do
    0x00000002
  end

  @doc """
  Permission to add a new child data object or queue object.

  If "ADD_OBJECT" is not permitted, a PUT or POST that requests creation of a
  new child data object or new queue object shall return an HTTP status code of
  403 Forbidden.
  """
  defmacro cdmi_ace_add_object do
    0x00000002
  end

  @doc """
  Permission to append data to the value of a data object.

  If "APPEND_DATA" is permitted and "WRITE_OBJECT" is not permitted, a PUT that
  requests modification of any existing part of the value of an object shall
  return an HTTP status code of 403 Forbidden.
  """
  defmacro cdmi_ace_append_data do
    0x00000004
  end

  @doc """
  Permission to create a child container object or domain object.

  If "ADD_SUBCONTAINER" is not permitted, a PUT that requests creation of a new
  child container object or new domain object shall return an HTTP status code
  of 403 Forbidden.
  """
  defmacro cdmi_ace_add_subcontainer do
    0x00000004
  end

  @doc """
  Permission to read the metadata of an object.

  If "READ_METADATA" is not permitted:
    • A CDMI GET that requests all fields shall return all fields with the
      exception of the metadata field.
    • A CDMI GET that requests specific fields shall return the requested fields
      with the exception of the metadata field.
    • A CDMI GET for only the metadata field shall return an HTTP status code of
      403 Forbidden.
  """
  defmacro cdmi_ace_read_metadata do
    0x00000008
  end

  @doc """
  Permission to modify the metadata of an object.

  If "WRITE_METADATA" is not permitted, a CDMI PUT that requests modification of
  the metadata field of an object shall return an HTTP status code of
  403 Forbidden.
  """
  defmacro cdmi_ace_write_metadata do
    0x00000010
  end

  @doc """
  Permission to execute an object.
  """
  defmacro cdmi_ace_execute do
    0x00000020
  end

  @doc """
  Permission to traverse a container object or domain object.

  If "TRAVERSE_CONTAINER" is not permitted for a parent container, all
  operations against all children below that container shall return an HTTP
  status code of 403 Forbidden.
  """
  defmacro cdmi_ace_traverse_container do
    0x00000020
  end

  @doc """
  Permission to delete a child data object or child queue object from a
  container object.

  If "DELETE_OBJECT" is not permitted, all DELETE operations shall return an
  HTTP status code of 403 Forbidden.
  """
  defmacro cdmi_ace_delete_object do
    0x00000040
  end

  @doc """
  Permission to delete a child container object from a container object or to
  delete a child domain object from a domain object.

  If "DELETE_SUBCONTAINER" is not permitted, all DELETE operations shall return
  an HTTP status code of 403 Forbidden.
  """
  defmacro cdmi_ace_delete_subcontainer do
    0x00000040
  end

  @doc """
  Permission to read the attribute fields of an object.
  The value fields, children fields, and metadata field are considered to be
  non-attribute fields. All other fields are considered to be attribute fields.

  If "READ_ATTRIBUTES" is not permitted:
    • A CDMI GET that requests all fields shall return all non-attribute fields
      and shall not return any attribute fields.
    • A CDMI GET that requests at least one non-attribute field shall only
      return the requested non-attribute fields.
    • A CDMI GET that requests only non-attribute fields shall return an HTTP
      status code of 403 Forbidden.
  """
  defmacro cdmi_ace_read_attributes do
    0x00000080
  end

  @doc """
  Permission to change attribute fields of an object.
  The value fields, children fields, and metadata field are considered to be
  non-attribute fields. All other fields are considered to be attribute fields.

  If "WRITE_ATTRIBUTES" is not permitted, a CDMI PUT that requests modification
  of any non-attribute field shall return an HTTP status code of 403 Forbidden.
  """
  defmacro cdmi_ace_write_attributes do
    0x00000100
  end

  @doc """
  Permission to change retention attributes of an object.

  If "WRITE_RETENTION" is not permitted, a CDMI PUT that requests modification
  of any non-hold retention metadata items shall return an HTTP status code of
  403 Forbidden.
  """
  defmacro cdmi_ace_write_retention do
    0x00000200
  end

  @doc """
  Permission to change retention hold attributes of an object.

  If "WRITE_RETENTION_HOLD" is not permitted, a CDMI PUT that requests
  modification of any retention hold metadata items shall return an HTTP status
  code of 403 Forbidden.
  """
  defmacro cdmi_ace_write_retention_hold do
    0x00000400
  end

  @doc """
  Permission to delete an object.

  If "DELETE" is not permitted, all DELETE operations shall return an HTTP
  status code of 403 Forbidden.
  """
  defmacro cdmi_ace_delete do
    0x00010000
  end

  @doc """
  Permission to read the ACL of an object.

  If "READ_ACL" is not permitted:
    • A CDMI GET that requests all metadata items shall return all metadata
      items with the exception of the cdmi_acl metadata item.
    • A CDMI GET that requests specific metadata items shall return the
      requested metadata items with the exception of the cdmi_acl metadata item.
    • A CDMI GET for only the cdmi_acl metadata item shall return an HTTP status
      code of 403 Forbidden.

  If "READ_ACL" is permitted and "READ_METADATA" is not permitted, then to read
  the ACL, a client CDMI GET for only the cdmi_acl metadata item shall be
  permitted.
  """
  defmacro cdmi_ace_read_acl do
    0x00020000
  end

  @doc """
  Permission to write the ACL of an object.

    • If "WRITE_ACL" is not permitted, a CDMI PUT that requests modification of
      the cdmi_acl metadata item shall return an HTTP status code of
      403 Forbidden.
    • If "WRITE_ACL" is permitted and "WRITE_METADATA" is not permitted, then to
      write the ACL, a client CDMI PUT for only the cdmi_acl metadata item shall
      be permitted.
  """
  defmacro cdmi_ace_write_acl do
    0x00040000
  end

  @doc """
  Permission to change the owner of an object.

    • If "WRITE_OWNER" is not permitted, a CDMI PUT that requests modification
      of the cdmi_owner metadata item shall return an HTTP status code of
      403 Forbidden.
    • If "WRITE_OWNER" is permitted and "WRITE_METADATA" is not permitted, then
      to write the owner, a client CDMI PUT for only the cdmi_owner metadata
      item shall be permitted.
  """
  defmacro cdmi_ace_write_owner do
    0x00080000
  end

  @doc """
  Permission to access an object locally at the server with synchronous reads
  and writes.
  """
  defmacro cdmi_ace_synchronize do
    0x00100000
  end

  @doc """
  Allow all permissions.
  """
  defmacro cdmi_all_perms do
    0x001F07FF
  end

  @doc """
  Allow all read/write permissions.
  """
  defmacro cdmi_read_write_all_perms do
    0x000601DF
  end

  @doc """
  Allow basic read/write permissions.
  """
  defmacro cdmi_read_write do
    0x0000001F
  end

  @doc """
  Read permissions.
  """
  defmacro cdmi_read_perms do
    cdmi_ace_read_object()
    |> bor(cdmi_ace_list_container())
    |> bor(cdmi_ace_read_metadata())
    |> bor(cdmi_ace_traverse_container())
    |> bor(cdmi_ace_read_attributes())
  end
end
