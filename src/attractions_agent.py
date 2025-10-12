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

class AttractionsAgent:
    def __init__(self, debug=False):
        self.exa = Exa(api_key=os.getenv('BEN_EXA_KEY'))
        self.location = os.getenv('LOCATION', 'Blacksburg, VA')
        self.debug = debug
        self.llm = genai.GenerativeModel('gemini-pro-latest') if gemini_api_key else None
        self.supabase: Client = create_client(supabase_url, supabase_key) if supabase_key else None

    def get_recommendations(self, member_id):
        # Main flow for attractions recommendations - uses exa and gemini to find local attractions
        # Tailored to user preferences and interests

        # Fetch user data from Supabase
        if not self.supabase:
            print("Supabase client not initialized")
            return []
        
        try:
            # Fetch user data from Supabase, selecting columns that exist
            response = self.supabase.table('members').select('first_name, wellness_preferences, cultural_preferences, business_preferences').eq('member_id', member_id).execute()
            if not response.data:
                print(f"No member found with ID: {member_id}")
                return []
            
            user_data = response.data[0]
            # Reconstruct a dictionary for personal info to match what the LLM prompt expects
            prefs = {'firstName': user_data.get('first_name')}
            wellness_prefs = user_data.get('wellness_preferences', {})
            cultural_prefs = user_data.get('cultural_preferences', {})
            business_prefs = user_data.get('business_preferences', {})
        except Exception as e:
            print(f"Error fetching user data: {e}")
            return []
        
        # 1. Search for local attractions and points of interest
        search_query = self._build_search_query(prefs, wellness_prefs, cultural_prefs, business_prefs)
        print(f"searching for attractions with query: {search_query}")
        try:
            search_results = self.exa.search(search_query, num_results=10, use_autoprompt=True).results
        except Exception as e:
            print(f"exa search failed: {e}")
            return []

        # 2. Fetch content from websites
        print(f"found {len(search_results)} potential attractions, getting their info...")
        ids = [result.id for result in search_results]
        try:
            contents = self.exa.get_contents(ids).results
        except Exception as e:
            print(f"exa content fetch failed: {e}")
            return []

        # 3. Synthesize recommendations
        print("concierge evaluating attractions...")
        prompt = self._build_llm_prompt(contents, prefs, wellness_prefs, cultural_prefs, business_prefs)
        
        try:
            response = self.llm.generate_content(prompt)
            cleaned_response = re.sub(r'```json\s*|\s*```', '', response.text).strip()
            if self.debug:
                print(f"--- raw gemini output ---\n{cleaned_response}\n--------------------")
            
            attractions = json.loads(cleaned_response)
            
            # Save recommendations to Supabase
            self._save_recommendations(member_id, attractions)
            
            return attractions

        except Exception as e:
            print(f"no results")
            if self.debug:
                print(f"    err: {e}")
            return []

    def _build_search_query(self, prefs, wellness_prefs, cultural_prefs, business_prefs):
        # Build search query for attractions based on user interests
        query_parts = [f"attractions things to do in {self.location}"]
        
        # Add general attraction types
        query_parts.append("museums landmarks")
        query_parts.append("parks outdoor activities")
        query_parts.append("entertainment venues")
        
        # Add wellness-based attractions
        if wellness_prefs.get('fitness', {}).get('fitnessClasses'):
            query_parts.append("fitness outdoor activities")
        
        if wellness_prefs.get('spa', {}).get('treatmentTypes'):
            query_parts.append("wellness attractions")
        
        # Add cultural interests
        if cultural_prefs.get('culturalAmenities') != 'None':
            query_parts.append("cultural attractions")
        
        # Add business-related attractions
        if business_prefs.get('companyName'):
            query_parts.append("corporate attractions business venues")
        
        # Add seasonal elements
        query_parts.append("current events today")
        
        return ' '.join(query_parts)

    def _build_llm_prompt(self, contents, prefs, wellness_prefs, cultural_prefs, business_prefs):
        # Build prompt for attractions recommendations
        first_name = prefs.get('firstName', 'Guest')
        
        prompt = f"""
        You are a helpful hotel concierge providing attraction recommendations for {first_name}. 
        
        User Profile:
        - Name: {first_name}
        - Fitness Interests: {wellness_prefs.get('fitness', {}).get('fitnessClasses', [])}
        - Wellness Interests: {wellness_prefs.get('spa', {}).get('treatmentTypes', [])}
        - Cultural Preferences: {cultural_prefs.get('culturalAmenities', 'None')}
        - Business Context: {business_prefs.get('companyName', 'Not specified')}
        
        Based *only* on the following context from local attraction websites, generate a personalized list of the TOP 5-12 attraction recommendations that are the best fit for this guest. Focus on:
        - Must-see landmarks and popular attractions
        - Activities matching their interests (fitness, wellness, cultural)
        - Mix of indoor and outdoor experiences
        - Family-friendly options if applicable
        - Current events and seasonal activities

        Your response MUST be a single, valid JSON array of objects. Do not include any introductory text, markdown formatting, or explanations outside of the JSON itself. Each object in the array must have the following keys: "name", "description", "url", "category", "best_time".
        - 'name': The name of the attraction.
        - 'description': A detailed description (3-4 sentences) tailored to the guest. Mention specific features, activities, or highlights that match their interests.
        - 'url': The original URL of the website.
        - 'category': The type of attraction (e.g., "Museum", "Park", "Landmark", "Entertainment", "Wellness").
        - 'best_time': Recommended time to visit (e.g., "Morning", "Afternoon", "Evening", "Anytime").

        Here is the content from the websites:
        """
        
        for content in contents:
            prompt += f"\n\n--- Website Content from {content.url} ---\n"
            prompt += content.text
        
        prompt += "\n\n--- End of Website Content ---"
        prompt += "\nNow, generate the JSON array of attraction recommendations as instructed. Ensure you provide a variety of different types of attractions."
        return prompt

    def _save_recommendations(self, member_id, recommendations):
        """Save recommendations to Supabase recommendations table"""
        if not self.supabase or not recommendations:
            return
        
        try:
            # Prepare data for insertion
            recommendation_data = {
                'member_id': member_id,
                'category': 'attractions',
                'location': self.location,
                'description': recommendations
            }
            
            # Insert into recommendations table
            response = self.supabase.table('recommendations').insert(recommendation_data).execute()
            print(f"Saved {len(recommendations)} attraction recommendations to Supabase")
            
        except Exception as e:
            print(f"Error saving recommendations to Supabase: {e}")

if __name__ == "__main__":
    # Test with a member ID from Supabase
    agent = AttractionsAgent(debug=False)
    
    # Use a test member ID - you can get this from your Supabase members table
    test_member_id = "MB789456123"  # From your user_preferences.json
    
    recs = agent.get_recommendations(test_member_id)
    
    if recs:
        print(f"Attraction Recommendations!")
        print(f"Here are the top attractions we recommend for your visit:\n")
        
        for i, r in enumerate(recs, 1):
            category = r.get('category', 'N/A')
            best_time = r.get('best_time', 'N/A')
            print(f"{i}. {r.get('name', 'N/A')} ({category})")
            print(f"   Best Time: {best_time}")
            print(f"   {r.get('description', 'N/A')}")
            print(f"   {r.get('url', 'N/A')}\n")
    else:
        print("no results")
    
    print("Recommendations saved to Supabase recommendations table")
