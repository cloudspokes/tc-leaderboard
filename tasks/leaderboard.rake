desc "Updates the IDOLOnDemand Leaderboard"

task :lightning do
  search_url = 'http://tc-search.herokuapp.com/challenges/v2/search?q=technologies:lightning%20AND%20status:Completed'
  skip_challenges = []
  update_leaderboard('lightning', search_url, skip_challenges)
end

task :idolondemand do
  search_url = 'http://tc-search.herokuapp.com/challenges/v2/search?q=challengeName:IDOL%20AND%20status:Completed'
  skip_challenges = [30042560, 30043102]
  update_leaderboard('idolondemand', search_url, skip_challenges)
end

task :getswifter do
  search_url = 'http://tc-search.herokuapp.com/challenges/v2/search?q=technologies:Swift%20AND%20status:Completed%20AND%20-challengeName:algorithm'
  skip_challenges = [30043437, 30043317, 30043422, 30043411, 30043297, 30043425, 30043293, 30044358, 30044401]
  update_leaderboard('getswifter', search_url, skip_challenges)
end

task :getswifteralgos do
  search_url = 'http://tc-search.herokuapp.com/challenges/v2/search?q=technologies:Swift%20AND%20status:Completed%20AND%20challengeName:algorithm'
  skip_challenges = []
  update_leaderboard('getswifteralgos', search_url, skip_challenges)
end

def update_leaderboard(leaderboard, search_url, skip)

  # delete all current members
  delete_all_members(leaderboard)
  # init the leaderboard
  lb = Leaderboard.new(leaderboard, DEFAULT_OPTIONS, settings.redis_options)

  # interate over all challenges returened
  JSON.parse(HTTParty.get(search_url)).each do |challenges|

    # skip the ones on the list
    next if skip.include?(challenges['_source']['challengeId'])
    # init the array of winners to add to leaderbaord
    winners = []
    # get the challenge
    challenge = HTTParty.get("http://api.topcoder.com/v2/#{challenges['_type']}/challenges/#{challenges['_source']['challengeId']}")
    # get all fo the submitters
    submitters = HTTParty.get("http://api.topcoder.com/v2/challenges/submissions/#{challenges['_source']['challengeId']}")['finalSubmissions']

    # skip this challenge if there are no submitters
    next if submitters.empty?
    # skip this challenge if there are no winners
    next if !submitters[0].has_key?('finalScore')

    # see how many winners there are
    submitters.each_with_index do |s, x|
      winners << s if s['finalScore'] > 80 && x < challenge['prize'].count
    end

    begin
      # add the money they won to the points
      challenge['prize'][0..winners.count-1].each_with_index  do |prize, x|
        winners[x]['points'] = prize
      end
    rescue
      p " **** Could not calcualte points for winners. "
    end

    p "Processing -- #{challenges['_source']['challengeName']} #{challenges['_source']['challengeId']}"
    p winners
    winners.each do |w|
      increment_member_score(
        lb,
        w['handle'],
        w['points'].to_i,
        JSON.generate({'pic' => process_pic(w['handle'], nil)})
      )
    end

  end

end
