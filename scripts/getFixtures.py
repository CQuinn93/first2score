import os
import requests

# Set up your Supabase URL and API key from environment variables
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')

# Define the table name where the data will be inserted
TABLE_NAME = "games"
BATCH_SIZE = 500  # Supabase recommends a maximum of 500 rows per insert/upsert request


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
        match_id = fixture.get('id')    # match ID
        gameweek = fixture.get('event')  # Gameweek number
        home_team = fixture.get('team_h')  # Home team ID
        away_team = fixture.get('team_a')  # Away team ID
        home_score = fixture.get('team_h_score')  # Home team score (if available)
        away_score = fixture.get('team_a_score')  # Away team score (if available)
        finished = fixture.get('finished') # Match status
        
        # Add the fixture data to the list
        fixtures_data.append({
            'match_id': match_id,
            'gameweek': gameweek,
            'home_team': home_team,
            'away_team': away_team,
            'home_score': home_score if home_score is not None else None,
            'away_score': away_score if away_score is not None else None,
            'finished': finished
        })
    
    return fixtures_data


def upsert_fixtures_batch(fixtures_batch):
    """
    Batch insert or update (upsert) a list of fixtures into the Supabase database.
    """
    url = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME}'

    # Prepare headers for Supabase API request
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates'  # Use upsert functionality
    }

    # Make the POST request to upsert batch fixture data
    response = requests.post(url, headers=headers, json=fixtures_batch)

    # Check if the upsert was successful
    if response.status_code in [200, 201]:
        print(f"Batch of {len(fixtures_batch)} fixtures upserted successfully.")
    else:
        print(f"Error upserting batch: {response.status_code} - {response.text}")


def upsert_fixtures(fixtures_data):
    """
    Upsert all fixtures data into the Supabase database in batches.
    """
    if not fixtures_data:
        print("No fixtures data to upsert.")
        return

    # Split fixtures_data into batches
    for i in range(0, len(fixtures_data), BATCH_SIZE):
        batch = fixtures_data[i:i + BATCH_SIZE]
        upsert_fixtures_batch(batch)


def run_fixtures_update():
    """
    Main function to pull fixtures data and upsert it into the Supabase database.
    """
    # Step 1: Pull fixtures data from FPL API
    fixtures_data = pull_fixtures()

    # Step 2: Upsert the pulled fixtures data into the Supabase database in batches
    upsert_fixtures(fixtures_data)


# Run the fixtures update process
if __name__ == "__main__":
    run_fixtures_update()
