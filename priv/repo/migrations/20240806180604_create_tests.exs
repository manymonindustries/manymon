defmodule Manymon.Repo.Migrations.CreateTests do
  use Ecto.Migration

  def change do
    create table(:tests) do
      add :name, :string
      add :url, :string
      add :method, :string
      add :headers, :map
      add :body, :string
      add :timeout, :float

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tests, [:name])
  end
end
