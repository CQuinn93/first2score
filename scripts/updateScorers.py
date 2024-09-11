import os
import requests
import json
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')
TABLE_NAME = "footballers"


def pull_fixtures():
    """
    Pull the fixtures data from the Fantasy Premier League API and only retrieve goalscorers for matches 
    where the kickoff_time is within the last 4 days.
    """
    URL = 'https://fantasy.premierleague.com/api/fixtures/'
    response = requests.get(URL)
    fixtures = response.json()

    goals_data = []

    # Get the current date and the date 4 days ago
    current_date = datetime.utcnow()
    four_days_ago = current_date - timedelta(days=4)

    # Loop through the fixtures
    for fixture in fixtures:
        if fixture['finished']:  # Only process finished matches
            kickoff_time_str = fixture.get('kickoff_time')

            # Convert the kickoff_time to a datetime object
            kickoff_time = datetime.strptime(kickoff_time_str, '%Y-%m-%dT%H:%M:%SZ')

            # Only include fixtures from the last 4 days
            if kickoff_time >= four_days_ago:
                gameweek = fixture['event']
                stats = fixture.get('stats', [])

                for stat in stats:
                    if stat['identifier'] == 'goals_scored':
                        # Process goals for team_a (away) and team_h (home)
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
    # Convert player_id to string and append ".0" to match the database format
    player_id_str = f"{player_id}.0"

    # API endpoint for patching data
    url = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME}?id=eq.{player_id_str}'

    # API request headers
    headers = {
        'apikey': SUPABASE_KEY,  # Ensure this is the service role key
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }

    # Data for patching (only updating last_goal_scored)
    data = {
        "last_goal_scored": gameweek  # Already a string
    }

    # Make the PATCH request to update data
    response = requests.patch(url, headers=headers, json=data)

    # Check the response status
    if response.status_code in [200, 204]:
        print(f"Player {player_id_str} updated successfully with gameweek {gameweek}.")
    else:
        print(f"Error updating player {player_id_str}: {response.status_code} - {response.text}")


def update_db_with_goals(goals_data):
    """
    Loop through the goals data and update each player using PATCH.
    """
    if not goals_data:
        print("No goals to update.")
        return

    # Loop through each player's goal data and perform the patch update
    for goal in goals_data:
        player_id = goal['player_id']
        gameweek = goal['last_goal_scored']
        update_player_goal(player_id, gameweek)


def run_weekly_update():
    """
    The main function to run the weekly update.
    """
    # Pull the fixture data and extract goalscorer information for the last 8 days
    goals_data = pull_fixtures()

    # Update the Supabase database with the last goal scored information
    update_db_with_goals(goals_data)


# Usage
run_weekly_update()
