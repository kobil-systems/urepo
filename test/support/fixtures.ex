defmodule Urepo.Fixtures do
  @moduledoc false

  @fixtures Application.get_env(:urepo, :fixtures, "test/fixtures")

  @doc """
  Read fixture ad given path
  """
  def fixture(path) do
    [@fixtures | List.wrap(path)]
    |> Path.join()
    |> File.read!()
  end
end
