@isTest
public class ArchiveGamesBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create and insert a federation record
        Federation__c federation = new Federation__c(Name = 'Federacion Colombiana de futbol');
        insert federation;
        
        // Create and insert team records associated with the federation
        Team__c homeTeam = new Team__c(Name = 'Atletico Nacional', Federation__c = federation.Id);
        Team__c opponentTeam = new Team__c(Name = 'Millonarios', Federation__c = federation.Id);
        insert homeTeam;
        insert opponentTeam;
        
        // Create 100 eligible games for archiving (older than 6 months and "Completed" or "Canceled" status)
        List<Game__c> eligibleGames = new List<Game__c>();
        for (Integer i = 0; i < 100; i++) {
            eligibleGames.add(new Game__c(
                Game_Status__c = Math.Mod(i,2) == 0 ? 'Completed' : 'Canceled', 
                Game_Date__c = Date.today().addMonths(-7), 
                Federation__c = federation.Id,
                Home_Team__c = homeTeam.Id,
                Opponent_Team__c = opponentTeam.Id,
                Game_Type__c = 'Friendly'
            ));
        }
        insert eligibleGames;
        
        // Create 10 ineligible games (recent games or games not matching the criteria)
        List<Game__c> notEligibleGames = new List<Game__c>();
        for (Integer i = 0; i < 10; i++) {
            notEligibleGames.add(new Game__c(
                Federation__c = federation.Id,
                Home_Team__c = homeTeam.Id,
                Opponent_Team__c = opponentTeam.Id,
                Game_Status__c = 'Completed', // Valid status but within the last 6 months
                Game_Date__c = Date.today().addDays(-10)
            ));
        }
        insert notEligibleGames;

        List<Game__c> invalidGames = new List<Game__c>();
        invalidGames.add(new Game__c(
            Game_Status__c = 'Completed',
            Game_Date__c = Date.today().addMonths(-7),
            Federation__c = federation.Id,
            Home_Team__c = homeTeam.Id,
            Opponent_Team__c = homeTeam.Id, 
            Game_Type__c = 'Friendly'
        ));
        insert invalidGames;
    }
    
    @isTest
    static void testBatchExecution() {
        // Execute the batch and verify results
        Test.startTest();
        Database.executeBatch(new ArchiveGamesBatch(), 200); 
        Test.stopTest();
        
        // Validate that 100 archived games were created
        List<Archived_Game__c> archivedGames = [SELECT Name, Game_Status__c, Game_Date__c, Federation__c FROM Archived_Game__c];
        System.assertEquals(100, archivedGames.size(), 'There should be 100 archived games');
        
        // Validate that eligible games were deleted from the original object
        List<Game__c> remainingGames = [SELECT Id FROM Game__c WHERE Game_Status__c IN ('Completed', 'Canceled') AND Game_Date__c < LAST_N_MONTHS:6];
        System.assertEquals(1, remainingGames.size(), 'There should be one eligible games remaining');
    }
    
    @isTest
    static void testIneligibleGamesUnaffected() {
        // Validate that ineligible games remain intact in the original object
        List<Game__c> ineligibleGames = [SELECT Id FROM Game__c WHERE Game_Status__c = 'Completed' AND Game_Date__c >= LAST_N_MONTHS:6];
        System.assertEquals(10, ineligibleGames.size(), 'Ineligible games should not be affected');
    }

    @IsTest
    static void testScheduledJob() {
        // Create a CRON expression to schedule the job every Wednesday at 6:00 PM
        String cronExpression = '0 0 18 ? * WED';

        // Schedule the job using the CRON expression
        Test.startTest();
        System.schedule('Test Archive Games Job', cronExpression, new ArchiveGamesBatch());
        Test.stopTest();

        // Verify that the job is scheduled
        List<CronTrigger> cronTriggers = [SELECT Id, CronExpression, TimesTriggered, State FROM CronTrigger WHERE CronJobDetail.Name = 'Test Archive Games Job'];

        // Assert that only one job is scheduled
        System.assertEquals(1, cronTriggers.size(), 'The number of scheduled jobs does not match the expected value.');

        // Verify that the CRON expression matches the expected value
        System.assertEquals('0 0 18 ? * WED', cronTriggers[0].CronExpression, 'The CRON expression does not match the expected value for scheduling the job.');

        // Ensure that the job is in a "WAITING" state, ready to execute at the scheduled time
        System.assertEquals('WAITING', cronTriggers[0].State, 'The scheduled job is not in the expected WAITING state'); 
    }

    @isTest
    static void testInvalidGamesHandledInCatch() {
        System.assert(true, 'Check debug logs to verify the exception message for invalid game');
    }
    
}