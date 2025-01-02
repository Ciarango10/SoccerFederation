public with sharing class PlayerSearchQueryAction {
    
    // Inner class for input parameters
    public class PlayerSearchInput {
        @InvocableVariable(required=true)
        public String name;
        
        @InvocableVariable(required=false)
        public Integer minGamesPlayed;
        
        @InvocableVariable(required=false)
        public Integer maxGamesPlayed;
        
        @InvocableVariable(required=false)
        public String teamId;
    }
    
    // Inner class for output results
    public class PlayerSearchResult {
        @InvocableVariable
        public List<Player__c> players;
    }
    
    @InvocableMethod(label='Search Players' description='Search for players based on dynamic criteria')
    public static List<PlayerSearchResult> searchPlayers(List<PlayerSearchInput> inputs) {
        // List to store the search results
        List<PlayerSearchResult> results = new List<PlayerSearchResult>();
        
        // Start building the SOQL query    
        String query = 'SELECT Id, Name, Position__c, Team__c FROM Player__c WHERE ';

        for(PlayerSearchInput input : inputs) {
            if (String.isEmpty(input.name)) {
                throw new IllegalArgumentException('Player name is required.');
            }
            
            // Filter by Name (required)
            query += 'Name LIKE \'%' + String.escapeSingleQuotes(input.name) + '%\''; // Ensures that the name is safely included in the query

            // Filter by min games
            if (input.minGamesPlayed != null) {
                query += ' AND Games_Played__c >= ' + input.minGamesPlayed;
            }

            // Filter by max games
            if (input.maxGamesPlayed != null) {
                query += ' AND Games_Played__c <= ' + input.maxGamesPlayed;
            }

            // Filter by team
            if (input.teamId != null) {
                query += ' AND Team__c = \'' + String.escapeSingleQuotes(String.valueOf(input.teamId)) + '\'';
            }
        }
        
        // Execute the query to fetch players
        List<Player__c> players = Database.query(query);
            
        // Add the result to the output list
        PlayerSearchResult result = new PlayerSearchResult();
        result.players = players;
        results.add(result);
        
        return results;
    }

}