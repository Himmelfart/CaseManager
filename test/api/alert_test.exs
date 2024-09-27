defmodule CaseManager.Alerts.AlertTest do
  use CaseManager.DataCase, async: true
  use ExUnitProperties
  alias CaseManager.Alerts.Alert
  alias CaseManager.Teams.Team

  @valid_team_attrs %{
    name: "Test Team"
  }
  @valid_alert_attrs %{
    alert_id: "12345678",
    title: "Test Alert",
    risk_level: "High",
    start_time: "2024-09-13T12:13:11.551Z",
    end_time: "2024-09-13T12:13:12.551Z",
    link: "http://example"
  }
  @valid_risk_levels ["Informational", "Low", "Medium", "High", "Critical"]

  setup do
    {:ok, team} = Team |> Ash.Changeset.for_create(:create, @valid_team_attrs) |> Ash.create()
    {:ok, team: team}
  end

  test "creates an alert with a valid team_id", %{team: team} do
    changeset =
      Alert
      |> Ash.Changeset.for_create(:create, Map.put(@valid_alert_attrs, :team_id, team.id))

    assert {:ok, _alert} = Ash.create(changeset)
  end

  test "fails to create an alert with missing required fields", %{team: team} do
    changeset =
      Alert
      |> Ash.Changeset.for_create(:create, %{
        team_id: team.id
      })

    assert {:error, _changeset} = Ash.create(changeset)
  end

  test "fails to create an alert with an invalid risk_level", %{team: team} do
    check all(risk_level <- string(:alphanumeric) |> filter(&(&1 not in @valid_risk_levels))) do
      changeset =
        Alert
        |> Ash.Changeset.for_create(
          :create,
          Map.put(@valid_alert_attrs, :team_id, team.id)
          |> Map.put(:risk_level, risk_level)
        )

      assert {:error, _changeset} = Ash.create(changeset)
    end
  end

  test "create an alert even if the risk_level is not capitalized", %{team: team} do
    check all(risk_level <- member_of(@valid_risk_levels) |> map(&String.downcase/1)) do
      changeset =
        Alert
        |> Ash.Changeset.for_create(
          :create,
          Map.put(@valid_alert_attrs, :team_id, team.id)
          |> Map.put(:risk_level, risk_level)
        )

      assert {:ok, _alert} = Ash.create(changeset)
    end
  end

  test "fails to create an alert with an invalid team_id" do
    changeset =
      Alert
      |> Ash.Changeset.for_create(
        :create,
        Map.put(@valid_alert_attrs, :team_id, Ecto.UUID.generate())
      )

    assert {:error, _changeset} = Ash.create(changeset)
  end

  test "fails to create an alert where the start_time is not before the end_time", %{team: team} do
    changeset =
      Alert
      |> Ash.Changeset.for_create(
        :create,
        @valid_alert_attrs
        |> Map.put(:team_id, team.id)
        |> Map.put(:start_time, "2024-09-13T12:13:12.551Z")
        |> Map.put(:end_time, "2024-09-13T12:13:12.551Z")
      )

    assert {:error, _changeset} = Ash.create(changeset)
  end
end
