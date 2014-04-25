# [topcoder] Leaderboard API

Simple leaderboard API that wraps around the [leaderboard gem](https://github.com/agoragames/leaderboard) which uses ruby and reds. This is a simple ruby sinatra app.

Feel free to try these calls out below. The API is loaded with demo data for your enjoyment. In the examples below, the name of the leaderboard is **'demo'**. 

Unfortunately, there is no way to get a list of all leaderboards.

### Creating a new leaderboard

Simply POST a new member's score to the name of your leaderboard to create it. See below for add/updating scores. Make sure the leaderboard doesn't already exists data. If you try and GET a non-existent leaderboard, it will simply return an empty array. You can also GET the /about for a non-existent leaderboard as well and it will tell you that it is empty.

### Retrieve info about a leaderboard

    curl http://tc-leaderboard.herokuapp.com/demo/about

### Retrieve a leaderboard with member data

    curl http://tc-leaderboard.herokuapp.com/demo
    
Optional parameters:

* page - the page of members to retrieve. Yah!! Support pagination!

### Retrieve a specific member

    curl http://tc-leaderboard.herokuapp.com/demo/jeffdonthemic

### Retrieve the member in a specific position

    curl http://tc-leaderboard.herokuapp.com/demo/rank/2
    
Returns the member in second place.

### Retrieve a range of members

    curl http://tc-leaderboard.herokuapp.com/demo/rank_range?start=2&end=5
    
Returns all members from second to fifth place.

### Retrieve an arbitrary list of members

    curl http://tc-leaderboard.herokuapp.com/demo/rank_members?members=jeffdonthemic,mess,coralblue
    
Returns the rank and score for jeffdonthemic, mess and coralblue.

### Retrieve "Around Me" leaderboard for a member

    curl http://tc-leaderboard.herokuapp.com/demo/jeffdonthemic/around

Returns a leaderboard for a member which pulls members above and below the specified member.

## Adding or updating the scores for a member

To add/update scores you will need to pass an API Key. Contact jeff@appirio.com for the key. When you POST scores to a leaderboard, if the member does not exist as a member in the leaderboard it will add them. If they already exists, it will update their score. Each time a score is added/update it will recalculate all of the rankings (thanks redis!!).

    curl -v -X POST -d handle=jeffdonthemic -d score=80 -d pic=http://community.topcoder.com/i/m/jeffdonthemic.jpeg -d apikey=[API-KEY] http://tc-leaderboard.herokuapp.com/demo    
    
There is also an HTML form you can use to add/update scores. Change the name to your leaderboard, of course, but [here is the sample form](http://tc-leaderboard.herokuapp.com/demo/form) for the demo leaderboard.
 
