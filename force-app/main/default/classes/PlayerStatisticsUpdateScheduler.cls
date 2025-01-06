public with sharing class PlayerStatisticsUpdateScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        // Query to retrieve all player records.
        List<Player__c> playersToUpdate = [SELECT Id, Name, Games_Played__c, Win_Rate__c, Wins__c FROM Player__c];
        
        // List to store the updated player records that need to be saved.
        List<Player__c> playersToSave = new List<Player__c>();
        
        for (Player__c player: playersToUpdate) {
            if (player.Games_Played__c == null || player.Games_Played__c == 0) {
                player.Win_Rate__c = 0;
            } else {
                if (player.Wins__c == null || player.Wins__c < 0) {
                    player.Win_Rate__c = 0;
                } else {
                    player.Win_Rate__c = (player.Wins__c / player.Games_Played__c) * 100;
                }
            }
            // Add the player to the list of players to save after the update.
            playersToSave.add(player);
        }
        
        // If there are any players that need to be updated, perform the DML update.
        if (!playersToSave.isEmpty()) {
            Database.update(playersToSave, false);
        }
    }
    
}