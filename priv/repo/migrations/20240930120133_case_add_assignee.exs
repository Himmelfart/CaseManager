defmodule CaseManager.Repo.Migrations.CaseAddAssignee do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:case) do
      add :assignee_id, :uuid
    end
  end

  def down do
    alter table(:case) do
      remove :assignee_id
    end
  end
end
