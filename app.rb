require 'sinatra'
require 'json'
require 'leaderboard'

configure do
  set :redis_options, {:host => 'localhost', :port => 6379}
  if ENV["REDISTOGO_URL"]
    uri = URI.parse(ENV["REDISTOGO_URL"])
    set :redis_options, {:host => uri.host, :port => uri.port, :password => uri.password}
  end

  DEFAULT_OPTIONS = {
    :page_size => 25,
    :reverse => false,
    :member_key => :handle,
    :rank_key => :rank,
    :score_key => :score,
    :member_data_key => :member_data,
    :member_data_namespace => 'member_data'
  }

end

get '/' do
  'Welcome to the topcoder leaderboards. Choose a leaderboard to get started.'
end 

get '/:leaderboard' do
  content_type :json
  page = params[:page] || 1
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  lb.leaders(page).to_json
end

get '/:leaderboard/about' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  {:name => params[:leaderboard], 
    :members => lb.total_members,
    :pages => lb.total_pages
    }.to_json
end

# temp
get '/:leaderboard/form' do
  erb :form
end

# temp
post '/:leaderboard/form' do
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  lb.rank_member(params[:handle], params[:score])
  "Added/Updated #{params[:handle]} with a score of #{params[:score]}"
end

get '/:leaderboard/rank/:rank' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  lb.member_at(params[:rank].to_i).to_json
end

get '/:leaderboard/:handle' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  {:handle => params[:handle], 
    :rank => lb.rank_for(params[:handle]),
    :score => lb.score_for(params[:handle])
    }.to_json
end

get '/:leaderboard/:handle/around' do
  content_type :json
  p 'around'
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  lb.around_me(params[:handle]).to_json
end

put '/:leaderboard' do
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  lb.rank_member(params[:handle], params[:score])
  {:handle => params[:handle], 
    :rank => lb.rank_for(params[:handle]),
    :score => lb.score_for(params[:handle])
    }.to_json
end

not_found do
  halt 404, 'page not found'
end