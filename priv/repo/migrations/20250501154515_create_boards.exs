defmodule Dopamin.Repo.Migrations.CreateBoards do
  use Ecto.Migration

  def change do
    create table(:boards) do
      add :name, :string, null: false
      add :description, :string
      add :slug, :string, null: false
      add :is_public, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:boards, [:slug])
  end
end
