import json
import requests
import os

# Get Supabase URL and API Key from environment variables
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')
TABLE_NAME = "footballers"

def pull_data():
    """
    Pull data from Fantasy Premier League API and store required fields in a list of dictionaries.
    """
    URL = 'https://fantasy.premierleague.com/api/bootstrap-static/'
    response = requests.get(URL)
    elements = response.json()['elements']

    # Prepare data to be uploaded to the Supabase DB
    player_data = []
    
    for item in elements:
        player = {
            'id': int(item['id']),
            'first_name': str(item['first_name']),
            'last_name': str(item['second_name']),
            'web_name': str(item['web_name']),
            'position': int(item['element_type']),
            'team': int(item['team']),
            'expected_goals': float(item.get('expected_goals', 0.0)),
            'expected_assists': float(item.get('expected_assists', 0.0)),
            'news': str(item.get('news', ''))
        }
        player_data.append(player)

    # Save the data as a JSON file (optional)
    with open('playerData.json', 'w', encoding='utf-8') as f:
        json.dump(player_data, f, ensure_ascii=False, indent=4)

    return player_data


def update_db(player_data):
    """
    Update the Supabase database with the player data.
    """
    if not player_data:
        print("Error: No player data to update.")
        return

    # API endpoint for inserting data
    url = f'{SUPABASE_URL}/rest/v1/{TABLE_NAME}'

    # API request headers
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates'
    }

    # Make the POST request to insert data
    response = requests.post(url, headers=headers, json=player_data)

    # Check the response from Supabase
    if response.status_code in [201, 204]:
        print('Data inserted successfully!')
    else:
        print(f'Error: {response.status_code} - {response.text}')


if __name__ == "__main__":
    # Fetch data and update database
    player_data = pull_data()
    update_db(player_data)
