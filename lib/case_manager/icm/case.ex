defmodule CaseManager.ICM.Case do
  @moduledoc false
  use Ash.Resource,
    otp_app: :case_manager,
    domain: CaseManager.ICM,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub],
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshStateMachine, AshAdmin.Resource]

  alias AshStateMachine.Checks.ValidNextState
  alias CaseManager.Policies.MSSPCreatePolicy
  alias CaseManager.Teams.User

  @valid_states [:in_progress, :pending, :t_positive, :f_positive, :benign]
  @closed_states [:t_positive, :f_positive, :benign]

  postgres do
    table "case"
    repo CaseManager.Repo

    references do
      reference :team, on_delete: :delete, on_update: :update, name: "case_to_team_fkey"
      reference :reporter, on_delete: :nilify, on_update: :update, name: "case_to_reporter_fkey"
      reference :assignee, on_delete: :nilify, on_update: :update, name: "case_to_assignee_fkey"
    end
  end

  pub_sub do
    module CaseManagerWeb.Endpoint

    prefix "case"
    publish :create, ["created"]
    publish :escalate, ["escalated", "all"]
    publish :escalate, ["escalated", :team_id]
  end

  policies do
    policy action_type(:create) do
      forbid_unless ValidNextState
      authorize_if MSSPCreatePolicy
    end

    policy action_type(:update) do
      forbid_unless ValidNextState
      authorize_if MSSPCreatePolicy
      authorize_if changing_relationship(:comment)
      authorize_if changing_relationship(:file)
    end

    policy action_type(:read) do
      authorize_if always()
    end
  end

  state_machine do
    initial_states(@valid_states)
    default_initial_state(:in_progress)
    state_attribute(:status)

    transitions do
      transition(:*, from: :in_progress, to: @valid_states)
      transition(:*, from: :pending, to: @valid_states)
      transition(:*, from: :benign, to: @closed_states)
      transition(:*, from: :t_positive, to: @closed_states)
      transition(:*, from: :f_positive, to: @closed_states)
    end
  end

  admin do
    create_actions([])
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false
    attribute :description, :string
    attribute :internal_note, :string

    attribute :status, :atom do
      constraints one_of: @valid_states
      default :in_progress
      allow_nil? false
      public? true
    end

    attribute :escalated, :boolean do
      allow_nil? false
      default false
    end

    attribute :priority, :atom do
      constraints one_of: [:info, :low, :medium, :high, :critical]
      allow_nil? false
    end

    timestamps(public?: true)
  end

  relationships do
    belongs_to :reporter, User, allow_nil?: true
    belongs_to :assignee, User, allow_nil?: true
    belongs_to :team, CaseManager.Teams.Team, allow_nil?: false

    many_to_many :alert, CaseManager.ICM.Alert do
      through CaseManager.ICM.CaseAlert
      source_attribute_on_join_resource :case_id
      destination_attribute_on_join_resource :alert_id
    end

    has_many :comment, CaseManager.ICM.Comment
    has_many :file, CaseManager.ICM.File
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "Create a case with related alerts."

      accept [
        :title,
        :description,
        :priority,
        :escalated,
        :internal_note
      ]

      primary? true

      argument :status, :atom, allow_nil?: false
      argument :alert, {:array, :string}

      change transition_state(arg(:status))
      change manage_relationship(:alert, type: :append_and_remove)
      change relate_actor(:reporter)
    end

    read :read_paginated do
      description "List cases paginated."
      filter expr(^actor(:team_type) == :mssp or (^actor(:team_id) == team_id and escalated == true))

      pagination do
        required? true
        offset? true
        countable true
        default_limit 20
      end
    end

    update :update do
      description "Update the case information."

      accept [
        :title,
        :description,
        :priority,
        :escalated,
        :internal_note
      ]

      argument :status, :atom, allow_nil?: false

      change transition_state(arg(:status))

      primary? true
    end

    update :set_assignee do
      description "Assign a case to a user."
      require_atomic? false

      argument :assignee, :string

      change manage_relationship(:assignee, type: :append_and_remove)
    end

    update :add_comment do
      description "Comment on the case."
      require_atomic? false

      argument :body, :string, allow_nil?: false

      change manage_relationship(
               :body,
               :comment,
               type: :create,
               value_is_key: :body
             )
    end

    update :remove_alert do
      description "Remove an alert related to the case."
      require_atomic? false

      argument :alert_id, :uuid, allow_nil?: false

      change manage_relationship(:alert_id, :alert, type: :remove)
    end

    update :upload_file do
      description "Upload a file and relate it to the case."
      require_atomic? false

      argument :file, :map, allow_nil?: false

      change manage_relationship(:file, type: :create)
    end

    update :escalate do
      description "Escalate a case and thus make it visible to its related team."
      change set_attribute(:escalated, true)
    end
  end

  resource do
    plural_name :cases
    description "A case about one or more alerts."
  end

  preparations do
    prepare build(load: [:team, :assignee])
  end

  aggregates do
    count :no_of_related_alerts, :alert
  end
end
