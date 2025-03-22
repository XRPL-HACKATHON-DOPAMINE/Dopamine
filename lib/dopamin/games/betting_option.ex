defmodule Dopamin.Games.BettingOption do
  use Ecto.Schema
  import Ecto.Changeset

  schema "betting_options" do
    field :name, :string
    field :description, :string
    field :amount, :integer
    field :selected, :boolean, default: false
    belongs_to :game, Dopamin.Games.Game

    timestamps()
  end

  def changeset(betting_option, attrs) do
    betting_option
    |> cast(attrs, [:name, :description, :amount, :selected, :game_id])
    |> validate_required([:name, :description, :game_id])
    |> foreign_key_constraint(:game_id)
  end
end
