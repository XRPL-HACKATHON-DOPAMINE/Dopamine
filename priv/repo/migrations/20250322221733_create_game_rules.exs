defmodule Dopamin.Repo.Migrations.CreateGameRules do
  use Ecto.Migration

  def up do
    create table(:game_rules) do
      add :game_id, :integer
      add :rule, :text

      timestamps()
    end

    create index(:game_rules, [:game_id])
  end

  def down do
    drop index(:game_rules, [:game_id])
    drop table(:game_rules)
  end
end
