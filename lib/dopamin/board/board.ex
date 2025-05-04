defmodule Dopamin.Board.Board do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "boards" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :is_public, :boolean, default: true

    has_many :posts, Dopamin.Board.Post

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name, :description, :slug, :is_public])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:slug, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/, message: "영문 소문자, 숫자, 하이픈만 가능합니다")
    |> unique_constraint(:slug)
  end
end
