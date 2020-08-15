

# Importing the Libraries
import numpy as np
from flask import Flask, request, render_template
from flask_cors import CORS
import os
import flask
import requests
from Levenshtein import *


# Loading Flask and assigning the model variable
app = Flask(__name__)
CORS(app)
app = flask.Flask(__name__, template_folder='templates')



def news_call_classifier(fact_check):

    url = "https://bing-news-search1.p.rapidapi.com/news/search"
    # q = "Amit shah tests negative for COVID-19"
    querystring = {"count":"50","setLang":"EN","freshness":"Day","textFormat":"Raw","safeSearch":"Off","q": fact_check}


    headers = {
        'x-rapidapi-host': "bing-news-search1.p.rapidapi.com",
        'x-rapidapi-key': "1daa73315amsha25dced63e1e976p16fe0djsn4b6547ffa9e5",
        'x-bingapis-sdk': "true"
        }

    response = requests.request("GET", url, headers=headers, params=querystring)
    response = response.json()

    news_headline = []
    for i in range(len(response['value'])):
        # print(response['value'][i]['name'])
        # print('\n\n')
        news_headline.append(response['value'][i]['name'])

    prob_list = []
    for news_art in news_headline:
        prob_list.append(ratio(fact_check, news_art))
        # prob_list.append(jellyfish.jaro_distance(q,news_art))
    ratio1 = sum(prob_list)/len(prob_list)
    return ratio1




@app.route('/')
def main():
    return render_template('main.html')

# Receiving the input url from the user and using Web Scrapping to extract the news content


@app.route('/predict', methods=['GET', 'POST'])
def predict():
    url = request.get_data(as_text=True)[5:]
    url = url.split(sep="+")
    url = " ".join(url)
    # Passing the news article to the model and returing whether it is Fake or Real
    pred = news_call_classifier(url)
    return render_template('main.html', prediction_text='The news is "{}"'.format(pred))


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(port=port, debug=True, use_reloader=False)
