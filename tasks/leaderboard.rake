desc "Updates the IDOLOnDemand Leaderboard"
task :idolondemand do
  search_url = 'http://tc-search.herokuapp.com/challenges/search?q=challengeName:IDOL%20+currentStatus%3ACompleted'
  skip_challenges = [30042560, 30043102]
  update_leaderboard('autoupdate', search_url, skip_challenges)
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

    # add the money they won to the points
    challenge['prize'][0..winners.count-1].each_with_index  do |prize, x|
      winners[x]['points'] = prize
    end

    p "Processing -- #{challenges['_source']['challengeName']} #{challenges['_source']['challengeId']}"

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