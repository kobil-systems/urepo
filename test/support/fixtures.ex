defmodule Urepo.Fixtures do
  @fixtures Application.get_env(:urepo, :fixtures, "test/fixtures")

  def fixture(path) do
    [@fixtures | List.wrap(path)]
    |> Path.join()
    |> File.read!()
  end
end
