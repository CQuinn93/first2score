import requests
from datetime import datetime, timedelta
import os

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')
TABLE_NAME_FOOTBALLERS = "footballers"
TABLE_NAME_SELECTIONS = "selections"


def pull_fixtures():
    """
    Pull the fixtures data from the Fantasy Premier League API and only retrieve goalscorers for matches 
    where the kickoff_time is within the last day.
    """
    URL = 'https://fantasy.premierleague.com/api/fixtures/'
    response = requests.get(URL)
    fixtures = response.json()

    goals_data = []
    current_date = datetime.utcnow()
    four_days_ago = current_date - timedelta(days=1)

    # Loop through the fixtures
    for fixture in fixtures:
        if fixture['finished']:  # Only process finished matches
            kickoff_time_str = fixture.get('kickoff_time')
            kickoff_time = datetime.strptime(kickoff_time_str, '%Y-%m-%dT%H:%M:%SZ')

            if kickoff_time >= four_days_ago:
                gameweek = fixture['event']
                stats = fixture.get('stats', [])

                for stat in stats:
                    if stat['identifier'] == 'goals_scored':
                        for goal_scorer in stat['a']:  # Away team goals
                            goals_data.append({'player_id': goal_scorer['element'], 'last_goal_scored': str(gameweek)})
                        for goal_scorer in stat['h']:  # Home team goals
                            goals_data.append({'player_id': goal_scorer['element'], 'last_goal_scored': str(gameweek)})

    return goals_data


def update_player_goal(player_id, gameweek):
    """
    Update the footballer's last_goal_scored column using PATCH.
    Only update the last_goal_scored column and leave other fields untouched.
    """
    player_id_str = f"{player_id}.0"
    url = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME_FOOTBALLERS}?id=eq.{player_id_str}'

    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }

    data = {
        "last_goal_scored": gameweek
    }

    response = requests.patch(url, headers=headers, json=data)

    if response.status_code in [200, 204]:
        print(f"Player {player_id_str} updated successfully with gameweek {gameweek}.")
    else:
        print(f"Error updating player {player_id_str}: {response.status_code} - {response.text}")


def batch_update_selections(goal_scorers):
    """
    Perform a batch update to the selections table for the players who scored.
    This function will update hasScored to TRUE and set the correct gameweek_scored.
    """
    if not goal_scorers:
        return

    # Build the filter for updating the selections
    player_ids = [f"{goal['player_id']}.0" for goal in goal_scorers]

    # Fetch selections where hasScored is false and the player is in the goal_scorers list
    url_selections = f"{SUPABASE_URL}/rest/v1/{TABLE_NAME_SELECTIONS}?player_id=in.({','.join(player_ids)})&hasScored=is.false"

    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }

    response_selections = requests.get(url_selections, headers=headers)

    if response_selections.status_code == 200:
        selections = response_selections.json()

        for selection in selections:
            player_id = selection['player_id']
            competition_id = selection['competition_id']
            gameweek_scored = next((goal['last_goal_scored'] for goal in goal_scorers if goal['player_id'] == int(player_id)), None)

            if gameweek_scored:
                # Add WHERE condition to specify which rows to update
                url_update = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME_SELECTIONS}?player_id=eq.{player_id}&competition_id=eq.{competition_id}&hasScored=is.false'

                # Data to update
                data = {
                    "hasScored": True,
                    "gameweek_scored": gameweek_scored
                }

                response_update = requests.patch(url_update, headers=headers, json=data)

                if response_update.status_code in [200, 204]:
                    print(f"Selections updated successfully for player {player_id}.")
                else:
                    print(f"Error updating selections for player {player_id}: {response_update.status_code} - {response_update.text}")
    else:
        print(f"Error fetching selections: {response_selections.status_code} - {response_selections.text}")


def update_db_with_goals(goals_data):
    """
    Loop through the goals data and update each player in the footballers and selections table.
    """
    if not goals_data:
        print("No goals to update.")
        return

    # Update the footballers table for all goals
    for goal in goals_data:
        player_id = goal['player_id']
        gameweek = goal['last_goal_scored']
        update_player_goal(player_id, gameweek)

    # Batch update the selections table based on goals scored
    batch_update_selections(goals_data)


def run_weekly_update():
    """
    The main function to run the weekly update.
    """
    goals_data = pull_fixtures()

    # Update the Supabase database with the last goal scored and selections
    update_db_with_goals(goals_data)


# Usage
run_weekly_update()
