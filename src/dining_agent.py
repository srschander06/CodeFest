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
    genai.configure(api_key=gemini_api_key )

# Supabase configuration
supabase_url = "https://ivnzekvuouiqasshhlml.supabase.co"
supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

class DiningAgent:
    def __init__(self, debug=False):
        self.exa = Exa(api_key=os.getenv('BEN_EXA_KEY'))
        self.location = os.getenv('LOCATION', 'Blacksburg, VA')
        self.debug = debug
        self.llm = genai.GenerativeModel('gemini-pro-latest') if gemini_api_key else None 
        self.supabase: Client = create_client(supabase_url, supabase_key) if supabase_key else None

        
    def get_recommendations(self, member_id):
        # this is the main flow for the agent. it's a multi-step process that uses exa and gemini
        # to get from a user's preferences to a list of tailored restaurant recommendations
        # The other agents (attractions, shopping, etc.) can follow this same pattern

        # Fetch user data from Supabase
        if not self.supabase:
            print("Supabase client not initialized")
            return []
        
        try:
            response = self.supabase.table('members').select('dining_preferences').eq('member_id', member_id).execute()
            if not response.data:
                print(f"No member found with ID: {member_id}")
                return []
            
            user_data = response.data[0]
            prefs = user_data.get('dining_preferences', {})
        except Exception as e:
            print(f"Error fetching user data: {e}")
            return []
        
        # 1. search: find a bunch of potential restaurant websites.
        # Exa does the heavy lifting via the neural search engine and the semantic search.
        search_query = self._build_search_query(prefs)
        print(f"searching for restaurants with query: {search_query}")
        try:
            search_results = self.exa.search(search_query, num_results=10, use_autoprompt=True).results
        except Exception as e:
            print(f"exa search fucked up: {e}")
            return []

        # 2. fetch content: get the text from all the sites at once.
        # batch request is way faster.
        print(f"found {len(search_results)} potential restaurants, getting their info...")
        ids = [result.id for result in search_results]
        try:
            contents = self.exa.get_contents(ids).results
        except Exception as e:
            print(f"exa content fetch fucked up: {e}")
            return []

        # 3. synthesize: this is the magic. give all the website content and user prefs to gemini.
        # ask it to act like a concierge and pick the best spots for us.
        print("cocierg evaluting the best restuarants...")
        prompt = self._build_llm_prompt(contents, prefs)
        
        try:
            response = self.llm.generate_content(prompt)
            # llm response is usually messy, gotta clean it up to get the json.
            cleaned_response = re.sub(r'```json\s*|\s*```', '', response.text).strip() # removing the markdown formatting             
            if self.debug:
                print(f"--- raw gemini output ---\n{cleaned_response}\n--------------------") # for debugging
            
            restaurants = json.loads(cleaned_response)
            
            # Save recommendations to Supabase
            self._save_recommendations(member_id, restaurants)
            
            return restaurants

        except Exception as e:
            print(f"no results")
            if self.debug:
                print(f"    err: {e}")
            return []

    def _build_search_query(self, prefs):
        # just translates the user's prefs into a search query for exa.
        # keeping it broad with ORs and specific terms seems to work best.
        query_parts = [f"top rated restaurants in {self.location}"]
        if cuisines := prefs.get('cuisinePreferences'):
            query_parts.append(f"({ ' OR '.join(cuisines) })")
        if (restrictions := prefs.get('dietaryRestrictions')) and (choice := restrictions.get('dietaryChoice')) != 'None':
            query_parts.append(f"with '{choice} menu'")
        return ' '.join(query_parts)

    def _build_llm_prompt(self, contents, prefs):
        # this is the core of the synthesize step. builds one giant prompt for the llm
        # with the user's prefs and all the website content. (someone can import a tokenizer and use that to count exactly how many tokens this is using)
        # prompt engineering (via the anthropic prompt workshop, I dont think there much improvement to be made here)
        prompt = f"""
        You are a helpful hotel concierge providing dining recommendations. A guest has the following dining preferences: {json.dumps(prefs)}.

        Based *only* on the following context from several restaurant websites, generate a personalized list of the TOP 5-15 restaurant recommendations that are the best fit for the guest.

        Your response MUST be a single, valid JSON array of objects. Do not include any introductory text, markdown formatting, or explanations outside of the JSON itself. Each object in the array must have the following keys: "name", "description", "url".
        - 'name': The name of the restaurant.
        - 'description': A summary (3-4 sentences) tailored to the guest. Cite specific menu items, reviews, or atmosphere details from the provided text that match their preferences.
        - 'url': The original URL of the website.

        Here is the content from the websites:
        """
        
        # just dump all the website text into the prompt. llm can handle it but we need to make sure it's formatted correctly
        for content in contents:
            prompt += f"\n\n--- Website Content from {content.url} ---\n" # Labeling the content for clarity
            prompt += content.text # pass full content
        
        prompt += "\n\n--- End of Website Content ---" # Labeling the end of the content for clarity
        prompt += "\nNow, generate the JSON array of the top 5-15 recommendations as instructed. Ensure you provide a variety of distinct options from the provided content. Your entire response should be only the JSON array."
        return prompt

    def _save_recommendations(self, member_id, recommendations):
        """Save recommendations to Supabase recommendations table"""
        if not self.supabase or not recommendations:
            return
        
        try:
            # Prepare data for insertion
            recommendation_data = {
                'member_id': member_id,
                'category': 'dining',
                'location': self.location,
                'description': recommendations
            }
            
            # Insert into recommendations table
            response = self.supabase.table('recommendations').insert(recommendation_data).execute()
            print(f"Saved {len(recommendations)} dining recommendations to Supabase")
            
        except Exception as e:
            print(f"Error saving recommendations to Supabase: {e}")

if __name__ == "__main__":
    # Test with a member ID from Supabase
    agent = DiningAgent(debug=False)
    
    # Use a test member ID - you can get this from your Supabase members table
    test_member_id = "MB789456123"  # From your user_preferences.json
    
    recs = agent.get_recommendations(test_member_id)
    
    if recs:
        print(f"Welcome Back! Here are some restaurant recommendations for you:")
        print(f"Location: {agent.location}\n")
        
        # IMPORTANT location and hours are handled by aryan's apple maps integration.
        # the user will tap a rec to see these details on the map.
        for i, r in enumerate(recs, 1):
            print(f"{i}. {r.get('name', 'N/A')}")
            print(f"   {r.get('description', 'N/A')}")
            print(f"   {r.get('url', 'N/A')}\n")
    else:
        print("no results")
    
    print("Recommendations saved to Supabase recommendations table")