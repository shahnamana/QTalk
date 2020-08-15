# Importing the Libraries
import numpy as np
from flask import Flask, request, render_template
from flask_cors import CORS
import os
# from sklearn.externals import joblib
import pickle
import flask
import os
# import newspaper
# from newspaper import Article
import urllib
from newsapi import NewsApiClient
from difflib import SequenceMatcher
from statistics import mean


news_headlines = []
news_description = []


def new_call(fact_check):
    newsapi = NewsApiClient(api_key='02e9d787a01340af8eba1c661fffc8ce')
    global news_headlines
    global news_description

    top_headlines = newsapi.get_everything(
        q=fact_check,
        language='en',
    )
    for article in top_headlines['articles']:
        news_description.append(article['description'])
        news_headlines.append(article['title'])


def similar(a):
    global news_description
    prob_list = []
    for i in range(len(news_description)):
        prob_list.append(SequenceMatcher(None, a, news_description[i]).ratio())
    max_in_list = min(prob_list)
    return max_in_list


# Loading Flask and assigning the model variable
app = Flask(__name__)
CORS(app)
app = flask.Flask(__name__, template_folder='templates')

# with open('model.pickle', 'rb') as handle:
#     model = pickle.load(handle)


@app.route('/')
def main():
    return render_template('main.html')

# Receiving the input url from the user and using Web Scrapping to extract the news content


@app.route('/predict', methods=['GET', 'POST'])
def predict():
    url = request.get_data(as_text=True)[5:]
    new_call(url)
    news = news_description
    # Passing the news article to the model and returing whether it is Fake or Real
    # pred = model.predict(news)
    maxinlist = similar(url)
    print(type(news))
    return render_template('main.html', prediction_text='The news is "{}"'.format(maxinlist))


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(port=port, debug=True, use_reloader=False)
