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
        """ Build an Exa query for attractions using attractionPreferences.
        Narrows by hobbies, music, social setting, travel mode, vibe tier,
        group/kid-friendly, languages, and wellness interests.
        """

        parts = [f"top rated attractions AND things to do in {self.location}"]

        # 1) Activities / hobbies steer category (e.g., Modern art, Planetariums, Scenic viewpoints)
        activities = prefs.get("activitiesHobbies") or []
        if activities:
            parts.append("(" + " OR ".join(activities) + ")")

        # 2) Music genres hint live-arts venues at night (jazz clubs, classical concerts)
        genres = prefs.get("favoriteMusicGenres") or []
        if genres:
            mapped = []
            for g in genres:
                gl = (g or "").lower()
                if "jazz" in gl:
                    mapped += ["jazz club", "live jazz", "jazz lounge"]
                elif "classical" in gl or "chamber" in gl:
                    mapped += ["classical concert", "symphony", "chamber music", "recital"]
                else:
                    mapped.append(f"live {g}")
            if mapped:
                parts.append("(" + " OR ".join(mapped) + ")")

        # 3) Social setting (quiet/private vs lively/crowded)
        social = prefs.get("socialSetting")
        if social == "Quiet/Private":
            parts.append("(private tour OR small group OR timed entry OR skip-the-line OR reservation required)")
        elif social == "Lively/Crowded":
            parts.append("(popular landmark OR festival OR live event OR bustling)")

        # 4) Travel mode hints (walk vs drive)
        travel = prefs.get("travel") or {}
        mode = (travel.get("mode") or "").lower()
        if mode == "walk":
            parts.append("(walkable OR near downtown OR city center)")
        elif mode == "drive":
            parts.append("(on-site parking OR valet parking)")

        # 5) Vibe tier → premium/curated
        tier = (prefs.get("vibe") or {}).get("tier")
        if tier in {"Premium", "Luxury"}:
            parts.append("(premium OR VIP OR exclusive OR curated OR private guide)")

        # 6) Group & kid-friendly (quick disambiguation)
        group = prefs.get("group")
        kid_friendly = prefs.get("kidFriendly")
        if group == "Couple":
            parts.append("(romantic OR sunset viewpoint OR intimate)")
        if kid_friendly is True:
            parts.append("(family-friendly OR kids museum OR interactive science center)")
        elif kid_friendly is False:
            parts.append("(adults only OR after-hours museum OR evening concert)")

        # 7) Languages → tours/audio guides in user's languages (any language)
        langs = [l for l in (prefs.get("languages") or []) if isinstance(l, str) and l.strip()]
        if langs:
            lang_terms = []
            for lang in langs:
                L = lang.strip()
                lang_terms.append(
                    f'("{L} audio guide" OR "{L} guided tour" OR "{L}-language tour" OR "tours in {L}" OR "{L} commentary")'
                )
            parts.append("(" + " OR ".join(lang_terms) + ")")

        # 8) Wellness interests (yoga/pilates, spa/thermal, easy scenic walks, boat cruises)
        wellness = prefs.get("wellnessActivity") or []
        if wellness:
            parts.append("(" + " OR ".join(wellness) + ")")

        # Note: awakeSleep (awakeAt/sleepAt) is better enforced in ranking, not search.

        return " ".join(parts)

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
