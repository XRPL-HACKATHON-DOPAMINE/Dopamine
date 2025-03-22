defmodule Dopamin.Repo.Migrations.CreateBettingOptions do
  use Ecto.Migration

  def up do
    create table(:betting_options) do
      add :game_id, :integer
      add :name, :string
      add :description, :string
      add :amount, :integer
      add :selected, :boolean, default: false

      timestamps()
    end

    create index(:betting_options, [:game_id])
  end

  def down do
    drop index(:betting_options, [:game_id])
    drop table(:betting_options)
  end
end
