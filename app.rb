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

# return a specific leaderboard with scores
get '/:leaderboard' do
  content_type :json
  page = params[:page] || 1
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  leaders = lb.leaders(page)
  # add in any additional data
  leaders.each { |member| add_member_data(lb, member) }
  leaders.to_json
end

# adds/updates a member's score for the specified leaderboard
post '/:leaderboard' do
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  if ENV['APIKEY'].eql?(params[:apikey])
    score = params[:score].to_i
    # if they already exist, add their new score to their current
    score = score + lb.score_for(params[:handle]).to_i if lb.score_for(params[:handle])
    lb.rank_member(params[:handle], score, JSON.generate({'pic' => params[:pic]}))
    {:status => "success", :message => "Added/Updated #{params[:handle]} to a score of #{score}"}.to_json
  else
    {:status => "error", :message => "API Key did not match. Score not recorded."}.to_json
  end
end

# get some basic info about a leaderboard
get '/:leaderboard/about' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  {:name => params[:leaderboard], 
    :members => lb.total_members,
    :pages => lb.total_pages
    }.to_json
end

# shows a form to manually enter a member's score
get '/:leaderboard/form' do
  erb :form
end

# temp -- adds/updates a member's score for the specified leaderboard
post '/:leaderboard/form' do
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  if ENV['APIKEY'].eql?(params[:apikey])
    score = params[:score].to_i
    # if they already exist, add their new score to their current
    score = score + lb.score_for(params[:handle]).to_i if lb.score_for(params[:handle])
    lb.rank_member(params[:handle], score, JSON.generate({'pic' => params[:pic]}))
    {:status => "success", :message => "Added/Updated #{params[:handle]} to a score of #{score}"}.to_json
  else
    {:status => "error", :message => "API Key did not match. Score not recorded."}.to_json
  end
end

# gets a the member in a specific rank for a leaderboard
get '/:leaderboard/rank/:rank' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  add_member_data(lb, lb.member_at(params[:rank].to_i)).to_json
end

# gets a range of ranks for a leaderboard
get '/:leaderboard/rank_range' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  leaders = lb.members_from_rank_range(params[:start].to_i, params[:end].to_i)
  leaders.each { |member| add_member_data(lb, member) }
  leaders.to_json
end

# returns members and their ranks from comma separated list of member
get '/:leaderboard/rank_members' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  leaders = lb.ranked_in_list(params[:members].split(','))
  leaders.each { |member| add_member_data(lb, member) }
  leaders.to_json  
end

# gets a member's rank
get '/:leaderboard/:handle' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  member = {:handle => params[:handle], 
    :rank => lb.rank_for(params[:handle]),
    :score => lb.score_for(params[:handle])
    }
  add_member_data(lb, member).to_json
end

# gets members around a specific member
get '/:leaderboard/:handle/around' do
  content_type :json
  lb = Leaderboard.new(params[:leaderboard], DEFAULT_OPTIONS, settings.redis_options)
  leaders = lb.around_me(params[:handle])
  leaders.each { |member| add_member_data(lb, member) }
  leaders.to_json    
end

# not sure what this does?
put '/:leaderboard' do
  content_type :json
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

# add any additional member data (ie pic)
def add_member_data(lb, member)
  begin
    obj = JSON.parse(lb.member_data_for(member[:handle]))
    obj.each { |key, value| member[key] = value }
  rescue 
    # fail silently if no data exists
  end
  member
end