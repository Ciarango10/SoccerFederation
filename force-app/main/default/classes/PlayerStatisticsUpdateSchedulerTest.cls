@isTest
private class PlayerStatisticsUpdateSchedulerTest {
    
    @isTest
    static void testSchedulerWithEligibleRecords() {
        // Create mock Player__c records with some wins and games played
        List<Player__c> players = new List<Player__c>{
            new Player__c(Name = 'Player 1', Wins__c = 5, Games_Played__c = 10),
            new Player__c(Name = 'Player 2', Wins__c = 0, Games_Played__c = 5),
            new Player__c(Name = 'Player 3', Wins__c = 3, Games_Played__c = 6)
        };
        insert players;
        
        // Instantiate the Scheduler and run it
        Test.startTest();
        PlayerStatisticsUpdateScheduler scheduler = new PlayerStatisticsUpdateScheduler();
        String cronExp = '0 0 0 1 1 ? 2099';  
        System.schedule('Test Player Statistics Update', cronExp, scheduler);
        Test.stopTest();
        
        // Query the updated records and assert the win rate calculations
        List<Player__c> updatedPlayers = [SELECT Name, Win_Rate__c FROM Player__c];
        
        // Assert that the Win Rate is calculated correctly
        for (Player__c player : updatedPlayers) {
            if (player.Name == 'Player 1') {
                System.assertEquals(50, player.Win_Rate__c, 'Win Rate for Player 1 should be 50%');
            } else if (player.Name == 'Player 2') {
                System.assertEquals(0, player.Win_Rate__c, 'Win Rate for Player 2 should be 0%');
            } else if (player.Name == 'Player 3') {
                System.assertEquals(50, player.Win_Rate__c, 'Win Rate for Player 3 should be 50%');
            }
        }
    }
    
    @isTest
    static void testSchedulerWithNoEligibleRecords() {
        // Create mock Player__c records with zero games played
        List<Player__c> players = new List<Player__c>{
            new Player__c(Name = 'Player 1', Wins__c = 0, Games_Played__c = 0),
            new Player__c(Name = 'Player 2', Wins__c = 0, Games_Played__c = 0)
        };
        insert players;
        
        // Instantiate the Scheduler and run it
        Test.startTest();
        PlayerStatisticsUpdateScheduler scheduler = new PlayerStatisticsUpdateScheduler();
        String cronExp = '0 0 0 1 1 ? 2099'; 
        System.schedule('Test Player Statistics Update', cronExp, scheduler);
        Test.stopTest();
        
        // Query the updated records and assert that the Win Rate is 0 for players with 0 games played
        List<Player__c> updatedPlayers = [SELECT Name, Win_Rate__c FROM Player__c];
        
        // Assert that the Win Rate is 0 for all players with 0 games played
        for (Player__c player : updatedPlayers) {
            System.assertEquals(0, player.Win_Rate__c, 'Win Rate should be 0 for players with 0 games played');
        }
    }
    
    @isTest
    static void testElseCondition() {
        // Insert a player record with specific conditions to reach the else block
        Player__c testPlayer = new Player__c(
            Name = 'Test Player',
            Games_Played__c = 1, 
            Wins__c = null       
        );
        insert testPlayer;
        
        // Execute the scheduler
        Test.startTest();
        PlayerStatisticsUpdateScheduler scheduler = new PlayerStatisticsUpdateScheduler();
        scheduler.execute(null); 
        Test.stopTest();
        
        // Verify the outcome
        Player__c updatedPlayer = [SELECT Win_Rate__c FROM Player__c WHERE Id = :testPlayer.Id];
        System.assertEquals(0, updatedPlayer.Win_Rate__c, 'Win_Rate__c should be 0 when Wins__c is null.');
    }
    
}