import os
import requests

# Set up your Supabase URL and API key from environment variables
SUPABASE_URL = 'https://tdbezgjqthdvrtxgvoao.supabase.co'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkYmV6Z2pxdGhkdnJ0eGd2b2FvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMzExNjU2NCwiZXhwIjoyMDM4NjkyNTY0fQ.rCTliFmz5DA3JLc6zXEpZr_ikCMv8N4E6I9jxk0v_Vk'

# Define the table name where the data will be inserted
TABLE_NAME = "games"

def pull_fixtures():
    """
    Pull fixtures data from the Fantasy Premier League API.
    Extract 'event' (gameweek), 'team_h' (home team), 'team_a' (away team),
    and if available, the 'team_h_score' (home score) and 'team_a_score' (away score).
    """
    # FPL API URL for fixtures data
    URL = 'https://fantasy.premierleague.com/api/fixtures/'
    
    # Make the request to FPL API
    response = requests.get(URL)
    
    # Check if the response is valid
    if response.status_code != 200:
        print(f"Error fetching fixtures data: {response.status_code}")
        return []

    # Parse the JSON response
    fixtures = response.json()
    
    fixtures_data = []
    
    # Loop through the fixtures and extract relevant data
    for fixture in fixtures:
        gameweek = fixture.get('event')  # Gameweek number
        home_team = fixture.get('team_h')  # Home team ID
        away_team = fixture.get('team_a')  # Away team ID
        home_score = fixture.get('team_h_score')  # Home team score (if available)
        away_score = fixture.get('team_a_score')  # Away team score (if available)
        
        # Add the fixture data to the list
        fixtures_data.append({
            'gameweek': gameweek,
            'home_team': home_team,
            'away_team': away_team,
            'home_score': home_score if home_score is not None else None,
            'away_score': away_score if away_score is not None else None
        })
    
    return fixtures_data


def upsert_fixture_into_db(fixture):
    """
    Insert or update (upsert) a single fixture into the Supabase database.
    """
    url = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME}'

    # Prepare headers for Supabase API request
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates'  # Use upsert functionality
    }

    # Make the POST request to upsert fixture data
    response = requests.post(url, headers=headers, json=fixture)

    # Check if the upsert was successful
    if response.status_code in [200, 201]:
        print(f"Fixture for gameweek {fixture['gameweek']} (Home: {fixture['home_team']} vs Away: {fixture['away_team']}) upserted successfully.")
    else:
        print(f"Error upserting fixture for gameweek {fixture['gameweek']}: {response.status_code} - {response.text}")


def upsert_fixtures(fixtures_data):
    """
    Upsert all fixtures data into the Supabase database.
    """
    if not fixtures_data:
        print("No fixtures data to upsert.")
        return

    # Loop through each fixture and upsert it into the database
    for fixture in fixtures_data:
        upsert_fixture_into_db(fixture)


def run_fixtures_update():
    """
    Main function to pull fixtures data and upsert it into the Supabase database.
    """
    # Step 1: Pull fixtures data from FPL API
    fixtures_data = pull_fixtures()

    # Step 2: Upsert the pulled fixtures data into the Supabase database
    upsert_fixtures(fixtures_data)


# Run the fixtures update process
    run_fixtures_update()
