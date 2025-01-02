@isTest
public class GamePlayerEligibilityHandlerTest {
    
    @isTest
    static void testEligiblePlayer() {
        // 1. Arrange: Setup data for the test
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create teams for the game
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        Team__c opponentTeam = new Team__c(Name = 'Millonarios', Federation__c = federation.Id);
        insert homeTeam;
        insert opponentTeam;
        
        // Create a player and a game
        Player__c player = new Player__c(Name = 'Player A', Games_Played__c = 4, Player_Status__c = 'Ineligible');
        Game__c game = new Game__c(Game_Status__c = 'Scheduled', Home_Team__c = homeTeam.Id, Opponent_Team__c = opponentTeam.Id, Federation__c = federation.Id);
        insert player;
        insert game;
        
        // Link the player to the game
        Game_Player__c gamePlayer = new Game_Player__c(Player__c = player.Id, Game__c = game.Id);
        insert gamePlayer;
        
        // 2. Act: Call the method under test
        Test.startTest();
        GamePlayerEligibilityHandler.updateGamePlayerEligibility(new List<Game_Player__c>{gamePlayer});
        Test.stopTest();
        
        // 3. Assert: Verify that the player status was updated correctly
        Player__c updatedPlayer = [SELECT Player_Status__c FROM Player__c WHERE Id = :player.Id];
        System.assertEquals('Eligible', updatedPlayer.Player_Status__c, 'Player should be marked as Eligible.');
    }
    
    @isTest
    static void testPendingReviewGamePlayer() {
        // 1. Arrange: Setup data for the test
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create teams for the game
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        Team__c opponentTeam = new Team__c(Name = 'Millonarios', Federation__c = federation.Id);
        insert homeTeam;
        insert opponentTeam;

        // Create a player and a game
        Player__c player = new Player__c(Name = 'Player B', Games_Played__c = 6, Player_Status__c = 'Ineligible');
        Game__c game = new Game__c(Game_Status__c = 'Scheduled', Home_Team__c = homeTeam.Id, Opponent_Team__c = opponentTeam.Id, Federation__c = federation.Id);
        insert player;
        insert game;
        
        // Link the player to the game
        Game_Player__c gamePlayer = new Game_Player__c(Player__c = player.Id, Game__c = game.Id);
        insert gamePlayer;
        
        // 2. Act: Call the method under test
        Test.startTest();
        GamePlayerEligibilityHandler.updateGamePlayerEligibility(new List<Game_Player__c>{gamePlayer});
        Test.stopTest();
        
        // 3. Assert: Verify that the player and game statuses were updated correctly
        Player__c updatedPlayer = [SELECT Player_Status__c FROM Player__c WHERE Id = :player.Id];
        Game__c updatedGame = [SELECT Game_Status__c FROM Game__c WHERE Id = :game.Id];
        System.assertEquals('Pending Review', updatedPlayer.Player_Status__c, 'Player should be marked as Pending Review.');
        System.assertEquals('Pending Player', updatedGame.Game_Status__c, 'Game should be marked as Pending Player.');
    }
    
    @isTest
    static void testBulkProcessing() {
        // 1. Arrange: Setup data for bulk test
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create teams for the games
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        Team__c opponentTeam = new Team__c(Name = 'Millonarios', Federation__c = federation.Id);
        insert homeTeam;
        insert opponentTeam;

        // Create multiple players and games
        List<Player__c> players = new List<Player__c>();
        List<Game__c> games = new List<Game__c>();
        List<Game_Player__c> gamePlayers = new List<Game_Player__c>();
        
        for (Integer i = 0; i < 200; i++) {
            players.add(new Player__c(Name = 'Player ' + i, Games_Played__c = (Math.Mod(i, 2) == 0) ? 4 : 6, Player_Status__c = 'Ineligible', Team__c = (Math.Mod(i, 2) == 0) ? homeTeam.Id : opponentTeam.Id));
            games.add(new Game__c(Game_Status__c = 'Scheduled', Home_Team__c = homeTeam.Id, Opponent_Team__c = opponentTeam.Id, Federation__c = federation.Id));
        }
        
        insert players;
        insert games;
        
        for (Integer i = 0; i < 200; i++) {
            gamePlayers.add(new Game_Player__c(Player__c = players[i].Id, Game__c = games[i].Id));
        }
        
        // 2. Act: Insert game players and update statuses
        insert gamePlayers;
        
        // 3. Assert: Verify that all players and games were updated correctly
        List<Player__c> updatedPlayers = [SELECT Player_Status__c FROM Player__c WHERE Id IN :players];
        List<Game__c> updatedGames = [SELECT Game_Status__c FROM Game__c WHERE Id IN :games];
        
        for (Integer i = 0; i < updatedPlayers.size(); i++) {
            Player__c player = updatedPlayers[i];
            if (Math.Mod(i, 2) == 0) {
                System.assertEquals('Eligible', player.Player_Status__c, 'Players with < 5 games should be Eligible');
            } else {
                System.assertEquals('Pending Review', player.Player_Status__c, 'Players with >=5 games should be Pending Review');
            }
        }
        
        for (Integer i = 0; i < updatedGames.size(); i++) {
            Game__c game = updatedGames[i];
            if (Math.Mod(i, 2) == 0) {
                System.assertEquals('Scheduled', game.Game_Status__c, 'Games with eligible players should remain Scheduled');
            } else {
                System.assertEquals('Pending Player', game.Game_Status__c, 'Games with pending review players should be Pending Player');
            }
        }
    } 

}