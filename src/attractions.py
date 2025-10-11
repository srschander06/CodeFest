import os
import json
import re
import time
import google.generativeai as genai
from exa_py import Exa
from dotenv import load_dotenv

load_dotenv()

gemini_api_key = os.getenv('GEMINI_KEY')
if gemini_api_key:
    genai.configure(api_key=gemini_api_key )

class AttractionsAgent:
    def __init__(self, debug=False):
        self.exa = Exa(api_key=os.getenv('BEN_EXA_KEY'))
        self.location = os.getenv('LOCATION', 'Blacksburg, VA')
        self.debug = debug
        self.llm = genai.GenerativeModel('gemini-pro-latest') if gemini_api_key else None  # most stable

    def get_recommendations(self, user_data):
        # main flow: Exa + Gemini to go from user prefs to tailored **attraction** recommendations
        prefs = user_data.get('attractionPreferences', {})
        
        # 1) search: find potential **attraction** websites via Exa
        search_query = self._build_search_query(prefs)
        print(f"searching for attractions with query: {search_query}")
        try:
            search_results = self.exa.search(search_query, num_results=10, use_autoprompt=True).results
        except Exception as e:
            print(f"exa search error: {e}")
            return []

        # 2) fetch content: pull text from those sites
        print(f"found {len(search_results)} potential attractions, getting their info...")
        ids = [result.id for result in search_results]
        try:
            contents = self.exa.get_contents(ids).results
        except Exception as e:
            print(f"exa content fetch error: {e}")
            return []

        # 3) synthesize: concierge picks the best **attractions** using prefs + site text
        print("concierge evaluating the best attractions...")
        prompt = self._build_llm_prompt(contents, prefs)
        
        try:
            response = self.llm.generate_content(prompt)
            cleaned_response = re.sub(r'```json\s*|\s*```', '', response.text).strip()
            if self.debug:
                print(f"--- raw gemini output ---\n{cleaned_response}\n--------------------")
            attractions = json.loads(cleaned_response)
            return attractions

        except Exception as e:
            print("no results")
            if self.debug:
                print(f"    err: {e}")
            return []

    def _build_search_query(self, prefs):
        # translate user prefs into an Exa search query for **attractions**
        query_parts = [f"top rated attractions in {self.location}"]
        # (left logic as-is; prefs may not include these keys, that's fine)
        if cuisines := prefs.get('cuisinePreferences'):
            query_parts.append(f"({ ' OR '.join(cuisines) })")
        if (restrictions := prefs.get('dietaryRestrictions')) and (choice := restrictions.get('dietaryChoice')) != 'None':
            query_parts.append(f"with '{choice} menu'")
        return ' '.join(query_parts)

    def _build_llm_prompt(self, contents, prefs):
        # build a single prompt asking for **attraction** recs in strict JSON
        prompt = f"""
        You are a helpful hotel concierge providing attraction recommendations. A guest has the following attraction preferences: {json.dumps(prefs)}.

        Based *only* on the following context from several attraction websites, generate a personalized list of the TOP 5-15 attraction recommendations that are the best fit for the guest.

        Your response MUST be a single, valid JSON array of objects. Do not include any introductory text, markdown formatting, or explanations outside of the JSON itself. Each object in the array must have the following keys: "name", "description", "url".
        - 'name': The name of the attraction/venue.
        - 'description': A summary (3-4 sentences) tailored to the guest. Cite specific details from the provided text that match their preferences.
        - 'url': The original URL of the website.

        Here is the content from the websites:
        """
        for content in contents:
            prompt += f"\n\n--- Website Content from {content.url} ---\n"
            prompt += content.text
        prompt += "\n\n--- End of Website Content ---"
        prompt += "\nNow, generate the JSON array of the top 5-15 recommendations as instructed. Ensure you provide a variety of distinct options from the provided content. Your entire response should be only the JSON array."
        return prompt

if __name__ == "__main__":
    # run the **attractions** agent
    agent = AttractionsAgent(debug=False)
    user_file = 'user_preferences.json'
    
    try:
        with open(user_file, 'r') as f:
            user_data = json.load(f)
    except FileNotFoundError:
        print(f"error: user_preferences.json not found.")
        exit()
    
    recs = agent.get_recommendations(user_data)
    
    # simple header using attractionPreferences (text only)
    attrs = user_data.get('attractionPreferences', {})
    first_name = user_data.get('personalInfo', {}).get('firstName', 'Guest')
    print(f"Welcome Back {first_name.upper()}! Here are some attraction recommendations for you:")
    if attrs:
        print(f"Prefs: {attrs}\n")
    
    # IMPORTANT: location & hours handled by your maps integration.
    if recs:
        for i, r in enumerate(recs, 1):
            print(f"{i}. {r.get('name', 'N/A')}")
            print(f"   {r.get('description', 'N/A')}")
            print(f"   {r.get('url', 'N/A')}\n")
    else:
        print("no results")
    
    print("this should go to mongo i think")
