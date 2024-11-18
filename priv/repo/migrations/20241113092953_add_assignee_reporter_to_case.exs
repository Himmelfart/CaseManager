defmodule CaseManager.Repo.Migrations.AddAssigneeReporterToCase do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:case) do
      add :reporter_id,
          references(:user,
            column: :id,
            name: "case_to_reporter_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :nilify_all,
            on_update: :update_all
          )

      modify :assignee_id,
             references(:user,
               column: :id,
               name: "case_to_assignee_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :nilify_all,
               on_update: :update_all
             )
    end

    create index(:case, [:assignee_id])
  end

  def down do
    drop_if_exists index(:case, [:assignee_id])

    drop constraint(:case, "case_to_reporter_fkey")

    drop constraint(:case, "case_to_assignee_fkey")

    alter table(:case) do
      modify :assignee_id, :uuid
      remove :reporter_id
    end
  end
end
