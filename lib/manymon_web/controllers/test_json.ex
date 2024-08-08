defmodule ManymonWeb.TestJSON do
  alias Manymon.Tests.Test

  @doc """
  Renders a list of tests.
  """
  def index(%{tests: tests}) do
    %{data: for(test <- tests, do: data(test))}
  end

  @doc """
  Renders a single test.
  """
  def show(%{test: test}) do
    %{data: data(test)}
  end

  defp data(%Test{} = test) do
    %{
      id: test.id,
      url: test.url,
      name: test.name,
      method: test.method,
      headers: test.headers,
      body: test.body,
      timeout: test.timeout
    }
  end
end
