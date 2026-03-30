include "lib2/rm_core.xs";

/*
** Prairie
** Author: AL (AoM DE XS CODE)
** Based on "Prairie" by AoE IV Team
** Date: January 12, 2025 (Reworked version)
** Final revision: March 30, 2026
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_egyptian_beach_day_02_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.10, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 0.7);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 0.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt3, 1.0);

   // Define forests.
   int egyptianBeachCustomForestID = rmCustomForestCreate("egyptian beach custom forest");
   rmCustomForestSetTerrain(egyptianBeachCustomForestID, cTerrainEgyptForestPalmDirt);
   rmCustomForestSetParams(egyptianBeachCustomForestID, 1.0, 1.0);
   rmCustomForestAddTreeType(egyptianBeachCustomForestID, cUnitTypeTreePalm, 1.0);
   rmCustomForestAddUnderbrushType(egyptianBeachCustomForestID, cUnitTypePlantEgyptianFern, 0.2);
   rmCustomForestAddUnderbrushType(egyptianBeachCustomForestID, cUnitTypePlantEgyptianBush, 0.2);
   rmCustomForestAddUnderbrushType(egyptianBeachCustomForestID, cUnitTypePlantEgyptianWeeds, 0.2);
   rmCustomForestAddUnderbrushType(egyptianBeachCustomForestID, cUnitTypePlantEgyptianGrass, 0.1);
   rmCustomForestAddUnderbrushType(egyptianBeachCustomForestID, cUnitTypeWaterPlant, 0.1);

   // Define Default Tree Type.
   rmSetDefaultTreeType(cUnitTypeTreePalm);

   // Biome Assets.
   int mapForestType = egyptianBeachCustomForestID;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = cUnitTypeGoat;

   // Make sure that settlements and gold mines share the same type of side.
   int sharedSide = cLocSideRandom;

   // Map size and terrain init.
   int axisSize = 128;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.7, 0.8));
   rmPlacePlayersOnCircle(0.33);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetBgGreek01);

   // Define Classes.

   // Define classes constraints.

   // Define type constraints.
   int goldAvoidEdge  = createSymmetricBoxConstraint(rmXTilesToFraction(10), rmZTilesToFraction(10));

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 16.0, 0.05, 2, 0.5);

   // Player base areas.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerBaseAreaID = rmAreaCreate("player base area " + p);
      rmAreaSetLocPlayer(playerBaseAreaID, p);
      rmAreaSetSize(playerBaseAreaID, rmRadiusToAreaFraction(32.0));
      rmAreaSetHeightNoise(playerBaseAreaID, cNoiseFractalSum, 4.0, 0.05, 2, 0.5);
      rmAreaSetHeightNoiseEdgeFalloffDist(playerBaseAreaID, 5.0);
      rmAreaSetHeightNoiseBias(playerBaseAreaID, 1.0);
      rmAreaSetCoherence(playerBaseAreaID, 0.25);
      rmAreaSetEdgeSmoothDistance(playerBaseAreaID, 3);
      rmAreaSetHeight(playerBaseAreaID, 8.0);
      rmAreaAddHeightBlend(playerBaseAreaID, cBlendEdge, cFilter5x5Gaussian, 5, 5);
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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidKotH);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 65.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, sharedSide);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 85.0, 120.0, cSettlementDist1v1, cBiasAggressive); // No share side here.
   }
   else
   {
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 85.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 90.0, 135.0, cFarSettlementDist, cBiasAggressive | allyBias);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard){
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1); 
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   // Generate the locs, but don't place yet if we succeed.
   bool settlementLocsGenerated = generateLocs("settlement locs", true, false, true, false);

   for(int i = 0; i < rmLocGenGetNumberLocs(); i++)
   {
      vector loc = rmLocGenGetLoc(i);
   
      int areaSettlementID = rmAreaCreate("settlement " + i); 
      rmAreaSetSize(areaSettlementID, rmRadiusToAreaFraction(20.0));
      rmAreaSetLoc(areaSettlementID, loc);
      rmAreaSetHeightNoise(areaSettlementID, cNoiseFractalSum, 4.0, 0.05, 2, 0.5);
      rmAreaSetHeightNoiseEdgeFalloffDist(areaSettlementID, 5.0);
      rmAreaSetHeightNoiseBias(areaSettlementID, 1.0);
      rmAreaSetCoherence(areaSettlementID, 0.25);
      rmAreaSetEdgeSmoothDistance(areaSettlementID, 3);
      rmAreaSetHeight(areaSettlementID, 8.0);
      rmAreaAddHeightBlend(areaSettlementID, cBlendEdge, cFilter5x5Gaussian, 5, 5);
      rmAreaAddConstraint(areaSettlementID, vDefaultAvoidKotH);
      rmAreaBuild(areaSettlementID);  
   }

   // Actually place stuff.
   if(settlementLocsGenerated)
   {
      applyGeneratedLocs();
   }

   resetLocGen();

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
                                    cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasAggressive);
   }
   
   // Starting gold small.
   int startingGoldSmallID = rmObjectDefCreate("starting gold small");
   rmObjectDefAddItem(startingGoldSmallID, cUnitTypeMineGoldSmall, 1);
   rmObjectDefAddConstraint(startingGoldSmallID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldSmallID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldSmallID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldSmallID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldSmallID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldSmallID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldSmallID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, 
                           cBiasNotAggressive); // No simlocs on this one.

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(3, 4), 2.0);
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(3, 4), 2.0);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGiraffe, xsRandInt(5, 6), 2.0);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(4, 6), 2.0);
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
   float avoidForestMeters = 26.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(17), rmTilesToAreaFraction(25));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 5, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 5, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 60.0;

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
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.

   // To differentiate the mines from how they are in Dry Arabia, we will make a few details.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, goldAvoidEdge); // A little more distance over the edge of the map.
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner24); // More permissive towards the corners of the map.
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1())
   {
      // The bonus gold mines will be placed in a sort of semi-mirror, but with a slightly different angle and radius than 
      // those set by default in simLocs; I don't want it to be too repetitive scenario-like, but also not too unfair.

      // A slightly more aggressive variance compared to Dry Arabia.
      float bonusGoldSimLocsRadiusVar = vSimLocDefaultRadiusVar * 1.35;
      float bonusGoldSimLocsAngleVar = vSimLocDefaultAngleVar * 1.4; 
      // I prioritize much more angular variety over radial variation; this is intentional.

      // Generate the locs in mirror.
      int[] locGenBonusGoldLocs = addMirroredLocsPerPlayerPair(xsRandInt(3, 4) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters, 
                                                               cBiasNone, cInAreaDefault, sharedSide);

      // Apply established radial and angular variation.
      setLocsRadiusVariance(locGenBonusGoldLocs, bonusGoldSimLocsRadiusVar);
      setLocsAngleVariance(locGenBonusGoldLocs, bonusGoldSimLocsAngleVar);

      // Place the objects in the locs.
      setLocsObject(locGenBonusGoldLocs, bonusGoldID, false);

   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeZebra, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(5, 6));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 55.0, 75.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, 75.0, avoidHuntMeters);
   }

   // Far hunt.
   int farHuntID = rmObjectDefCreate("far hunt");
   rmObjectDefAddItem(farHuntID, cUnitTypeGiraffe, xsRandInt(4, 5));
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(farHuntID, createTownCenterConstraint(75.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 75.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 75.0, 120.0, avoidHuntMeters);
   }

   // Bonus hunt.
   float bonusHuntFloat = xsRandFloat(0.0, 1.0);

   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(bonusHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElephant, 2);
   }
   else if(bonusHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeRhinoceros, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeHippopotamus, xsRandInt(2, 3));
   }
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

   // Bonus hunt 2.
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt b");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeZebra, xsRandInt(6, 7));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGazelle, xsRandInt(6, 7));
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidKotH);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 90.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 90.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 90.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      // It's intentional that the entire quantity is handled here for more iterations = more variety.
      int numLargeHunt = 1 * getMapAreaSizeFactor(); 
      
      for(int i = 0; i < numLargeHunt; i++)
      {
         bool isAgressive = xsRandBool(0.65);
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);

         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(isAgressive)
         {
            if(largeMapHuntFloat < 1.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(2, 3));
            }
            else if(largeMapHuntFloat < 2.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeHippopotamus, xsRandInt(2, 3));
            }
            else if(largeMapHuntFloat < 3.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 3));
            }
            else if(largeMapHuntFloat < 4.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, 2);
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, 1);
            }
            else
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, 1);
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeHippopotamus, 2);
            }
         }
         else
         {
            if(largeMapHuntFloat < 1.0 / 6.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(5, 6));
            }
            else if(largeMapHuntFloat < 2.0 / 6.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(5, 6));
            }
            else if(largeMapHuntFloat < 3.0 / 6.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(4, 5));
            }
            else if(largeMapHuntFloat < 4.0 / 6.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 5));
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 5));
            }
            else if(largeMapHuntFloat < 5.0 / 6.0)
            {
               if(xsRandBool(0.5) == true)
               {
                  rmObjectDefAddItem(largeMapHuntID, cUnitTypeMonkey, xsRandInt(9, 11));
               }
               else
               {
                  rmObjectDefAddItem(largeMapHuntID, cUnitTypeBaboon, xsRandInt(9, 11));
               }
            }
            else
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(2, 3));
               if(xsRandBool(0.5) == true)
               {
                  rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 4));
               }
               else
               {
                  rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 4));
               }
            }
         }
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidKotH);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }

   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 55.0;

   int closeBerriesID = rmObjectDefCreate("close berries");
   rmObjectDefAddItem(closeBerriesID, cUnitTypeBerryBush, xsRandInt(5, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeBerriesID, 60.0);
   addObjectLocsPerPlayer(closeBerriesID, false, 1 * getMapSizeBonusFactor(), 60.0, 80.0, avoidBerriesMeters);

   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(8, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerriesID, 90.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 90.0, 120.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 90.0, -1.0, avoidBerriesMeters);
   }

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
   rmObjectDefAddItem(closePredatorID, cUnitTypeHyena, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closePredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closePredatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closePredatorID, 70.0);
   addObjectLocsPerPlayer(closePredatorID, false, 1 * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   int farPredatorID = rmObjectDefCreate("far predator ");
   rmObjectDefAddItem(farPredatorID, cUnitTypeLion, 2);
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

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(47.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));

   rmAreaDefCreateAndBuildAreas(forestDefID, 22 * cNumberPlayers * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm, 3, 4);

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(startingGoldSmallID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);
   buildAreaUnderObjectDef(closeBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad2, 2.5);

   // Random tree palm.
   int randomTreePalmID = rmObjectDefCreate("random tree palm");
   rmObjectDefAddItem(randomTreePalmID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePalmID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePalmID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreePalmID, avoidRoad2);
   rmObjectDefPlaceAnywhere(randomTreePalmID, 0, 18 * cNumberPlayers * getMapAreaSizeFactor());


   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 25;
      int plantsGroupDensity = 4;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantEgyptianBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantEgyptianShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantEgyptianFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantEgyptianWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantEgyptianGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantEgyptianFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantEgyptianWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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

   // Generic Bush.
   int genericBushID = rmObjectDefCreate("generic bush");
   rmObjectDefAddItem(genericBushID, cUnitTypeBush, 1);
   rmObjectDefAddConstraint(genericBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(genericBushID, vDefaultAvoidImpassableLand2);
   rmObjectDefAddConstraint(genericBushID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(genericBushID, avoidRoad1);
   rmObjectDefAddConstraint(genericBushID, avoidRoad2);
   rmObjectDefPlaceAnywhere(genericBushID, 0, 22 * cNumberPlayers * getMapAreaSizeFactor());

   // Generic Bush Group.
   int genericBushGroupID = rmObjectDefCreate("generic bush group");
   rmObjectDefAddItemRange(genericBushGroupID, cUnitTypeBush, 2, 6, 0.5, 1.5);
   rmObjectDefAddConstraint(genericBushGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(genericBushGroupID, vDefaultAvoidImpassableLand2);
   rmObjectDefAddConstraint(genericBushGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(genericBushGroupID, avoidRoad1);
   rmObjectDefAddConstraint(genericBushGroupID, avoidRoad2);
   rmObjectDefPlaceAnywhere(genericBushGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

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

   // Sand VFX.
   int sandDriftPlainID = rmObjectDefCreate("sand drift plain");
   rmObjectDefAddItem(sandDriftPlainID, cUnitTypeVFXSandDriftPlain, 1);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidAll6);
   rmObjectDefAddConstraint(sandDriftPlainID, rmCreateTypeDistanceConstraint(cUnitTypeVFXSandDriftPlain, 45.0));
   rmObjectDefAddConstraint(sandDriftPlainID, rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 15.0));
   rmObjectDefPlaceAnywhere(sandDriftPlainID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Lighting Override.
   // lightingOverride();

   rmSetProgress(1.0);
}
