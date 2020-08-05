defmodule Urepo.RepoTest do
  use ExUnit.Case

  import Urepo.Fixtures

  alias Urepo.Store.Memory, as: Store

  @subject Urepo.Repo

  doctest @subject

  setup do
    start_supervised!(Store)
    Application.put_env(:urepo, :store, {Store, []})

    Application.ensure_all_started(:urepo)

    on_exit(fn ->
      Application.stop(:urepo)
    end)

    assert {:ok, {name, release}} =
             Urepo.Repo.Release.from_tarball(fixture("tarballs/example-0.1.0.tar"))

    {:ok, name: name, release: release}
  end

  test "adding release ends with success", %{name: name, release: release} do
    assert :ok = @subject.add(name, release)
  end

  test "added release appears in releases", %{name: name, release: release} do
    assert :ok = @subject.add(name, release)
    assert {:ok, [release]} == @subject.get_releases(name)
  end

  test "releases always appear version-sorted", %{name: name, release: release} do
    assert :ok = @subject.add(name, %{release | version: "0.1.1"})
    assert :ok = @subject.add(name, %{release | version: "0.2.0"})
    assert :ok = @subject.add(name, %{release | version: "0.1.0"})

    assert {:ok, [%{version: "0.2.0"}, %{version: "0.1.1"}, %{version: "0.1.0"}]} =
             @subject.get_releases(name)
  end

  test "unknown release return error" do
    assert :error = @subject.get_releases("foo_bar")
  end

  test "after application restart all versions are still available", %{
    name: name,
    release: release
  } do
    assert :ok = @subject.add(name, %{release | version: "0.1.1"})
    assert :ok = @subject.add(name, %{release | version: "0.2.0"})
    assert :ok = @subject.add(name, %{release | version: "0.1.0"})

    Application.stop(:urepo)
    Application.ensure_all_started(:urepo)

    assert {:ok, [%{version: "0.2.0"}, %{version: "0.1.1"}, %{version: "0.1.0"}]} =
             @subject.get_releases(name)
  end
end
