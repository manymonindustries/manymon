defmodule Manymon.Repo do
  use Ecto.Repo,
    otp_app: :manymon,
    adapter: Ecto.Adapters.Postgres
end
