defmodule ManymonWeb.TestController do
  use ManymonWeb, :controller

  alias Manymon.Tests
  alias Manymon.Tests.Test

  action_fallback ManymonWeb.FallbackController

  def index(conn, _params) do
    tests = Tests.list_tests()
    render(conn, :index, tests: tests)
  end

  def create(conn, %{"test" => test_params}) do
    with {:ok, %Test{} = test} <- Tests.create_test(test_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/tests/#{test}")
      |> render(:show, test: test)
    end
  end

  def show(conn, %{"id" => id}) do
    test = Tests.get_test!(id)
    render(conn, :show, test: test)
  end

  def update(conn, %{"id" => id, "test" => test_params}) do
    test = Tests.get_test!(id)

    with {:ok, %Test{} = test} <- Tests.update_test(test, test_params) do
      render(conn, :show, test: test)
    end
  end

  def delete(conn, %{"id" => id}) do
    test = Tests.get_test!(id)

    with {:ok, %Test{}} <- Tests.delete_test(test) do
      send_resp(conn, :no_content, "")
    end
  end
end
