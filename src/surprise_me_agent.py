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

class SurpriseMeAgent:
    def __init__(self, debug=False):
        self.exa = Exa(api_key=os.getenv('BEN_EXA_KEY'))
        self.location = os.getenv('LOCATION', 'Blacksburg, VA')
        self.debug = debug
        self.llm = genai.GenerativeModel('gemini-pro-latest') if gemini_api_key else None
        self.supabase: Client = create_client(supabase_url, supabase_key) if supabase_key else None

    def get_recommendations(self, member_id):
        # Main flow for surprise recommendations - uses exa and gemini to find unique experiences
        # Combines user preferences with random/unique activities for a surprise element

        # Fetch user data from Supabase
        if not self.supabase:
            print("Supabase client not initialized")
            return []
        
        try:
            # Fetch user data from Supabase, selecting columns that exist
            response = self.supabase.table('members').select('first_name, dining_preferences, wellness_preferences').eq('member_id', member_id).execute()
            if not response.data:
                print(f"No member found with ID: {member_id}")
                return []
            
            user_data = response.data[0]
            # Reconstruct a dictionary for personal info to match what the LLM prompt expects
            prefs = {'firstName': user_data.get('first_name')}
            dining_prefs = user_data.get('dining_preferences', {})
            wellness_prefs = user_data.get('wellness_preferences', {})
        except Exception as e:
            print(f"Error fetching user data: {e}")
            return []
        
        # 1. Search for unique experiences and activities
        search_query = self._build_search_query(prefs, dining_prefs, wellness_prefs)
        print(f"searching for surprise experiences with query: {search_query}")
        try:
            search_results = self.exa.search(search_query, num_results=10, use_autoprompt=True).results
        except Exception as e:
            print(f"exa search failed: {e}")
            return []

        # 2. Fetch content from websites
        print(f"found {len(search_results)} potential experiences, getting their info...")
        ids = [result.id for result in search_results]
        try:
            contents = self.exa.get_contents(ids).results
        except Exception as e:
            print(f"exa content fetch failed: {e}")
            return []

        # 3. Synthesize recommendations with surprise element
        print("concierge evaluating surprise experiences...")
        prompt = self._build_llm_prompt(contents, prefs, dining_prefs, wellness_prefs)
        
        try:
            response = self.llm.generate_content(prompt)
            cleaned_response = re.sub(r'```json\s*|\s*```', '', response.text).strip()
            if self.debug:
                print(f"--- raw gemini output ---\n{cleaned_response}\n--------------------")
            
            experiences = json.loads(cleaned_response)
            
            # Save recommendations to Supabase
            self._save_recommendations(member_id, experiences)
            
            return experiences

        except Exception as e:
            print(f"no results")
            if self.debug:
                print(f"    err: {e}")
            return []

    def _build_search_query(self, prefs, dining_prefs, wellness_prefs):
        # Build search query for unique experiences based on user profile
        query_parts = [f"unique experiences activities in {self.location}"]
        
        # Add surprise elements
        query_parts.append("hidden gems local secrets")
        query_parts.append("unusual activities off the beaten path")
        
        # Add preferences-based elements
        if dining_prefs.get('diningStyle') == 'Fine dining':
            query_parts.append("exclusive dining experiences")
        
        if wellness_prefs.get('spa', {}).get('treatmentTypes'):
            query_parts.append("unique wellness experiences")
        
        # Add seasonal/random elements
        query_parts.append("surprise activities today")
        
        return ' '.join(query_parts)

    def _build_llm_prompt(self, contents, prefs, dining_prefs, wellness_prefs):
        # Build prompt for surprise recommendations
        first_name = prefs.get('firstName', 'Guest')
        
        prompt = f"""
        You are a creative hotel concierge providing SURPRISE recommendations for {first_name}. 
        
        User Profile:
        - Name: {first_name}
        - Dining Style: {dining_prefs.get('diningStyle', 'Not specified')}
        - Wellness Interests: {wellness_prefs.get('spa', {}).get('treatmentTypes', [])}
        - Cuisine Preferences: {dining_prefs.get('cuisinePreferences', [])}
        
        Based *only* on the following context from local experience websites, generate a personalized list of 3-8 SURPRISE recommendations that are unexpected, unique, and tailored to surprise this guest. Focus on:
        - Hidden gems and local secrets
        - Unusual or off-the-beaten-path experiences
        - Activities they wouldn't typically think of
        - Mix of dining, entertainment, and unique local experiences

        Your response MUST be a single, valid JSON array of objects. Do not include any introductory text, markdown formatting, or explanations outside of the JSON itself. Each object in the array must have the following keys: "name", "description", "url", "surprise_factor".
        - 'name': The name of the experience/venue.
        - 'description': A compelling description (3-4 sentences) explaining why this is a surprise and how it fits their profile. Mention specific details that make it unique.
        - 'url': The original URL of the website.
        - 'surprise_factor': A rating from 1-10 indicating how surprising/unexpected this recommendation is.

        Here is the content from the websites:
        """
        
        for content in contents:
            prompt += f"\n\n--- Website Content from {content.url} ---\n"
            prompt += content.text
        
        prompt += "\n\n--- End of Website Content ---"
        prompt += "\nNow, generate the JSON array of surprise recommendations as instructed. Focus on experiences that will genuinely surprise and delight this guest."
        return prompt

    def _save_recommendations(self, member_id, recommendations):
        """Save recommendations to Supabase recommendations table"""
        if not self.supabase or not recommendations:
            return
        
        try:
            # Prepare data for insertion
            recommendation_data = {
                'member_id': member_id,
                'category': 'surprise',
                'location': self.location,
                'description': recommendations
            }
            
            # Insert into recommendations table
            response = self.supabase.table('recommendations').insert(recommendation_data).execute()
            print(f"Saved {len(recommendations)} surprise recommendations to Supabase")
            
        except Exception as e:
            print(f"Error saving recommendations to Supabase: {e}")

if __name__ == "__main__":
    # Test with a member ID from Supabase
    agent = SurpriseMeAgent(debug=False)
    
    # Use a test member ID - you can get this from your Supabase members table
    test_member_id = "MB789456123"  # From your user_preferences.json
    
    recs = agent.get_recommendations(test_member_id)
    
    if recs:
        print(f"Surprise Recommendations!")
        print(f"Here are some unexpected experiences we think you'll love:\n")
        
        for i, r in enumerate(recs, 1):
            surprise_factor = r.get('surprise_factor', 'N/A')
            print(f"{i}. {r.get('name', 'N/A')} (Surprise Factor: {surprise_factor}/10)")
            print(f"   {r.get('description', 'N/A')}")
            print(f"   {r.get('url', 'N/A')}\n")
    else:
        print("no results")
    
    print("Recommendations saved to Supabase recommendations table")
