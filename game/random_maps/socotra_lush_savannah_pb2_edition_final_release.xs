include "lib2/rm_core.xs";

/*
** Socotra
** Author: AL (AoM DE XS CODE)
** Based on "Socotra" by AoE II DE Team
** Date: December 23, 2025
** Update: February 3, 2026
** Final revision: March 30, 2026
*/

void generateTriggers()
{
   rmTriggerAddScriptLine("rule _settlement");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   for(int i = 1; i <= cNumberPlayers; i++)");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      trModifyProtounitData(\"AbstractSettlement\", i, 7, 10, 0);");
   rmTriggerAddScriptLine("      xsDisableSelf();");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("}");
}

// Override.
mutable void applySuddenDeath()
{
   // Remove all settlements.
   rmRemoveUnitType(cUnitTypeSettlement);

   // Add some tents (not around towers).
   int tentID = rmObjectDefCreate(cSuddenDeathTentName);
   rmObjectDefAddItem(tentID, cUnitTypeTent, 1);
   rmObjectDefAddConstraint(tentID, vDefaultAvoidCollideable);
   addObjectLocsPerPlayer(tentID, true, cNumberSuddenDeathTents, cStartingTowerMinDist - 10.0,
                          cStartingTowerMaxDist + 10.0, cStartingTowerAvoidanceMeters);

   generateLocs("sudden death tent locs");
}

// Predators can be very hostile when they are very close, so we will reduce the number and the radius.
mutable void placeKotHObjects(int predatorProtoID = cUnitTypeShadePredator, vector areaLoc = cCenterLoc)
{
   if(gameIsKotH() == false)
   {
      return;
   }

   // If you don't want this initialized, override the above function with an empty body.
   initializeKotHArea(areaLoc);

   // Plenty at the center.
   int plentyID = rmObjectDefCreate(cKotHPlentyName);
   rmObjectDefAddItem(plentyID, cUnitTypePlentyVaultKOTH, 1);
   rmObjectDefAddToClass(plentyID, vKotHClassID);
   rmObjectDefPlaceAtLoc(plentyID, 0, areaLoc);

   // Spawn titan if we're in high gauntlet difficulties
   #if (cGauntletDifficulty >= cDifficultyLegendary)
   {
      int titanID = rmObjectDefCreate(cKotHTitanName);
      rmObjectDefAddItem(titanID, cUnitTypeTitanPredator, 1);
      rmObjectDefAddToClass(titanID, vKotHClassID);
      placeObjectDefInCircle(titanID, 0, 2, 10.0, randRadian(), 0.0, 0.0, areaLoc);
   }
   #elif (cGauntletDifficulty >= cDifficultyExtreme)
   {
      int titanID = rmObjectDefCreate(cKotHTitanName);
      rmObjectDefAddItem(titanID, cUnitTypeTitanPredator, 1);
      rmObjectDefAddToClass(titanID, vKotHClassID);
      placeObjectDefInCircle(titanID, 0, 1, 10.0, randRadian(), 0.0, 0.0, areaLoc);
   }
   #endif

   // Surrounding embellishment objects/predators.
   int predatorID = rmObjectDefCreate(cKotHPredatorName);
   rmObjectDefAddItem(predatorID, predatorProtoID, 1);
   rmObjectDefAddToClass(predatorID, vKotHClassID);
   placeObjectDefInCircle(predatorID, 0, 4, 7.0, randRadian(), 0.0, 0.0, areaLoc);
}

