require 'sinatra'
require 'json'
require 'leaderboard'

configure do
  set :redis_options, {:host => 'localhost', :port => 6379}
  if ENV["REDISTOGO_URL"]
    uri = URI.parse(ENV["REDISTOGO_URL"])
    set :redis_options, {:host => uri.host, :port => uri.port, :password => uri.password}
  end
end

get '/' do
  'Welcome to the topcoder leaderboards. Choose a leaderboard to get started.'
end 

get '/:leaderboard' do
  content_type :json
  page = params[:page] || 1
  lb = Leaderboard.new(params[:leaderboard], Leaderboard::DEFAULT_OPTIONS, settings.redis_options)
  lb.leaders(page).to_json
end

put '/:leaderboard' do
  lb = Leaderboard.new(params[:leaderboard], Leaderboard::DEFAULT_OPTIONS, settings.redis_options)
  lb.rank_member(params[:handle], params[:score])
  {:handle => params[:handle], 
    :rank => lb.rank_for(params[:handle]),
    :score => lb.score_for(params[:handle])
    }.to_json
end

not_found do
  halt 404, 'page not found'
end