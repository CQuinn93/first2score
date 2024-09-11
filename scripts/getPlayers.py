import json
import os
import pandas as pd
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_ANON_KEY')
TABLE_NAME = "footballers"


def pull_data():
    # Pull data from Fantasy.PremierLeague.com
    URL = 'https://fantasy.premierleague.com/api/bootstrap-static/'
    RESPONSE = requests.get(URL)
    ELEMENTS = RESPONSE.json()['elements']

    # Create a DataFrame with the required columns
    DF = pd.DataFrame(
        columns=['id', 'first_name', 'last_name', 'web_name', 'position', 'team', 'expected_goals', 'expected_assists',
                 'news']
    )

    # Set the DataFrame columns to the correct data types
    DF = DF.astype({
        'id': 'int',
        'first_name': 'object',
        'last_name': 'object',
        'web_name': 'object',
        'position': 'int',
        'team': 'int',
        'expected_goals': 'float',
        'expected_assists': 'float',
        'news': 'object'
    })

    # Populate the DataFrame with the data from the API response
    for i, item in enumerate(ELEMENTS):
        DF.at[i, 'id'] = int(item['id'])  # Ensure it's an integer
        DF.at[i, 'first_name'] = str(item['first_name'])
        DF.at[i, 'last_name'] = str(item['second_name'])
        DF.at[i, 'web_name'] = str(item['web_name'])
        DF.at[i, 'position'] = int(item['element_type'])  # Ensure it's an integer
        DF.at[i, 'team'] = int(item['team'])  # Ensure it's an integer
        DF.at[i, 'expected_goals'] = float(item.get('expected_goals', 0.0))  # Ensure it's a float
        DF.at[i, 'expected_assists'] = float(item.get('expected_assists', 0.0))  # Ensure it's a float
        DF.at[i, 'news'] = str(item.get('news', ''))  # Convert to string, default to empty if missing

    DF.to_csv("playerData.csv", encoding="utf-8-sig", index=False)


def read_and_update_db(csv_file_path):
    # Read the CSV file into a DataFrame with UTF-8 encoding
    df = pd.read_csv(csv_file_path, encoding='utf-8-sig')

    # Check if DataFrame is empty
    if df.empty:
        print("Error: DataFrame is empty. No data to update.")
        return

    # Clean DataFrame to remove potential NaNs or invalid data
    df = df.fillna('')  # Replace NaNs with empty strings
    df = df.dropna()  # Drop any rows that are still invalid

    # Convert DataFrame to JSON with special characters preserved
    data = json.loads(df.to_json(orient='records', force_ascii=False))

    # Debug: Ensure that data is not empty and is well-formed
    if not data:
        print("Error: Converted JSON data is empty.")
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

    # Debug: Print the JSON data being sent
    print("Sending the following JSON data to Supabase:")

    # Make the POST request to insert data
    response = requests.post(url, headers=headers, json=data)

    # Check the response from Supabase
    if response.status_code in [201, 204]:
        print('Data inserted successfully!')
    else:
        print(f'Error: {response.status_code} - {response.text}')


# Usage
pull_data()
read_and_update_db('playerData.csv')