void generate()
{
   rmSetProgress(0.0);

   // Define Mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.3, 2);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSavannah1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSavannah2, 5.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt1, 3.0);

   // Define Forests.
   int lushSavannahCustomForestID = rmCustomForestCreate();
   rmCustomForestSetTerrain(lushSavannahCustomForestID, cTerrainEgyptForestPalmGrass);
   rmCustomForestSetParams(lushSavannahCustomForestID, 1.0, 1.0);
   rmCustomForestAddTreeType(lushSavannahCustomForestID, cUnitTypeTreePalm, 1.0);
   rmCustomForestAddTreeType(lushSavannahCustomForestID, cUnitTypeTreeOak, 0.5);
   rmCustomForestAddTreeType(lushSavannahCustomForestID, cUnitTypeTreeSavannah, 1.5);
   rmCustomForestAddUnderbrushType(lushSavannahCustomForestID, cUnitTypePlantEgyptianBush, 0.1);
   rmCustomForestAddUnderbrushType(lushSavannahCustomForestID, cUnitTypePlantEgyptianWeeds, 0.1);
   rmCustomForestAddUnderbrushType(lushSavannahCustomForestID, cUnitTypePlantEgyptianShrub, 0.1);
   rmCustomForestAddUnderbrushType(lushSavannahCustomForestID, cUnitTypePlantEgyptianGrass, 0.1);

   // Define Default Tree Type.
   float randomDefaultTreeTypeFloat = xsRandFloat(0.0, 1.0);
   int defaultTreeType = 0;
   if(randomDefaultTreeTypeFloat < 1.0 / 3.0)
   {
      defaultTreeType = cUnitTypeTreeOak;
   }
   else if(randomDefaultTreeTypeFloat < 2.0 / 3.0)
   {
      if(xsRandBool(0.5) == true)
      {
         defaultTreeType = cUnitTypeTreeSavannah;
      }
      else
      {
         defaultTreeType = cUnitTypeTreeSavannahOld;
      } 
   }
   else
   {
      defaultTreeType = cUnitTypeTreePalm;
   }
   
   rmSetDefaultTreeType(defaultTreeType);

   // Biome Assets.
   int mapWaterType = cWaterEgyptSea;
   int mapForestType = lushSavannahCustomForestID;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypePig;

   // Water overrides.
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainEgyptBeach1, 2.0, 1.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainEgyptGrassDirt3, 4.0, 1.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainEgyptGrassDirt2, 7.0, 1.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainEgyptGrassDirt1, 8.0, 1.0);

   // Map size and terrain init.
   int axisSize = (gameIs1v1() == true) ? 121 - cNumberPlayers : 118 - cNumberPlayers;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeWater(mapWaterType);

   // Socotra Stuff.
   float continentFraction = 0.3995;
   float playerContinentEdgeDistMeters = (gameIs1v1() == true) ? 34.0 : 37.0;
   float placementRadiusMeters = rmFractionToAreaRadius(continentFraction) - playerContinentEdgeDistMeters;
   float placementFraction = smallerMetersToFraction(placementRadiusMeters);

   if(gameIsKotH())
   {  // Push the players further out if it's KoTH.
      placementFraction += smallerMetersToFraction(7.0);
   }
   
   // Player placement.
   rmSetTeamSpacingModifier(0.95);
   rmPlacePlayersOnCircle(placementFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetAotgAotgSummer);

   // Define Classes.

   // Define Classes Constraints.

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

   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0, "reed vs land");
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0, "force reed near land");

   int papyrusAvoidLand = rmCreateWaterDistanceConstraint(false, 3.0, "papyrus vs land");
   int forcePapyrusNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "force papyrus near land");

   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 3.0, "lily vs land");
   int forceLilyNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "force lily near land");

   // Define Overrides.
   float cStartingObjectAvoidanceMetersOverride = 20.0;

   vDefaultGoldAvoidWater = vDefaultAvoidWater16;
   vDefaultGoldAvoidImpassableLand = vDefaultAvoidImpassableLand6;
   vDefaultGoldAvoidAll = vDefaultAvoidAll4;

   vDefaultFoodAvoidAll = vDefaultAvoidAll4;
   vDefaultFoodAvoidImpassableLand = vDefaultAvoidImpassableLand4;

   vDefaultForestAvoidAll = vDefaultAvoidAll6;
   vDefaultAvoidSettlementRange = rmCreateTypeDistanceConstraint(cUnitTypeAbstractSettlement, 15.0);
   vDefaultAvoidTowerLOS = rmCreateTypeDistanceConstraint(cUnitTypeSentryTower, 18.0);

   rmSetProgress(0.1);

   // Continent.
   int continentID = rmAreaCreate("socotra continent");
   rmAreaSetSize(continentID, continentFraction);
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaSetMix(continentID, baseMixID);
   rmAreaSetCoherence(continentID, 0.55);
   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 3.8, 0.05, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0); // Only grow upwards to not get below water height.
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 20.0);
   rmAreaSetHeight(continentID, 0.25);
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 10, 10);
   rmAreaSetEdgeSmoothDistance(continentID, 15);
   rmAreaAddConstraint(continentID, createSymmetricBoxConstraint(0.075), 0.0, 5.0);
   rmAreaBuild(continentID);

   // Continent Constraints.
   int avoidSocoEdges = rmCreateAreaEdgeDistanceConstraint(continentID, 15.0, "anything vs continent edges 15");

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   // Starting objects distance reduction.
   float distanceReduction = 4.0;

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);

   // Make the towers mirrored first, to avoid in an extremely rare case where the mirrored mines do not match 
   // due to the obstruction of a tower.
   if(gameIs1v1())
   { 
      addMirroredObjectLocsPerPlayerPair(startingTowerID, true, 2, cStartingTowerMinDist - distanceReduction, cStartingTowerMaxDist - 
                                          distanceReduction, cStartingTowerAvoidanceMeters, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(startingTowerID, true, 2, cStartingTowerMinDist - distanceReduction, cStartingTowerMaxDist - 
                              distanceReduction, cStartingTowerAvoidanceMeters, cBiasAggressive);
   }

   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   if(gameIs1v1() == true)
   {  // Since the map is very small, I decided to remove the avoidTowerLOS constraint, 
      // which allows for more permissive settlement placement.
      // However, sometimes the settlement can be seen from the start of the game, so if this happens, 
      // it should be for both players by placing towers and settlements in mirror.
      addMirroredObjectLocsPerPlayerPair(firstSettlementID, false, 1, 45.0, 65.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 45.0, 65.0, cCloseSettlementDist, cBiasAggressive);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1); 
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 55.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Starting objects.
   // We will use mirror starting gold mines and hunts for the tournament.

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   if(gameIs1v1())
   {
      addMirroredObjectLocsPerPlayerPair(startingGoldID, false, 1, cStartingGoldMinDist - distanceReduction, cStartingGoldMaxDist - 
                                          distanceReduction, cStartingObjectAvoidanceMetersOverride, cBiasDefensive);
   }
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist - distanceReduction, cStartingGoldMaxDist - 
                              distanceReduction, cStartingObjectAvoidanceMetersOverride, cBiasDefensive);
   }

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(7, 9));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(7, 9));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(startingHuntID, false, 1, cStartingHuntMinDist - distanceReduction, cStartingHuntMaxDist - 
                              distanceReduction, cStartingObjectAvoidanceMetersOverride);
   }
   else
   {
      addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist - distanceReduction, cStartingHuntMaxDist - 
                              distanceReduction, cStartingObjectAvoidanceMetersOverride);
   }

   // Starting hunt 2.
   int startingHunt2ID = rmObjectDefCreate("starting hunt B");
   rmObjectDefAddItem(startingHunt2ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultFoodAvoidImpassableLand);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(startingHunt2ID, false, 1, cStartingHuntMinDist - distanceReduction, cStartingHuntMaxDist - 
                              distanceReduction, cStartingObjectAvoidanceMetersOverride);
   }
   else
   {
      addObjectLocsPerPlayer(startingHunt2ID, false, 1, cStartingHuntMinDist - distanceReduction, cStartingHuntMaxDist - 
                              distanceReduction, cStartingObjectAvoidanceMetersOverride);
   }

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist - distanceReduction, cStartingChickenMaxDist - 
                           distanceReduction, cStartingObjectAvoidanceMetersOverride);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(4, 5));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist - distanceReduction, cStartingHerdMaxDist  - distanceReduction);

   // TODO: Simlocs for chickens and herds?

   generateLocs("starting food locs");

   // Forest.
   float avoidForestMeters = 24.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(45), rmTilesToAreaFraction(50));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidWater14);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 2, cStartingForestMinDist - distanceReduction, cStartingForestMaxDist - 
                                 distanceReduction, avoidForestMeters + 4.0, cBiasAggressive);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 2, cStartingForestMinDist - distanceReduction, cStartingForestMaxDist - distanceReduction, 
                           avoidForestMeters + 4.0, cBiasAggressive);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 45.0;

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
   addObjectDefPlayerLocConstraint(closeGoldID, 42.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 42.0, 60.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 42.0, 60.0, avoidGoldMeters);
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
   addObjectDefPlayerLocConstraint(bonusGoldID, 45.0);

   // TODO: Simlocs in 1v1?
   addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 45.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeZebra, xsRandInt(7, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(7, 8));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidSocoEdges);
   addObjectDefPlayerLocConstraint(closeHuntID, 40.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 40.0, 60.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 40.0, 60.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeGiraffe, xsRandInt(4, 5));
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeZebra, xsRandInt(0, 2));
      }
      else
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeGazelle, xsRandInt(0, 2));
      }
   }
   else
   {
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeMonkey, xsRandInt(7, 9));  
      }
      else
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeBaboon, xsRandInt(7, 9));  
      }
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, avoidSocoEdges);
   rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(48.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 45.0, 60.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 45.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 1 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(3, 7));
            if(xsRandBool(0.5) == true)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(2, 5));
            }
         }
         else if(largeMapHuntFloat < 2.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeHippopotamus, xsRandInt(1, 3));
         }
         else if(largeMapHuntFloat < 3.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeMonkey, xsRandInt(6, 11));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 7));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 6));
         }
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 50.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 50.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // No berries on this map.
   // The placement can become chaotic.

   // Herdables.
   float avoidHerdMeters = 30.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, mapHerdType, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 45.0);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 45.0, 60.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 48.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 1 * getMapAreaSizeFactor(), 48.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // No predators on this map.

   rmSetProgress(0.7);

   // Relics.
   float avoidRelicMeters = 45.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 50.0);
   addObjectLocsPerPlayer(relicID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   
   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 4 * getMapAreaSizeFactor());

   // Stragglers
   int numStragglers = xsRandInt(4, 5);
   int stragglerType = 0;
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      vector loc = rmGetPlayerLoc(i, 0);

      for(int j = 0; j < numStragglers; j++)
      {
         // Straggler rand.
         int stragglerRand = xsRandInt(0, 2);

         if(stragglerRand == 0)
         {
            stragglerType = cUnitTypeTreePalm;
         }
         else if(stragglerRand == 1)
         {
            if(xsRandBool(0.5) == true)
            {
               stragglerType = cUnitTypeTreeSavannah;
            }
            else
            {
               stragglerType = cUnitTypeTreeSavannahOld;
            }
         }
         else if(stragglerRand == 2)
         {
            stragglerType = cUnitTypeTreeOak;
         }
         int startingStragglerID = rmObjectDefCreate("starting straggler " + i + j);
         rmObjectDefAddItem(startingStragglerID, stragglerType, 1);
         rmObjectDefAddConstraint(startingStragglerID, vDefaultAvoidAll8);
         rmObjectDefPlaceAtLoc(startingStragglerID, 0, loc, cStartingStragglerMinDist, cStartingStragglerMaxDist, 1, true);
      }  
   }
   
   // Fish.
   int fishCount = 14 + (cNumberPlayers * 2) * getMapAreaSizeFactor();

   // Angle Placement.
   float fishAngleOffset = randRadian();

   // Fish radius avoid continent.
   float fishRadius = rmFractionToAreaRadius(continentFraction) + 14.0;

   // Number of fish Layers.   
   int numFishLayers = sqrt(cNumberPlayers * 2);

   for(int i = 0; i < numFishLayers; i++)
   {
      // Locs Placement.
      vector[] fishLocs = placeLocationsInCircle(fishCount, fishRadius, fishAngleOffset, 0.0, 0.0, cCenterLoc, 1.0);

      for(int j = 0; j < fishCount; j++)
      {
         int fishID = rmObjectCreate("fish " + j + "from layer " + i);
         rmObjectAddItem(fishID, cUnitTypeMahi, 1);
         rmObjectPlaceAtLoc(fishID, 0, fishLocs[j]);
      }

      fishRadius += 12.0;

      // Extra Rotation.
      float offset = cPi / fishCount;
      fishAngleOffset += (i % 2 != 0 ? offset : -offset);
   }

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Random tree Savannah.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidWater6);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Random tree Savannah old.
   int randomTreeSavannahOldID = rmObjectDefCreate("random tree old");
   rmObjectDefAddItem(randomTreeSavannahOldID, cUnitTypeTreeSavannahOld, 1);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultAvoidWater6);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeSavannahOldID, 0, 3  * cNumberPlayers * getMapAreaSizeFactor());

   // Random Tree Palm.
   int randomPalmID = rmObjectDefCreate("random palm");
   rmObjectDefAddItem(randomPalmID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomPalmID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomPalmID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomPalmID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomPalmID, vDefaultAvoidWater6);
   rmObjectDefAddConstraint(randomPalmID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(randomPalmID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomPalmID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Random Tree Oak.
   int randomTreeOakID = rmObjectDefCreate("random oak");
   rmObjectDefAddItem(randomTreeOakID, cUnitTypeTreeOak, 1);
   rmObjectDefAddConstraint(randomTreeOakID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeOakID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeOakID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeOakID, vDefaultAvoidWater6);
   rmObjectDefAddConstraint(randomTreeOakID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(randomTreeOakID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeOakID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.

   // Sand & Dirt avoidance.
   int avoidEgyptSand1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand1, 1.0);
   int avoidEgyptSand2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand2, 1.0);
   int avoidEgyptDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt1, 1.0);
   int avoidEgyptDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt2, 1.0);
   int avoidEgyptDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt3, 1.0);
   int avoidEgyptDirtRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirtRocks1, 1.0);
   int avoidEgyptDirtRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirtRocks2, 1.0);

   // Grass avoidance.
   int avoidEgyptGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass1, 1.0);
   int avoidEgyptGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass2, 1.0);
   int avoidEgyptGrassDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt1, 1.0);
   int avoidEgyptGrassDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt2, 1.0);
   int avoidEgyptGrassDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt3, 1.0);
   int avoidEgyptGrassRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassRocks1, 1.0);
   int avoidEgyptGrassRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassRocks2, 1.0);

   // Road avoidance.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 2.0);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad2, 2.0);


   // Plants placement.
   for(int i = 0; i < 5; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 6;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantEgyptianBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantEgyptianShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantEgyptianFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantEgyptianWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantEgyptianGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

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
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptSand1);  
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptSand2);  
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt2);  
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt3);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirtRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirtRocks2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirt1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirt2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptDirt3);
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad1);
      rmObjectDefAddConstraint(plantTypeDef, avoidRoad2);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

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
   rmObjectDefPlaceAnywhere(logID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefPlaceAnywhere(logGroupID, 0, 1 * cNumberPlayers * getMapAreaSizeFactor());

   // Papirus
   int papyrusID = rmObjectDefCreate("Papyrus");
   rmObjectDefAddItem(papyrusID, cUnitTypePapyrus, 1);
   rmObjectDefAddConstraint(papyrusID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int papyrusGroupID = rmObjectDefCreate("Papyrus group");
   rmObjectDefAddItemRange(papyrusGroupID, cUnitTypePapyrus, 3, 5);
   rmObjectDefAddConstraint(papyrusGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusGroupID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusGroupID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefPlaceAnywhere(waterLilyRedGroupID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

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

   // Water plants.
   int waterPlantID = rmObjectDefCreate("water plant shores");
   rmObjectDefAddItem(waterPlantID, cUnitTypeWaterPlant, 1);
   rmObjectDefAddConstraint(waterPlantID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(waterPlantID, rmCreateMaxWaterDepthConstraint(2.6));
   rmObjectDefPlaceAnywhere(waterPlantID, 0, 30 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Water Animals.

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
   rmObjectDefPlaceAnywhere(seaTurtleID, 0, 1 * cNumberPlayers * getMapAreaSizeFactor());

   // Orcas.
   int orcaID = rmObjectDefCreate("orca");
   rmObjectDefAddItem(orcaID, cUnitTypeOrca);
   rmObjectDefAddConstraint(orcaID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(orcaID, vDefaultAvoidLand22);
   rmObjectDefAddConstraint(orcaID, customAvoidEdge18);
   rmObjectDefAddConstraint(orcaID, orcaAvoidOrca);
   rmObjectDefPlaceAnywhere(orcaID, 0, 1 * cNumberPlayers * getMapAreaSizeFactor());

   // Sharks.
   int sharkID = rmObjectDefCreate("shark");
   rmObjectDefAddItem(sharkID, cUnitTypeSharks);
   rmObjectDefAddConstraint(sharkID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(sharkID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sharkID, vDefaultAvoidLand22);
   rmObjectDefAddConstraint(sharkID, customAvoidEdge18);
   rmObjectDefAddConstraint(sharkID, avoidOrca20);
   rmObjectDefAddConstraint(sharkID, sharkAvoidShark);
   rmObjectDefPlaceAnywhere(sharkID, 0, 1 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 1 * cNumberPlayers * getMapAreaSizeFactor());

   // generateTriggers(); Currently disabled.

   rmSetProgress(1.0);
}
