defmodule Urepo.DocsTest do
  use ExUnit.Case

  import Urepo.Fixtures

  alias Urepo.Store.Memory, as: Store

  @subject Urepo.Docs

  doctest @subject

  setup do
    start_supervised!(Store)
    Application.put_env(:urepo, :store, {Store, []})

    Application.ensure_all_started(:urepo)

    on_exit(fn ->
      Application.stop(:urepo)
    end)

    assert :ok = Urepo.publish_docs("example", "0.1.0", fixture("docs/example-0.1.0.tar"))

    :ok
  end

  test "fetching existing file succeeds" do
    assert {:ok, _} = @subject.file("example", "0.1.0", "index.html")
  end

  test "fetching docs for non-existent package fails" do
    assert :error = @subject.file("non_existent", "0.1.0", "index.html")
  end

  test "fetching docs for non-existent version fails" do
    assert :error = @subject.file("example", "0.2.0", "index.html")
  end

  test "fetching docs for non-existent file fails" do
    assert :error = @subject.file("example", "0.1.0", "non-existent.html")
  end
end
