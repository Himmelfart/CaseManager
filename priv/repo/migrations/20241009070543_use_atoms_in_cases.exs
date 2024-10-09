defmodule CaseManager.Repo.Migrations.UseAtomsInCases do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:case) do
      modify :status, :text, default: "in_progress"
    end
  end

  def down do
    alter table(:case) do
      modify :status, :text, default: "In Progress"
    end
  end
end
