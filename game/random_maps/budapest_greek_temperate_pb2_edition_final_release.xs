include "lib2/rm_core.xs";

/*
** Budapest
** Author: AL (AoM DE XS CODE)
** Based on "Budapest" by AoE II DE Team (But only with one loc per player)
** Dev note: I can add 2 locations per player, but for a map with such a small location radius I prefer to avoid it.
** Date: March 30, 2026 (Final PB2 revision)
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_greek_temperate_dusk_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.3, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt2, 1.0);

   // Define Default Tree Type.
   float randomDefaultTreeTypeFloat = xsRandFloat(0.0, 1.0);
   int defaultTreeType = 0;
   if(randomDefaultTreeTypeFloat < 1.0 / 3.0)
   {
      defaultTreeType = cUnitTypeTreeOak;
   }
   else if(randomDefaultTreeTypeFloat < 2.0 / 3.0)
   {
      defaultTreeType = cUnitTypeTreeCypress;
   }
   else
   {
      defaultTreeType = cUnitTypeTreeOlive;
   }

   rmSetDefaultTreeType(defaultTreeType);

   // Biome Assets.
   int mapForestType = cForestGreekOak;
   int mapWaterType = cWaterGreekSea;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypePig;

   // Water overrides.
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainGreekBeach1, 2.0, 0.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainGreekGrassDirt3, 4.0, 0.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainGreekGrassDirt2, 6.0, 0.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainGreekGrassDirt1, 8.0, 0.0);

   // Map size and terrain init.
   int axisSize = (gameIs1v1() == true) ? 137 : 130;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.70, 0.75));
   if(gameIs1v1() == true)
   {
      // This will determine if the placement is straight or in the shape of a +
      vector startLoc = vectorXZ(0.5, 0.3);
      vector endLoc = vectorXZ(0.5, 0.7);

      // Evaluate a randomness of 0.5; if this condition is met, they align in a cross shape as if it were an X.
      // Disabled from the tournament.
    /* if(xsRandBool(0.5) == true) 
      {
         startLoc = vectorXZ(0.7, 0.7);
         endLoc = vectorXZ(0.3, 0.3);
      } */

      // This will randomize the angle at which the previously established lines will be placed.
      if(xsRandBool(0.5) == true)
      {
         startLoc = xsVectorRotateXZ(startLoc, cPiOver2, cCenterLoc);
         endLoc = xsVectorRotateXZ(endLoc, cPiOver2, cCenterLoc);
      }

      placePlayersOnLine(startLoc, endLoc, 1.0, 1.0);
   }
   else
   {
      rmPlacePlayersOnCircle(0.245);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Lighting.
   rmSetLighting(cLightingSetFott08);

   // Define Classes.
   int playerAreaClassID = rmClassCreate("player area class");

   // Define Classes Constraints.
   int avoidPlayerArea = rmCreateClassDistanceConstraint(playerAreaClassID, 1.0, cClassAreaDistance, "pond vs player area");

   // Define Type Constraints.
   int orcaAvoidOrca = rmCreateTypeDistanceConstraint(cUnitTypeOrca, 30.0, true, "orca vs orca 30");
   int sharkAvoidShark = rmCreateTypeDistanceConstraint(cUnitTypeSharks, 30.0, true, "shark vs shark 30");
   int seaTurtleAvoidSeaTurtle = rmCreateTypeDistanceConstraint(cUnitTypeSeaTurtle, 30.0, true, "sea turtle vs sea turle 30");

   int avoidOrca20 = rmCreateTypeDistanceConstraint(cUnitTypeOrca, 20.0, true, "anything vs orca 20");
   int avoidSharks20 = rmCreateTypeDistanceConstraint(cUnitTypeSharks, 20.0, true, "anything vs shark 20");
   int avoidOrca30 = rmCreateTypeDistanceConstraint(cUnitTypeOrca, 30.0, true, "anything vs orca 30");
   int avoidSharks30 = rmCreateTypeDistanceConstraint(cUnitTypeSharks, 30.0, true, "anything vs shark 30");

   int customAvoidEdge18 = createSymmetricBoxConstraint(rmXMetersToFraction(18.0), rmZMetersToFraction(18.0));
   int customAvoidEdge22 = createSymmetricBoxConstraint(rmXMetersToFraction(22.0), rmZMetersToFraction(22.0));
   int customAvoidEdge50 = createSymmetricBoxConstraint(rmXMetersToFraction(50.0), rmZMetersToFraction(50.0));

   int seaTurtleAvoidLand = rmCreateWaterDistanceConstraint(false, 25.0, "sea turtle vs land");

   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 3.0, "lily vs land");
   int forceLilyNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "lily near land");

   int papyrusAvoidLand = rmCreateWaterDistanceConstraint(false, 4.0, "papyrus vs land");
   int forcePapyrusNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "papyrus near land");

   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0, "reed vs land");
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0, "reed near land");

   int customRelicAvoidEdge = createSymmetricBoxConstraint(rmXTileIndexToFraction(5), rmXTileIndexToFraction(5));

   // Define Overrides.
   vDefaultRelicAvoidWater = vDefaultAvoidWater12;

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.04, 2, 0.5);

   // Player base areas.
   float playerBaseAreaSize = rmRadiusToAreaFraction(33.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int playerBaseAreaID = rmAreaCreate("player base area " + p);
      rmAreaSetLocPlayer(playerBaseAreaID, p);
      rmAreaSetSize(playerBaseAreaID, playerBaseAreaSize);
      rmAreaSetCoherence(playerBaseAreaID, 0.35);
      rmAreaSetEdgeSmoothDistance(playerBaseAreaID, 3);
      rmAreaAddToClass(playerBaseAreaID, playerAreaClassID);
   }  

   rmAreaBuildAll();

   // Ponds
   float pondSize = 0.06;
   
   for(int i = 0; i < 4; i++)
   {
      int pondID = rmAreaCreate("pond " + i);
      rmAreaSetWaterType(pondID, mapWaterType);
      rmAreaSetSize(pondID, pondSize); 
      rmAreaSetCoherence(pondID, 0.1);
      rmAreaSetEdgeSmoothDistance(pondID, 1, false);
      rmAreaSetWaterHeightBlend(pondID, cFilter5x5Gaussian, 25, 10);
      if(i == 0)
      {
         rmAreaSetLoc(pondID, vectorXZ(0.5, 0.01));
         rmAreaAddInfluenceSegment(pondID, vectorXZ(0.375, 0.0), vectorXZ(0.625, 0.0));
      }
      else if(i == 1)
      {
         rmAreaSetLoc(pondID, vectorXZ(0.5, 0.99));
         rmAreaAddInfluenceSegment(pondID, vectorXZ(0.375, 1.0), vectorXZ(0.625, 1.0));
      }
      else if(i == 2)
      {
         rmAreaSetLoc(pondID, vectorXZ(0.01, 0.5));
         rmAreaAddInfluenceSegment(pondID, vectorXZ(0.01, 0.375), vectorXZ(0.01, 0.625));
      }
      else if (i == 3)
      {
         rmAreaSetLoc(pondID, vectorXZ(0.99, 0.5));
         rmAreaAddInfluenceSegment(pondID, vectorXZ(0.99, 0.375), vectorXZ(0.99, 0.625));
      }
      rmAreaAddConstraint(pondID, avoidPlayerArea);
   }  
   
   rmAreaBuildAll();

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 55.0, 75.0, cSettlementDist1v1, cBiasBackward | cBiasDefensive, 
                                    cInAreaDefault, cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 75.0, 110.0, cSettlementDist1v1, cBiasAggressive | cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 55.0, 75.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 90.0, 165.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Starting objects.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, 
                                    cBiasNone, cInAreaDefault, cLocSideOpposite);
   }  
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);
   }
   
   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(3, 5));
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(3, 5));
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 7), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forest.
   float avoidForestMeters = 22.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(75), rmTilesToAreaFraction(85));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidWater12);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 15.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 15.0);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward);
      addObjectLocsPerPlayer(closeGoldID, false, 1, 70.0, 80.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   float closeHuntFloat = xsRandFloat(0.0, 1.0);

   int closeHuntID = rmObjectDefCreate("close hunt");
   if(closeHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(3, 4));
   }
   else if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(6, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(4, 6));
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(75.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 80.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);

   int farHunt1ID = rmObjectDefCreate("far hunt 1");
   if(farHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(farHunt1ID, cUnitTypeBoar, xsRandInt(3, 5));
      rmObjectDefAddItem(farHunt1ID, cUnitTypeDeer, xsRandInt(2, 3));
   }
   else if(farHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(farHunt1ID, cUnitTypeDeer, xsRandInt(6, 9));
   }
   else
   {
      rmObjectDefAddItem(farHunt1ID, cUnitTypeAurochs, xsRandInt(3, 5));
      rmObjectDefAddItem(farHunt1ID, cUnitTypeDeer, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farHunt1ID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHunt1ID, false, 1, 70.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHunt1ID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 2 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 6));
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(1, 3));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 7));
         }
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidImpassableLand20);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 70.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, mapHerdType, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 55.0;

   int closePredatorID = rmObjectDefCreate("close predator ");
   rmObjectDefAddItem(closePredatorID, cUnitTypeWolf, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closePredatorID, 70.0);
   addObjectLocsPerPlayer(closePredatorID, false, 1 * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   int farPredatorID = rmObjectDefCreate("far predator ");
   rmObjectDefAddItem(farPredatorID, cUnitTypeBear, 2);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farPredatorID, 85.0);
   addObjectLocsPerPlayer(farPredatorID, false, 1 * getMapAreaSizeFactor(), 85.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.7);
      
   // Statue Melagius Definition.
   int statueMelagiusDefID = rmObjectDefCreate("statue melagius def");
   rmObjectDefAddItem(statueMelagiusDefID, cUnitTypeStatueMelagius, 1);

   // Relic Definition.
   int relicDefID = rmObjectDefCreate("relic def");
   rmObjectDefAddItem(relicDefID, cUnitTypeRelic, 1);

   // Torch Definition.
   int torchDefID = rmObjectDefCreate("torch def");
   rmObjectDefAddItem(torchDefID, cUnitTypeTorch, 1);

   // Column Definition.
   int columnDefID = rmObjectDefCreate("column def");
   rmObjectDefAddItem(columnDefID, cUnitTypeColumns, 1);

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicLocID = rmObjectDefCreate("relic loc");
   rmObjectDefAddConstraint(relicLocID, customRelicAvoidEdge);
   rmObjectDefAddConstraint(relicLocID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicLocID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicLocID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicLocID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicLocID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicLocID, 80.0);
   addObjectLocsPerPlayer(relicLocID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   // Run locGen.
   bool successfulRelics = generateLocs("relic locs", true, false, true, false);

   // Get number of relic locations
   int numRelicLocs = rmLocGenGetNumberLocs();

   // For the tournament, we will only use these custom angles.
   float[] angleCandidates = new float(1, cPiOver2);
   angleCandidates.add(cPiOver2 * 0.45);
   
   int numAngleCandidates = angleCandidates.size();

   for(int i = 0; i < numRelicLocs; i++)
   {
      
      // LocGen stuff.
      vector relicLoc = rmLocGenGetLoc(i);

      // Relic stuff.
      float relicRotationAngle = angleCandidates[xsRandInt(0, numAngleCandidates - 1)];
     // relicRotationAngle = modSnapAngle(relicRotationAngle, cPiOver4);

      int relicID = rmObjectDefCreateObject(relicDefID);
      rmObjectSetItemRotation(relicID, 0, cItemRotateCustom, relicRotationAngle);
      rmObjectPlaceAtLoc(relicID, 0, relicLoc);

      // Statue.
      vector statueLoc = relicLoc.translateXZ(rmXTilesToFraction(1), relicRotationAngle);

      float statueAngle = xsVectorAngleAroundY(statueLoc, relicLoc);

      int statueID = rmObjectDefCreateObject(statueMelagiusDefID);
      rmObjectSetItemRotation(statueID, 0, cItemRotateCustom, statueAngle + cPiOver2);
      rmObjectPlaceAtLoc(statueID, 0, statueLoc);

      // Small Torches.
      vector torchCLoc = relicLoc.translateXZ(rmXTilesToFraction(1), relicRotationAngle - cPiOver2);
      vector torchDLoc = relicLoc.translateXZ(-rmXTilesToFraction(1), relicRotationAngle - cPiOver2);

      int torchCID = rmObjectDefCreateObject(torchDefID);
      rmObjectSetItemVariation(torchCID, 0, 0);
      rmObjectPlaceAtLoc(torchCID, 0, torchCLoc);

      int torchDID = rmObjectDefCreateObject(torchDefID);
      rmObjectSetItemVariation(torchDID, 0, 0);
      rmObjectPlaceAtLoc(torchDID, 0, torchDLoc);

   }

   if(successfulRelics)
   {
      // rmLocGenApply is not necessary here, since it would only be used for a dummy reference object 
      // for angle reference and placement constraints.
      resetLocGen();
   }

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(47.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 12 * getMapAreaSizeFactor());

   // Stragglers
   int numStragglers = xsRandInt(3, 4);
   int stragglerType = 0;
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      vector loc = rmGetPlayerLoc(i, 0);

      for(int j = 0; j < numStragglers; j++)
      {

         // Straggler Rand Type:
         int stragglerCase = xsRandInt(0, 2);
         if(stragglerCase == 0)
         {
            stragglerType = cUnitTypeTreeOak;
         }
         else if(stragglerCase == 1)
         {
            stragglerType = cUnitTypeTreeCypress;
         }
         else if(stragglerCase == 2)
         {
            stragglerType = cUnitTypeTreeOlive;
         } 

         int startingStragglerID = rmObjectDefCreate("starting straggler " + i + j);
         rmObjectDefAddItem(startingStragglerID, stragglerType, 1);
         rmObjectDefAddConstraint(startingStragglerID, vDefaultAvoidAll8);
         rmObjectDefPlaceAtLoc(startingStragglerID, 0, loc, cStartingStragglerMinDist, cStartingStragglerMaxDist, 1, true);
         
      }  
   }
   
   // Fish.
   float fishDistMeters = 35.0;
   int fishType = cUnitTypeMahi;

   if(gameIs1v1() == true)
   {
      int fishID = rmObjectDefCreate("fish 1v1 ");
      rmObjectDefAddItem(fishID, fishType, 2, 3.5);
      placeObjectDefInLine(fishID, 0, 4 * getMapAreaSizeFactor(), vectorXZ(0.345, 0.065), vectorXZ(0.655, 0.065), 0.5, 0.5);
      placeObjectDefInLine(fishID, 0, 4 * getMapAreaSizeFactor(), vectorXZ(0.345, 0.935), vectorXZ(0.655, 0.935), 0.5, 0.5);
      placeObjectDefInLine(fishID, 0, 4 * getMapAreaSizeFactor(), vectorXZ(0.065, 0.345), vectorXZ(0.065, 0.655), 0.5, 0.5);
      placeObjectDefInLine(fishID, 0, 4 * getMapAreaSizeFactor(), vectorXZ(0.935, 0.345), vectorXZ(0.935, 0.655), 0.5, 0.5);
   }
   else
   {
      for(int i = 0; i < 4; i++)
      {
         int pondID = rmAreaGetID("pond " + i);
         int fishID = rmObjectDefCreate("fish " + i);
         rmObjectDefAddItem(fishID, fishType, 2, 3.5);
         rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 8.0));
         rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));
         rmObjectDefAddConstraint(fishID, createSymmetricBoxConstraint(rmXTileIndexToFraction(4.5), rmXTileIndexToFraction(4.5)));
         rmObjectDefAddConstraint(fishID, rmCreateAreaConstraint(pondID));
         addObjectLocsPerPlayer(fishID, false, 2, 10.0, rmXFractionToMeters(1.0), fishDistMeters, cBiasNone, cInAreaNone);
      }
   }

   generateLocs("fish locs");

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);

   // Relic decoration.
   float relicAreaFraction = rmTilesToAreaFraction(55);

   int numRelics = rmObjectDefGetNumberCreatedObjects(relicDefID);

   for(int i = 0; i < numRelics; i++)
   {
      int relicAuxID = rmObjectDefGetCreatedObject(relicDefID, i);

      vector relicLoc = rmObjectGetLoc(relicAuxID);

      if(relicLoc == cInvalidVector)
      {
         continue;
      }

      int relicAreaID = rmAreaCreate("relic area " + i);
      rmAreaSetLoc(relicAreaID, relicLoc);
      rmAreaSetCoherence(relicAreaID, 0.45);
      rmAreaAddTerrainLayer(relicAreaID, cTerrainGreekGrassDirt3, 0, 1);  
      rmAreaSetTerrainType(relicAreaID, cTerrainGreekRoad1);
      rmAreaSetSize(relicAreaID, relicAreaFraction);
      rmAreaSetEdgeSmoothDistance(relicAreaID, 3);
      rmAreaAddConstraint(relicAreaID, vDefaultAvoidImpassableLand4);
      rmAreaAddTerrainConstraint(relicAreaID, rmCreateLocMaxDistanceConstraint(relicLoc, 5.0));
      rmAreaBuild(relicAreaID);
   }

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad2, 2.5);

   // Random trees placement.
   for(int i = 0; i < 3; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = 26 / 2;
      if(i == 2)
      {
         treeDensity = xsRandInt(4, 5);
      }
      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreeOak; treeName = "oak "; break; }
         case 1: { treeTypeID = cUnitTypeTreeOlive; treeName = "olive "; break; }
         case 2: { treeTypeID = cUnitTypeTreeCypress; treeName = "cypress "; break; }
      }

      // Tree template.
      int treeDefID = rmObjectDefCreate(treeName);
      rmObjectDefAddItem(treeDefID, treeTypeID, 1);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidAll);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidCollideable);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidImpassableLand);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidWater);
      rmObjectDefAddConstraint(treeDefID, vDefaultAvoidSettlementWithFarm);
      rmObjectDefAddConstraint(treeDefID, vDefaultTreeAvoidTree);
      rmObjectDefAddConstraint(treeDefID, avoidRoad1);
      rmObjectDefAddConstraint(treeDefID, avoidRoad2);
      rmObjectDefPlaceAnywhere(treeDefID, 0, treeDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 25;
      int plantsGroupDensity = 5;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantGreekBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantGreekShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantGreekFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantGreekWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantGreekGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantGreekFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantGreekWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
      }
      
      // Plant template.
      int plantTypeDef = rmObjectDefCreate(plantName);
      if(i < 5)
      {
         rmObjectDefAddItem(plantTypeDef, plantID, 1);
      }
      else
      {
         rmObjectDefAddItemRange(plantTypeDef, plantID, 1, 3, 0.0, 4.0);
      }
      rmObjectDefAddConstraint(plantTypeDef, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidImpassableLand2);
      rmObjectDefAddConstraint(plantTypeDef, vDefaultEmbellishmentAvoidWater); 
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad1);
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad2);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Flowers.
   int flowersID = rmObjectDefCreate("Flowers");
   rmObjectDefAddItem(flowersID, cUnitTypeFlowers, 1);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersID, avoidRoad1);
   rmObjectDefAddConstraint(flowersID, avoidRoad2);
   rmObjectDefPlaceAnywhere(flowersID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);   
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(logID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logID, vDefaultAvoidEdge);   
   rmObjectDefAddConstraint(logID, avoidRoad1);
   rmObjectDefAddConstraint(logID, avoidRoad2);   
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int logGroupID = rmObjectDefCreate("log group");
   rmObjectDefAddItem(logGroupID, cUnitTypeRottingLog, 2, 2.0);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidEdge);   
   rmObjectDefAddConstraint(logGroupID, avoidRoad1);
   rmObjectDefAddConstraint(logGroupID, avoidRoad2);   
   rmObjectDefPlaceAnywhere(logGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Water lilies.
   int waterLilyID = rmObjectDefCreate("lily");
   rmObjectDefAddItem(waterLilyID, cUnitTypeWaterLily, 1);
   rmObjectDefAddConstraint(waterLilyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyGroupID = rmObjectDefCreate("lily group");
   rmObjectDefAddItemRange(waterLilyGroupID, cUnitTypeWaterLily, 2, 4);
   rmObjectDefAddConstraint(waterLilyGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyRedID = rmObjectDefCreate("lily red");
   rmObjectDefAddItem(waterLilyRedID, cUnitTypeWaterLilyRed, 1);
   rmObjectDefAddConstraint(waterLilyRedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyRedID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyRedID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyRedID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyRedGroupID = rmObjectDefCreate("lily red group");
   rmObjectDefAddItemRange(waterLilyRedGroupID, cUnitTypeWaterLilyRed, 2, 4);
   rmObjectDefAddConstraint(waterLilyRedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyRedGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyRedGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyRedGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Papirus
   int papyrusID = rmObjectDefCreate("Papyrus");
   rmObjectDefAddItem(papyrusID, cUnitTypePapyrus, 1);
   rmObjectDefAddConstraint(papyrusID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   int papyrusGroupID = rmObjectDefCreate("Papyrus group");
   rmObjectDefAddItemRange(papyrusGroupID, cUnitTypePapyrus, 3, 5);
   rmObjectDefAddConstraint(papyrusGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusGroupID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusGroupID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusGroupID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int waterReedGroupID = rmObjectDefCreate("reed group");
   rmObjectDefAddItemRange(waterReedGroupID, cUnitTypeWaterReeds, 2, 3);
   rmObjectDefAddConstraint(waterReedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedGroupID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedGroupID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedGroupID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweeds near from the shores.
   int shoreSeaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(shoreSeaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMaxWaterDepthConstraint(2.35));
   rmObjectDefPlaceAnywhere(shoreSeaweedID, 0, 30 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Seaweeds far from the shores.
   int deepSeaweedID = rmObjectDefCreate("deep seaweed");
   rmObjectDefAddItem(deepSeaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(deepSeaweedID, rmCreateMinWaterDepthConstraint(2.0));
   rmObjectDefAddConstraint(deepSeaweedID, rmCreateMaxWaterDepthConstraint(3.0));
   rmObjectDefAddConstraint(deepSeaweedID, createSymmetricBoxConstraint(rmXTileIndexToFraction(8), rmXTileIndexToFraction(8)));
   rmObjectDefPlaceAnywhere(deepSeaweedID, 0, 50.0 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Water plants.
   int waterPlantID = rmObjectDefCreate("water plant shores");
   rmObjectDefAddItem(waterPlantID, cUnitTypeWaterPlant, 1);
   rmObjectDefAddConstraint(waterPlantID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(waterPlantID, rmCreateMaxWaterDepthConstraint(2.6));
   rmObjectDefPlaceAnywhere(waterPlantID, 0, 20 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Water Animals.

   // Orcas.
   int orcaID = rmObjectDefCreate("orca");
   rmObjectDefAddItem(orcaID, cUnitTypeOrca);
   rmObjectDefAddConstraint(orcaID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(orcaID, vDefaultAvoidLand22);
   rmObjectDefAddConstraint(orcaID, customAvoidEdge18);
   rmObjectDefAddConstraint(orcaID, orcaAvoidOrca);
   rmObjectDefPlaceAnywhere(orcaID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Sharks.
   int sharkID = rmObjectDefCreate("shark");
   rmObjectDefAddItem(sharkID, cUnitTypeSharks);
   rmObjectDefAddConstraint(sharkID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(sharkID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sharkID, vDefaultAvoidLand22);
   rmObjectDefAddConstraint(sharkID, customAvoidEdge18);
   rmObjectDefAddConstraint(sharkID, avoidOrca20);
   rmObjectDefAddConstraint(sharkID, sharkAvoidShark);
   rmObjectDefPlaceAnywhere(sharkID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Sea Turtles.
   int seaTurtleID = rmObjectDefCreate("sea turtles");
   rmObjectDefAddItem(seaTurtleID, cUnitTypeSeaTurtle);
   rmObjectDefAddConstraint(seaTurtleID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(seaTurtleID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(seaTurtleID, seaTurtleAvoidLand);
   rmObjectDefAddConstraint(seaTurtleID, customAvoidEdge22);
   rmObjectDefAddConstraint(seaTurtleID, avoidOrca30);
   rmObjectDefAddConstraint(seaTurtleID, avoidSharks30);
   rmObjectDefAddConstraint(seaTurtleID, seaTurtleAvoidSeaTurtle);
   rmObjectDefPlaceAnywhere(seaTurtleID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Lighting Override.
   lightingOverride();

   rmSetProgress(1.0);
}
