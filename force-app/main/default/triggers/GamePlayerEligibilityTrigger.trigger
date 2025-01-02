trigger GamePlayerEligibilityTrigger on Game_Player__c (before insert, before update) {
    GamePlayerEligibilityHandler.updateGamePlayerEligibility(Trigger.new);
}