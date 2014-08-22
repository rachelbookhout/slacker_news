require 'sinatra'
# #require 'sinatra-reloader'
require 'pry'
require 'csv'
require 'redis'
enable :sessions

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

require 'sinatra'
require 'redis'
require 'json'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  articles = []

  serialized_articles.each do |article|
    articles << JSON.parse(article, symbolize_names: true)
  end

  articles
end

def save_article(url, title, description)
  article = { url: url, title: title, description: description }

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end


def read_csv(filename)
  data = []
  CSV.foreach(filename, headers:true) do |row|
    data << row.to_hash
  end
  data
end


def validate_url(filename,url)
  checked_urls = filename.select do |row|
    row["Url"] == url
  end
  checked_urls
end

before do
  @articles = read_csv('articles.csv')
end


get '/' do
  @articles = read_csv('articles.csv')
  erb :index
end

get '/new' do
  erb :new
end

post '/new' do

  # Read the input from the form the user filled out
  @name = params["article_name"]
  @url = params['url']
  @description = params['description']
  @checked_urls = validate_url(@articles, @url)
  if @checked_urls.empty?
  # Open the "tasks" file and append the task
    CSV.open('articles.csv', 'a') do |csv|
      csv << [@name, @url, @description]
    end
    # Send the user back to the home page which shows
    # the list of articles
    redirect '/'
  else
    session[:message] = "We already know about this. Send us something different"
    erb :new
  end
end
