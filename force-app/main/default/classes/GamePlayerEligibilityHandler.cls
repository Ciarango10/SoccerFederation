public with sharing class GamePlayerEligibilityHandler {
    public static void updateGamePlayerEligibility(List<Game_Player__c> gamePlayers) {
        // Sets to hold the IDs of players and games
        Set<Id> playerIds = new Set<Id>();
        Set<Id> gameIds = new Set<Id>();

        // Collect player and game IDs
        for (Game_Player__c gamePlayer : gamePlayers) {
            if (gamePlayer.Player__c != null) {
                playerIds.add(gamePlayer.Player__c);
            }
            if (gamePlayer.Game__c != null) {
                gameIds.add(gamePlayer.Game__c);
            }
        }

        // Query Players and Games
        Map<Id, Player__c> playersMap = new Map<Id, Player__c>([
            SELECT Id, Games_Played__c, Player_Status__c, Team__c 
            FROM Player__c 
            WHERE Id IN :playerIds
        ]);

        Map<Id, Game__c> gamesMap = new Map<Id, Game__c>([
            SELECT Id, Game_Status__c 
            FROM Game__c 
            WHERE Id IN :gameIds
        ]);

        // Group players by their teams
        Map<Id, List<Player__c>> playersByTeam = new Map<Id, List<Player__c>>();
        for (Player__c player : playersMap.values()) {
            if (player.Team__c != null) {
                if (!playersByTeam.containsKey(player.Team__c)) {
                    playersByTeam.put(player.Team__c, new List<Player__c>());
                }
                playersByTeam.get(player.Team__c).add(player);
            }
        }
 
        // Validate the number of players per team
        for (Id teamId : playersByTeam.keySet()) {
            List<Player__c> teamPlayers = playersByTeam.get(teamId);
            if (teamPlayers.size() < 7) { 
                throw new InvalidGameConfigurationException('Team ' + teamId + ' has insufficient players. At least 7 players are required.');
            }
        }

        // Lists to store updates
        List<Player__c> playersToUpdate = new List<Player__c>();
        List<Game__c> gamesToUpdate = new List<Game__c>();

        // Process game players
        for (Game_Player__c gamePlayer : gamePlayers) {
            Player__c player = playersMap.get(gamePlayer.Player__c);

            if (player != null) {
                // Check eligibility rules
                if (player.Games_Played__c < 5) {
                    if (player.Player_Status__c != 'Eligible') {
                        player.Player_Status__c = 'Eligible';
                        playersToUpdate.add(player);
                    }
                } else {
                    if (player.Player_Status__c != 'Pending Review') {
                        player.Player_Status__c = 'Pending Review';
                        playersToUpdate.add(player);
                    }

                    // Update Game status if needed
                    if (gamePlayer.Game__c != null && gamesMap.containsKey(gamePlayer.Game__c)) {
                        Game__c game = gamesMap.get(gamePlayer.Game__c);
                        if (game != null && game.Game_Status__c != 'Pending Player') {
                            game.Game_Status__c = 'Pending Player';
                            gamesToUpdate.add(game);
                        }
                    }
                }
            }
        }

        // Perform bulk updates
        try {
            if (!playersToUpdate.isEmpty()) {
                update playersToUpdate;
            }
            if (!gamesToUpdate.isEmpty()) {
                update gamesToUpdate;
            }
        } catch (DmlException e) {
            System.debug('Error during updates: ' + e.getMessage());
        }
    }
}