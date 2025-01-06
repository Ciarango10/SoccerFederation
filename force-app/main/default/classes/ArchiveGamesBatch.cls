public class ArchiveGamesBatch implements Database.Batchable<SObject>, Schedulable {
    
    // The start method retrieves games older than 6 months with 'Completed' or 'Canceled' status.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoffDate = System.today().addMonths(-6);
        return Database.getQueryLocator([
            SELECT Id, Name, Game_Status__c, Game_Date__c, City__c, Start_Time__c, End_Time__c, Federation__c,Game_Type__c, Home_Team__c, Opponent_Team__c, Is_Invalid__c, Score__c, Stadium__c
            FROM Game__c
            WHERE Game_Status__c IN ('Completed', 'Canceled') 
            AND Game_Date__c < :cutoffDate
        ]);
    }
    
    // The execute method processes each batch of games, archives them, and deletes the original records.
    public void execute(Database.BatchableContext bc, List<Game__c> games) {

        List<Archived_Game__c> archivedGames = new List<Archived_Game__c>(); // Stores records to be archived.
        List<Id> gameIdsToDelete = new List<Id>(); // Collects IDs of games to be deleted.

        // Loop through each game and prepare its archive record.
        for (Game__c game : games) {
            try {
                // Custom Exceptions
                if (game.Home_Team__c == null || game.Opponent_Team__c == null) {
                    throw new InvalidGameConfigurationException('Both Home Team and Opponent Team must be specified for game: ' + game.Name);
                }
                if (game.Game_Type__c == null) {
                    throw new InvalidGameConfigurationException('Game Type is required for game: ' + game.Name);
                }
                if (game.Game_Type__c != 'Friendly' && game.Game_Type__c != 'League' && game.Game_Type__c != 'Cup') {
                    throw new InvalidGameConfigurationException('Invalid Game Type for game: ' + game.Name + '. Allowed values are Friendly, League, or Cup.');
                }
                if (game.Home_Team__c == game.Opponent_Team__c) {
                    throw new InvalidGameConfigurationException('Home Team and Opponent Team cannot be the same for game: ' + game.Name);
                }

                archivedGames.add(new Archived_Game__c(
                    City__c = game.City__c,
                    Start_Time__c = game.Start_Time__c,
                    End_Time__c = game.End_Time__c,
                    Federation__c = game.Federation__c,
                    Game_Date__c = game.Game_Date__c,
                    Game_Status__c = game.Game_Status__c,
                    Game_Type__c = game.Game_Type__c,
                    Home_Team__c = game.Home_Team__c,
                    Opponent_Team__c = game.Opponent_Team__c,
                    Is_Invalid__c = game.Is_Invalid__c,
                    Score__c = game.Score__c,
                    Stadium__c = game.Stadium__c
                ));
                gameIdsToDelete.add(game.Id); // Add game ID for deletion after archival.
            } catch (InvalidGameConfigurationException e) {
                System.debug('Invalid game configuration for Game Id: ' + game.Id + '. Message: ' + e.getMessage());
            }
        }
        
        // Attempts to insert the archive records into Archived_Game__c.  
        if (!archivedGames.isEmpty()) {
            Database.insert(archivedGames, false);
        }
       
        // Attempts to delete the original game records that were successfully archived.     
        if (!gameIdsToDelete.isEmpty()) {
            Database.delete(gameIdsToDelete, false);
        }

    }

    // The finish method sends an email notification when the batch process is complete.
    public void finish(Database.BatchableContext context) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {'carlosarango3101@gmail.com', 'carlos.arango@adaptus.com'});
        email.setSubject('Batch Archive Process Completed');
        email.setPlainTextBody('The ArchiveGamesBatch has completed successfully.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    // Scheduling of the batch process.
    public void execute(SchedulableContext sc) {
        ArchiveGamesBatch agb = new ArchiveGamesBatch();
        Database.executeBatch(agb); // Executes the batch process.
    }
    
}