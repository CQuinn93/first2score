import os
import requests

# Set up your Supabase URL and API key
SUPABASE_URL = 'SUPABASE_URL'
SUPABASE_KEY = 'SUPABASE_ANON_KEY'
# Define the table name where the data will be inserted
TABLE_NAME = "gameweek"


def pull_gameweeks():
    """
    Pull gameweek data from the Fantasy Premier League API.
    Extract 'id' (gameweek number) and 'deadline_time' for each gameweek.
    """
    # FPL API URL for gameweek data
    URL = 'https://fantasy.premierleague.com/api/bootstrap-static/'
    
    # Make the request to FPL API
    response = requests.get(URL)
    
    # Check if the response is valid
    if response.status_code != 200:
        print(f"Error fetching gameweek data: {response.status_code}")
        return []

    # Parse the JSON response
    data = response.json()
    
    # Extract gameweek information from the 'events' section
    events = data.get('events', [])
    
    gameweeks_data = []
    
    # Loop through the events (gameweeks) and extract relevant data
    for event in events:
        gameweek_number = event.get('id')  # Use 'id' for the gameweek number
        deadline_time = event.get('deadline_time')
        
        # If both gameweek_number and deadline_time are present, add them to the list
        if gameweek_number and deadline_time:
            gameweeks_data.append({
                'gameweek_id': gameweek_number,  # Use 'gameweek_id' as the field name
                'deadline_time': deadline_time
            })
    
    return gameweeks_data


def upsert_gameweek_into_db(gameweek):
    """
    Insert or update (upsert) a single gameweek into the Supabase database.
    """
    url = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME}'

    # Prepare headers for Supabase API request
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates'  # Use upsert functionality
    }

    # Make the POST request to upsert gameweek data
    response = requests.post(url, headers=headers, json=gameweek)

    # Check if the upsert was successful
    if response.status_code in [200, 201]:
        print(f"Gameweek {gameweek['gameweek_id']} upserted successfully.")
    else:
        print(f"Error upserting gameweek {gameweek['gameweek_id']}: {response.status_code} - {response.text}")


def upsert_gameweeks(gameweeks_data):
    """
    Upsert all gameweeks data into the Supabase database.
    """
    if not gameweeks_data:
        print("No gameweeks data to upsert.")
        return

    # Loop through each gameweek and upsert it into the database
    for gameweek in gameweeks_data:
        upsert_gameweek_into_db(gameweek)


def run_gameweek_update():
    """
    Main function to pull gameweek data and upsert it into the Supabase database.
    """
    # Step 1: Pull gameweek data from FPL API
    gameweeks_data = pull_gameweeks()

    # Step 2: Upsert the pulled gameweek data into the Supabase database
    upsert_gameweeks(gameweeks_data)


# Run the gameweek update process
if __name__ == "__main__":
    run_gameweek_update()
