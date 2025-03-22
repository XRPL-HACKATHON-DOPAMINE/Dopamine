defmodule Dopamin.Repo do
  use Ecto.Repo,
    otp_app: :dopamin,
    adapter: Ecto.Adapters.Postgres
end
