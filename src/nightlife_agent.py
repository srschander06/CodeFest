import os
import json
import re
import time
import google.generativeai as genai
from exa_py import Exa
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

gemini_api_key = os.getenv('GEMINI_KEY')
if gemini_api_key:
    genai.configure(api_key=gemini_api_key)

# Supabase configuration
supabase_url = "https://ivnzekvuouiqasshhlml.supabase.co"
supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

class NightlifeAgent:
    def __init__(self, debug=False):
        self.exa = Exa(api_key=os.getenv('BEN_EXA_KEY'))
        self.location = os.getenv('LOCATION', 'Blacksburg, VA')
        self.debug = debug
        self.llm = genai.GenerativeModel('gemini-pro-latest') if gemini_api_key else None
        self.supabase: Client = create_client(supabase_url, supabase_key) if supabase_key else None

    def get_recommendations(self, member_id):
        # Main flow for nightlife recommendations - uses exa and gemini to find evening entertainment
        # Tailored to user preferences and evening activities

        # Fetch user data from Supabase
        if not self.supabase:
            print("Supabase client not initialized")
            return []
        
        try:
            # Fetch user data from Supabase, selecting columns that exist
            response = self.supabase.table('members').select('first_name, dining_preferences, service_preferences, special_occasions').eq('member_id', member_id).execute()
            if not response.data:
                print(f"No member found with ID: {member_id}")
                return []
            
            user_data = response.data[0]
            # Reconstruct a dictionary for personal info to match what the LLM prompt expects
            prefs = {'firstName': user_data.get('first_name')}
            dining_prefs = user_data.get('dining_preferences', {})
            service_prefs = user_data.get('service_preferences', {})
            special_prefs = user_data.get('special_occasions', {})
        except Exception as e:
            print(f"Error fetching user data: {e}")
            return []
        
        # 1. Search for nightlife venues and evening entertainment
        search_query = self._build_search_query(prefs, dining_prefs, service_prefs, special_prefs)
        print(f"searching for nightlife with query: {search_query}")
        try:
            search_results = self.exa.search(search_query, num_results=10, use_autoprompt=True).results
        except Exception as e:
            print(f"exa search failed: {e}")
            return []

        # 2. Fetch content from websites
        print(f"found {len(search_results)} potential nightlife venues, getting their info...")
        ids = [result.id for result in search_results]
        try:
            contents = self.exa.get_contents(ids).results
        except Exception as e:
            print(f"exa content fetch failed: {e}")
            return []

        # 3. Synthesize recommendations
        print("concierge evaluating nightlife options...")
        prompt = self._build_llm_prompt(contents, prefs, dining_prefs, service_prefs, special_prefs)
        
        try:
            response = self.llm.generate_content(prompt)
            cleaned_response = re.sub(r'```json\s*|\s*```', '', response.text).strip()
            if self.debug:
                print(f"--- raw gemini output ---\n{cleaned_response}\n--------------------")
            
            venues = json.loads(cleaned_response)
            
            # Save recommendations to Supabase
            self._save_recommendations(member_id, venues)
            
            return venues

        except Exception as e:
            print(f"no results")
            if self.debug:
                print(f"    err: {e}")
            return []

    def _build_search_query(self, prefs, dining_prefs, service_prefs, special_prefs):
        # Build search query for nightlife based on user preferences
        query_parts = [f"nightlife bars clubs in {self.location}"]
        
        # Add general nightlife types
        query_parts.append("live music venues")
        query_parts.append("cocktail bars lounges")
        query_parts.append("dance clubs entertainment")
        
        # Add dining-related nightlife
        if dining_prefs.get('diningStyle') == 'Fine dining':
            query_parts.append("upscale bars fine dining")
        
        if dining_prefs.get('beveragePreferences', {}).get('alcohol'):
            alcohol_prefs = dining_prefs.get('beveragePreferences', {}).get('alcohol', '')
            if 'wine' in alcohol_prefs.lower():
                query_parts.append("wine bars")
            if 'sake' in alcohol_prefs.lower():
                query_parts.append("sake bars")
        
        # Add music preferences
        if special_prefs.get('musicPreference'):
            music_prefs = special_prefs.get('musicPreference', '')
            if 'jazz' in music_prefs.lower():
                query_parts.append("jazz clubs")
            if 'classical' in music_prefs.lower():
                query_parts.append("classical music venues")
        
        # Add evening timing preferences
        typical_dinner_time = dining_prefs.get('typicalDinnerTime', '19:00')
        if typical_dinner_time:
            query_parts.append("late night entertainment")
        
        # Add do not disturb hours consideration
        dnd_hours = service_prefs.get('communication', {}).get('doNotDisturbHours', '22:00-07:00')
        if '22:00' in dnd_hours:
            query_parts.append("early evening venues")
        
        return ' '.join(query_parts)

    def _build_llm_prompt(self, contents, prefs, dining_prefs, service_prefs, special_prefs):
        # Build prompt for nightlife recommendations
        first_name = prefs.get('firstName', 'Guest')
        
        prompt = f"""
        You are a helpful hotel concierge providing nightlife recommendations for {first_name}. 
        
        User Profile:
        - Name: {first_name}
        - Dining Style: {dining_prefs.get('diningStyle', 'Not specified')}
        - Alcohol Preferences: {dining_prefs.get('beveragePreferences', {}).get('alcohol', 'Not specified')}
        - Music Preferences: {special_prefs.get('musicPreference', 'Not specified')}
        - Typical Dinner Time: {dining_prefs.get('typicalDinnerTime', 'Not specified')}
        - Do Not Disturb Hours: {service_prefs.get('communication', {}).get('doNotDisturbHours', 'Not specified')}
        
        Based *only* on the following context from local nightlife venue websites, generate a personalized list of the TOP 5-12 nightlife recommendations that are the best fit for this guest. Focus on:
        - Venues matching their dining style and alcohol preferences
        - Music venues aligned with their taste
        - Timing that respects their schedule (dinner time, do not disturb hours)
        - Mix of casual and upscale options
        - Live music, bars, lounges, and entertainment venues

        Your response MUST be a single, valid JSON array of objects. Do not include any introductory text, markdown formatting, or explanations outside of the JSON itself. Each object in the array must have the following keys: "name", "description", "url", "venue_type", "best_time", "dress_code".
        - 'name': The name of the venue.
        - 'description': A detailed description (3-4 sentences) tailored to the guest. Mention specific features, atmosphere, music, or drinks that match their preferences.
        - 'url': The original URL of the website.
        - 'venue_type': The type of venue (e.g., "Cocktail Bar", "Live Music Venue", "Dance Club", "Lounge", "Wine Bar").
        - 'best_time': Recommended time to visit (e.g., "7-9 PM", "9-11 PM", "After 10 PM").
        - 'dress_code': Recommended dress code (e.g., "Casual", "Smart Casual", "Upscale", "Dressy").

        Here is the content from the websites:
        """
        
        for content in contents:
            prompt += f"\n\n--- Website Content from {content.url} ---\n"
            prompt += content.text
        
        prompt += "\n\n--- End of Website Content ---"
        prompt += "\nNow, generate the JSON array of nightlife recommendations as instructed. Ensure you provide a variety of different types of venues and consider their schedule preferences."
        return prompt

    def _save_recommendations(self, member_id, recommendations):
        """Save recommendations to Supabase recommendations table"""
        if not self.supabase or not recommendations:
            return
        
        try:
            # Prepare data for insertion
            recommendation_data = {
                'member_id': member_id,
                'category': 'nightlife',
                'location': self.location,
                'description': recommendations
            }
            
            # Insert into recommendations table
            response = self.supabase.table('recommendations').insert(recommendation_data).execute()
            print(f"Saved {len(recommendations)} nightlife recommendations to Supabase")
            
        except Exception as e:
            print(f"Error saving recommendations to Supabase: {e}")

if __name__ == "__main__":
    # Test with a member ID from Supabase
    agent = NightlifeAgent(debug=False)
    
    # Use a test member ID - you can get this from your Supabase members table
    test_member_id = "MB789456123"  # From your user_preferences.json
    
    recs = agent.get_recommendations(test_member_id)
    
    if recs:
        print(f"Nightlife Recommendations!")
        print(f"Here are the best evening entertainment options for your visit:\n")
        
        for i, r in enumerate(recs, 1):
            venue_type = r.get('venue_type', 'N/A')
            best_time = r.get('best_time', 'N/A')
            dress_code = r.get('dress_code', 'N/A')
            print(f"{i}. {r.get('name', 'N/A')} ({venue_type})")
            print(f"   Best Time: {best_time} | Dress Code: {dress_code}")
            print(f"   {r.get('description', 'N/A')}")
            print(f"   {r.get('url', 'N/A')}\n")
    else:
        print("no results")
    
    print("Recommendations saved to Supabase recommendations table")
