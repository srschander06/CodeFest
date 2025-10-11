Okay so the dining agent is working sorta.

Feel free to use this as a starting point for the other agents. But, exa is a relatively new service to me so I am still learning how to use it effectively. I'm sure there's a better approach than how this currently functions but iven our time constraint, I don't want to complicate this much more than a few api calls and a single LLM call (notice requirements.txt) // if you're using this as a reference point, keep that in mind and if you have any suggestions feel free to add your own improvements (w notes if needed)

That being said, this is the flow the agent follows:

1. The agent takes in the user's preferences and builds a search query for exa (exa is a search engine that uses AI (neural search,) to find the most relevant results)

2. Exa returns a list of candidate restaurant URLs (the agent then uses the IDs from the search results to perform a single, batch request to get the full text content of all the websites at once)

3. The agent fetches the content of all the candidate restaurant URLs (this is a batch request so it's more efficient than making individual requests for each URL)

4. The agent uses the Gemini LLM to synthesize the best recommendations from the content (this is the core of the agent)

5. The agent returns the recommendations to the user. the agent then formats the recommendations into a JSON array and returns it to the user //currently fixing this cause its fucking broken rn --will fix soon (the llm response was being wrapped in markdown formatting which was breaking the json.loads() function,, if you find a more reliable way to fix this, please do so but try to stray away from complex post processing solutions)

//would do a mermaid diagram but idk how to do that in vscode so just use your imagination


The output for our example user (inside user_preferences.json) is:

to run in terminal: 
pip install -r requirements.txt
python dining_agent.py (to run the agent)


FINAL LLM-GENERATED RECOMMENDATIONS FOR SARAH
Diet: Pescatarian | Allergies: Shellfish
Style: Fine dining | Beverages: White wine, sake

1. Zeppoli's Italian Restaurant and Wine Shop
   Description: This restaurant is an excellent match for your fine dining preference, aspiring to a "cutting edge culinary experience" with homemade Italian
 pasta. As a pescatarian, you may enjoy customizable dishes like the "Primavera with added salmon," which aligns with your dietary choice while avoiding shel
lfish. Their status as a wine shop and bar is perfect for your preference for white wine, and making a reservation for your 19:00 dinner should be seamless.
The from-scratch kitchen is a positive indicator that they can carefully handle your shellfish allergy.
   URL: https://www.zeppolis.com/

2. Zeppoli's Italian Restaurant and Wine Shop
   Description: Matching your preference for Italian cuisine, Zeppoli's is an ideal choice. The restaurant is particularly well-suited for your pescatarian diet, as the menu features customizable dishes like 'Primavera with added salmon.' As a wine shop with offerings like 'Wine Tasting' and '2 for 20 Wines,' it is a perfect match for your interest in white wine. The restaurant is praised for its 
wonderful dining experience and friendly staff.
   URL: https://www.restaurantji.com/va/blacksburg/zeppolis-italian-restaurant-and-wine-shop-/  

3. 622 North
   Description: This restaurant fits your interest in a contemporary, upscale atmosphere. It is described as a 'Contemporary, Wine Bar,' which directly aligns with your preferences for fine dining and white wine. While specific menu items are not listed, a contemporary American restaurant and wine bar is an excellent setting to find quality pescatarian dishes. It is noted as a 'Solid choice when visiting Virginia Tech.'                                                         
   URL: https://www.tripadvisor.com/Restaurants-g57513-Blacksburg_Virginia.html 


4. Ocean Samurai
   Description: To satisfy your preference for Asian cuisine, Ocean Samurai is a strong candidate specializing in Japanese food. This is an especially fitting choice given your beverage preference, as it is noted to be a continuation of the former 'Sake House.' The menu features sushi rolls, which are perfect for a pescatarian diet, though you should inform them of your shellfish allergy. Reviews 
praise the 'Excellent service and sushi rolls.'
   URL: https://www.tripadvisor.com/Restaurants-g57513-Blacksburg_Virginia.html


5. Blacksburg Wine Lab
   Description: Given your preference for white wine, the Blacksburg Wine Lab is a highly tailored recommendation. This establishment focuses on an international wine experience and is described as a great place for a special occasion dinner, suggesting a sophisticated atmosphere. It is 'Highly recommended' and would be a wonderful place to relax and enjoy a selection of quality wines that suit your taste.                                                                       
   URL: https://www.tripadvisor.com/Restaurants-g57513-Blacksburg_Virginia.html


6. Preston's Restaurant
   Description: Located at the Inn at Virginia Tech, Preston's offers an American fine dining experience. Its location within the hotel suggests a more formal atmosphere suitable for your preferences. Another source also refers to it as a 'Wine Bar', making it a great place to enjoy a glass of white wine with dinner. Being a hotel restaurant, they are typically well-equipped to handle dietary requests like your pescatarian needs and shellfish allergy.                         
   URL: https://www.tripadvisor.com/Restaurants-g57513-Blacksburg_Virginia.html

   7. Avellinos Italian Restaurant & Pizzeria
   Description: For a well-regarded Italian option, Avellinos fits your cuisine 
preference. The restaurant serves Italian food and is specifically listed as having 'Seafood' options, which is perfect for your pescatarian diet, though you should notify the staff of your shellfish allergy. It has a full bar to accommodate your request for white wine and takes reservations for your 19:00 dinner time. One reviewer notes, 'The food was delicious, the portions were generous, and the service was attentive.'                                                       
   URL: https://www.menupix.com/virginia/restaurants/28296624/Avellinos-Blacksburg-VA


8. Cellar Restaurant
   Description: The Cellar offers a diverse menu that touches on several of your preferred cuisines, including Italian, Mediterranean, and American. Located in 
the heart of downtown, it provides a 'relaxing night of great food' and features music from local bands. While known for its large beer list, a full bar is available to serve white wine. This would be a more relaxed choice to enjoy a variety of familiar cuisines.                                                         
   URL: https://us.nextdoor.com/pages/the-cellar-restaurant-blacksburg-va/


9. India Garden
   Description: As a great option for Asian cuisine, India Garden offers an authentic Indian dining experience. With a price range of '$$ - $$$' and menu items 
like 'Chicken Tikka' and 'Lamb Pasanda' mentioned in reviews, it promises a quality meal beyond casual takeout. Indian cuisine has extensive vegetarian and pescatarian options, ensuring you will have many delicious, shellfish-free dishes to choose from.                                                                   
   URL: https://www.tripadvisor.com/Restaurants-g57513-Blacksburg_Virginia.html


10. Cafe Mekong
   Description: For another Asian option, Cafe Mekong specializes in Thai cuisine. It is highly rated by locals, with one reviewer stating they 'usually eat here about once a week.' The 'pho and fried rice really stand out,' and Thai cuisine offers many fish and tofu-based dishes suitable for your pescatarian diet. It 
would be a great place to also enjoy your preferred green tea with your meal.   
   URL: https://www.tripadvisor.com/Restaurants-g57513-Blacksburg_Virginia.html

   ^ These results were generated by a single LLM call based on multiple sources collected by exa  

