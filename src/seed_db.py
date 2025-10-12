import os
import json
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

# Supabase configuration
supabase_url = "https://ivnzekvuouiqasshhlml.supabase.co"
supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def seed_database():
    """
    Seeds the Supabase 'members' table with data from user_preferences.json.
    This script maps the JSON data structure to the database schema.
    """
    if not supabase_key:
        print("Error: SUPABASE_SERVICE_ROLE_KEY not found in .env file.")
        return

    supabase: Client = create_client(supabase_url, supabase_key)

    try:
        with open('user_preferences.json', 'r', encoding='utf-8') as f:
            user_data = json.load(f)
    except FileNotFoundError:
        print("Error: user_preferences.json not found in the same directory.")
        return
    except json.JSONDecodeError as e:
        print(f"Error decoding user_preferences.json: {e}")
        return

    # Transform data to match Supabase schema (camelCase to snake_case and flatten)
    account_info = user_data.get('accountInfo', {})
    personal_info = user_data.get('personalInfo', {})
    
    member_id = account_info.get('memberId')
    if not member_id:
        print("Error: memberId not found in user_preferences.json")
        return

    # Check if member already exists to prevent duplicates
    try:
        response = supabase.table('members').select('member_id').eq('member_id', member_id).execute()
        if response.data:
            print(f"Member with ID {member_id} already exists. Skipping insertion.")
            return
    except Exception as e:
        print(f"Error checking for existing member: {e}")
        return

    member_record = {
        'member_id': account_info.get('memberId'),
        'username': account_info.get('username'),
        'email': account_info.get('email'),
        'phone': account_info.get('phone'),
        'first_name': personal_info.get('firstName'),
        'last_name': personal_info.get('lastName'),
        'date_of_birth': personal_info.get('dateOfBirth'),
        'member_since': account_info.get('memberSince'),
        'elite_status': account_info.get('eliteStatus'),
        'lifetime_nights': account_info.get('lifetimeNights'),
        'current_year_nights': account_info.get('currentYearNights'),
        'points_balance': account_info.get('pointsBalance'),
        'address': personal_info.get('address'),
        'emergency_contact': personal_info.get('emergencyContact'),
        'room_preferences': user_data.get('roomPreferences'),
        'dining_preferences': user_data.get('diningPreferences'),
        'service_preferences': user_data.get('servicePreferences'),
        'wellness_preferences': user_data.get('wellnessPreferences'),
        'business_preferences': user_data.get('businessPreferences'),
        'loyalty_preferences': user_data.get('loyaltyPreferences'),
        'transportation_preferences': user_data.get('transportationPreferences'),
        'special_occasions': user_data.get('specialOccasions'),
        'travel_companions_meta': user_data.get('travelCompanions'),
        'cultural_preferences': user_data.get('culturalPreferences'),
        'technology_preferences': user_data.get('technologyPreferences'),
    }

    try:
        # Insert the transformed record into the members table
        response = supabase.table('members').insert(member_record).execute()
        print(f"Successfully seeded member data for {member_id} to Supabase.")
        
    except Exception as e:
        print(f"Error inserting data into Supabase: {e}")


if __name__ == "__main__":
    seed_database()
