@isTest
public class PlayerSearchQueryActionTest {

    @isTest
    static void testSearchPlayersValid() {
        // Create federation
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create team
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        insert homeTeam;

        // Create player
        Player__c player = new Player__c(Name = 'Carlos Arango', Team__c = homeTeam.Id, Position__c = 'Forward', Games_Played__c = 10);
        insert player;

        // Test case where valid criteria are provided
        PlayerSearchQueryAction.PlayerSearchInput input = new PlayerSearchQueryAction.PlayerSearchInput();
        input.name = player.Name; 
        input.minGamesPlayed = 10; 
        input.maxGamesPlayed = 100; 
        input.teamId = homeTeam.Id;

        List<PlayerSearchQueryAction.PlayerSearchInput> inputs = new List<PlayerSearchQueryAction.PlayerSearchInput>{ input };

        Test.startTest();
        List<PlayerSearchQueryAction.PlayerSearchResult> results = PlayerSearchQueryAction.searchPlayers(inputs);
        Test.stopTest();

        System.assertNotEquals(results.size(), 0, 'Results should be returned');
        System.assertNotEquals(results[0].players.size(), 0, 'Players should be found');
    }

    @isTest
    static void testSearchPlayersWithMissingName() {
        // Create federation
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create team
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        insert homeTeam;

        // Test case where name is missing (this should throw an error)
        PlayerSearchQueryAction.PlayerSearchInput input = new PlayerSearchQueryAction.PlayerSearchInput();
        input.name = ''; 
        input.minGamesPlayed = 10; 
        input.maxGamesPlayed = 100; 
        input.teamId = homeTeam.Id;

        List<PlayerSearchQueryAction.PlayerSearchInput> inputs = new List<PlayerSearchQueryAction.PlayerSearchInput>{ input };

        Test.startTest();
        try {
            PlayerSearchQueryAction.searchPlayers(inputs);
            System.assert(false, 'Expected IllegalArgumentException for missing name');
        } catch (IllegalArgumentException e) {
            System.assertEquals(e.getMessage(), 'Player name is required.');
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchPlayersWithNoResults() {
        // Create federation
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create team
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        insert homeTeam;

        // Create player
        Player__c player = new Player__c(Name = 'Carlos Arango', Team__c = homeTeam.Id, Position__c = 'Forward', Games_Played__c = 10);
        insert player;

        // Test case where no players match the criteria
        PlayerSearchQueryAction.PlayerSearchInput input = new PlayerSearchQueryAction.PlayerSearchInput();
        input.name = 'NonExistentName'; 
        input.minGamesPlayed = 10; 
        input.maxGamesPlayed = 100; 
        input.teamId = homeTeam.Id;

        List<PlayerSearchQueryAction.PlayerSearchInput> inputs = new List<PlayerSearchQueryAction.PlayerSearchInput>{ input };

        Test.startTest();
        List<PlayerSearchQueryAction.PlayerSearchResult> results = PlayerSearchQueryAction.searchPlayers(inputs);
        Test.stopTest();

        System.assertEquals(results.size(), 1, 'There should be one result list');
        System.assertEquals(results[0].players.size(), 0, 'There should be no players matching the criteria');
    }
    
}
