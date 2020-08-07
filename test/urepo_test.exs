defmodule UrepoTest do
  use ExUnit.Case

  import Urepo.Fixtures

  alias Urepo.Store.Memory, as: Store

  @subject Urepo

  doctest @subject

  setup do
    start_supervised!(Store)
    Application.put_env(:urepo, :store, {Store, []})

    Application.ensure_all_started(:urepo)

    on_exit(fn ->
      Application.stop(:urepo)
    end)

    :ok
  end

  describe "tarball" do
    test "publishing correct tarball results in success" do
      assert {:ok, %{version: "0.1.0"}} =
               @subject.publish_release(fixture("tarballs/example-0.1.0.tar"))
    end

    test "invalid tarball will be rejected" do
      assert {:error, _} = @subject.publish_release(fixture("docs/example-0.1.0.tar"))
    end

    test "after publication of tarball there is file `names`" do
      assert {:error, _} = Store.fetch("names", [])
      assert {:ok, _} = @subject.publish_release(fixture("tarballs/example-0.1.0.tar"))
      assert {:ok, _} = Store.fetch("names", [])
    end

    test "after publication of tarball there is file `versions`" do
      assert {:error, _} = Store.fetch("versions", [])
      assert {:ok, _} = @subject.publish_release(fixture("tarballs/example-0.1.0.tar"))
      assert {:ok, _} = Store.fetch("versions", [])
    end
  end
end
