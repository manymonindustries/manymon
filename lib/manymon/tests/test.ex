defmodule Manymon.Tests.Test do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tests" do
    field :name, :string
    field :url, :string
    field :method, :string, default: "GET"
    field :headers, :map, default: %{}
    field :body, :string, default: ""
    field :timeout, :float, default: 2.0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(test, attrs) do
    test
    |> cast(attrs, [:name, :url, :method, :headers, :body, :timeout])
    |> validate_required([:name, :url])
    |> unique_constraint(:name)
    |> validate_number(:timeout, greater_than: 0.1, less_than: 10.0)
    |> validate_inclusion(:method, ["GET", "POST", "PUT", "HEAD", "PATCH", "DELETE", "OPTIONS"])
    |> validate_format(:name, ~r/^\w{2,64}$/, message: "name must be between 2 and 64 alphanumeric characters and underscores")
  end
end
