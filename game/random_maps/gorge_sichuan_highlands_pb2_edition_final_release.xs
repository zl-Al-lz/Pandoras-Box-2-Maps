include "lib2/rm_core.xs";

/*
** Gorge
** Author: AL (AoM DE XS CODE)
** Based on "Gorge" by AoE IV DE Team
** Date: January 4, 2026
** Date: March 30, 2026 (Final PB2 revision)
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_sichuan_highlands_day_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}

vector modSwapVectorAxis(float x = 0.0, float z = 0.0, bool booleanRotation = false)
{
   // Since we cannot make random booleans on constants, we will have to pass an indicator as a parameter.
   return booleanRotation ? vectorXZ(z, x) : vectorXZ(x, z);
}

vector modVectorLerp(vector A = cInvalidVector, vector B = cInvalidVector, float t = 0.0)
{
   return vector(A.x + (B.x - A.x) * t, A.y + (B.y - A.y) * t, A.z + (B.z - A.z) * t);
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrass2, 3.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrass1, 3.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassRocks1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassDirt1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassDirt2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseGrassDirt3, 4.0);

   // Define forests.
   int sichuanHighlandsCustomForestID = rmCustomForestCreate("sichuan highlands forest");
   rmCustomForestSetTerrain(sichuanHighlandsCustomForestID, cTerrainChineseForestGrass1);
   rmCustomForestSetParams(sichuanHighlandsCustomForestID, 1.0, 1.0);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreePine, 1.3);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeChinesePine, 0.4);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeBamboo, 0.3);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeBambooSingle, 0.3);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeOak, 0.35);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeMetasequoia, 0.2);
   rmCustomForestAddTreeType(sichuanHighlandsCustomForestID, cUnitTypeTreeGinkgo, 0.2);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseBush, 0.2);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseWeeds, 0.2);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseFern, 0.3);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypePlantChineseGrass, 0.1);
   rmCustomForestAddUnderbrushType(sichuanHighlandsCustomForestID, cUnitTypeRockChineseTiny, 0.1);

   // Define Default Tree Type.
   float randomDefaultTreeTypeFloat = xsRandFloat(0.0, 1.0);
   int defaultTreeType = 0;
   if(randomDefaultTreeTypeFloat < 1.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreePine;
   }
   else if(randomDefaultTreeTypeFloat < 2.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreeChinesePine;
   }
   else if(randomDefaultTreeTypeFloat < 3.0 / 6.0)
   {
      if(xsRandBool(0.5) == true)
      {
         defaultTreeType = cUnitTypeTreeBamboo;
      }
      else
      {
         defaultTreeType = cUnitTypeTreeBambooSingle;
      }
   }
   else if(randomDefaultTreeTypeFloat < 4.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreeOak;
   }
   else if(randomDefaultTreeTypeFloat < 5.0 / 6.0)
   {
      defaultTreeType = cUnitTypeTreeMetasequoia;
   }
   else
   {
      defaultTreeType = cUnitTypeTreeGinkgo;
   }

   rmSetDefaultTreeType(defaultTreeType);

   // Biome Assets.
   int mapForestType = sichuanHighlandsCustomForestID;
   int mapCliffType = cCliffChineseGrass;
   int mapCliffTerrainType = cTerrainChineseCliff1;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypeCow;

   // Map stuff.
   float ravineWidth = 103.0;
   float hillHeight = 18.0;

   bool swapAxis = xsRandBool(0.5);

   // Map size and terrain init.
   int axisSize = 132;
   int axisTiles = getScaledAxisTiles(axisSize);

   if(cNumberPlayers <= 4)
   {
      rmSetMapSize(axisTiles);
   }
   else
   {
      float axisMultiplier = 0.93 - (0.021 * cNumberPlayers);
      if(swapAxis)
      {
         rmSetMapSize(axisMultiplier * axisTiles, (1.0 / axisMultiplier) * axisTiles);
      }
      else
      {
         rmSetMapSize((1.0 / axisMultiplier) * axisTiles, axisMultiplier * axisTiles);
      }
   }

   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(1.0);

   // Compute the players to obtain their actual placement order.
   int[] computedPlayers = rmComputePlayersForPlacement();

   // Placement Locs.
   vector startLoc = modSwapVectorAxis(0.22, 0.5, swapAxis);
   vector endLoc = modSwapVectorAxis(0.78, 0.5, swapAxis);

   if(!gameIs1v1())
   {
      float distanceInMeters = (cNumberPlayers <= 4) ? 45 : 30;
      float edgeDistance = (swapAxis) ? rmXMetersToFraction(distanceInMeters) : rmZMetersToFraction(distanceInMeters);
      startLoc = modSwapVectorAxis(0.0 + edgeDistance, 0.5, swapAxis);
      endLoc = modSwapVectorAxis(1.0 - edgeDistance, 0.5, swapAxis);
   }

   if(gameIsSandbox())
   {
      rmPlacePlayer(computedPlayers[0], cCenterLoc);
   }
   else
   {
      placePlayersOnLine(startLoc, endLoc);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureChinese);

   // Lighting.
   rmSetLighting(cLightingSetPotgPotg04);

   // Define Classes.
   int hillClassID = rmClassCreate("hill class");
   int forestClassID = rmClassCreate("forest class");
   int goldClassID = rmClassCreate("gold class");
   int berriesClassID = rmClassCreate("berries class");
   
   // Define Classes Constraints.
   int hillAvoidance = rmCreateClassDistanceConstraint(hillClassID, ravineWidth, cClassAreaDistance, "hill vs hill");
   int avoidHillEdges10 = rmCreateClassDistanceConstraint(hillClassID, 10.0, cClassAreaEdgeDistance, "anything vs hill edges 10");
   int avoidHillEdges15 = rmCreateClassDistanceConstraint(hillClassID, 15.0, cClassAreaEdgeDistance, "anything vs hill edges 15");
   int avoidHillEdges20 = rmCreateClassDistanceConstraint(hillClassID, 20.0, cClassAreaEdgeDistance, "anything vs hill edges 20");
   int forceToHills = rmCreateClassMaxDistanceConstraint(hillClassID, 1.0, cClassAreaDistance, "force anything to hill");
   int forestAvoidance = rmCreateClassDistanceConstraint(forestClassID, 15.0, cClassAreaDistance, "forest vs forest");
   int avoidForest10 = rmCreateClassDistanceConstraint(forestClassID, 10.0, cClassAreaDistance, "anything vs foresst 10");

   // Define Type Constraints.
   int goldAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(7), rmZTilesToFraction(7));

   // Define Overrides.
   vDefaultSettlementAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(12), rmZTilesToFraction(12));

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 3.0, 0.05, 2, 0.5);

   // Disable TOB conversion or they might be floating in the air due to blending after painting.
   rmSetTOBConversion(false);

   // Hills.
   for(int i = 0; i < 2; i++)
   {
      int hillID = rmAreaCreate("hill " + i);
      rmAreaSetSize(hillID, 1.0);
      if(i == 0)
      {
         rmAreaSetLoc(hillID, modSwapVectorAxis(0.5, 1.0, swapAxis));
         rmAreaAddInfluenceSegment(hillID, modSwapVectorAxis(0.0, 1.0, swapAxis), vectorXZ(1.0, 1.0));
      }
      else if(i == 1)
      {
         rmAreaSetLoc(hillID, modSwapVectorAxis(0.5, 0.0, swapAxis));
         rmAreaAddInfluenceSegment(hillID, vectorXZ(0.0, 0.0), modSwapVectorAxis(1.0, 0.0, swapAxis));
      }
      rmAreaSetCoherence(hillID, 0.35);
      rmAreaSetCoherenceSquare(hillID, true);
      rmAreaSetHeight(hillID, hillHeight);
      rmAreaSetHeightNoise(hillID, cNoiseFractalSum, 3.0, 0.05, 2, 0.5);
      rmAreaSetHeightNoiseBias(hillID, 1.0);
      rmAreaSetHeightNoiseEdgeFalloffDist(hillID, 5.0);
      rmAreaAddHeightBlend(hillID, cBlendEdge, cFilter5x5Gaussian, 45, 45, false, true);
      rmAreaSetEdgeSmoothDistance(hillID, 15, false);
      rmAreaAddConstraint(hillID, hillAvoidance);
      if(!gameIs1v1() || gameIsSandbox())
      {
         rmAreaAddConstraint(hillID, rmCreateLocDistanceConstraint(cCenterLoc, 70.0));
      }
   
      rmAreaAddToClass(hillID, hillClassID);
   }

   rmAreaBuildAll();

   // Get the locations of the cliffs we will place.
   vector[] cliffLocs = new vector(0, cOriginVector);

   for(int i = 0; i < 2; i++)
   {
      int tempHillID = rmAreaGetID("hill " + i);
      
      rmAddClosestLocConstraint(rmCreateAreaEdgeConstraint(tempHillID));

      vector cliffLoc = rmGetClosestLoc(cCenterLoc, ravineWidth + 30);

      cliffLoc = modSwapVectorAxis(cliffLoc.x, cliffLoc.z, swapAxis);

      // Since I don't fully trust the accuracy of closestLoc, we'll ensure that the alignment axis is definitely 0.5.
      cliffLoc = modSwapVectorAxis(0.5, cliffLoc.z, swapAxis);

      float pushMeters = (swapAxis) ? rmXMetersToFraction(3.0) : rmZMetersToFraction(3.0);
      cliffLoc = cliffLoc.translateXZ(-pushMeters, xsVectorAngleAroundY(cliffLoc, cCenterLoc));

      cliffLocs.add(cliffLoc);

      rmClearClosestLocConstraints();
   }

   // Cliff Definition.
   float cliffSize = rmRadiusToAreaFraction(14.0);

   int cliffDefID = rmAreaDefCreate("pit cliff def");
   rmAreaDefSetMix(cliffDefID, baseMixID);
   rmAreaDefSetAvoidSelfDistance(cliffDefID, 15.0);
   rmAreaDefSetSize(cliffDefID, cliffSize);
   rmAreaDefSetCoherence(cliffDefID, 0.35);
  // rmAreaDefSetCoherenceSquare(cliffDefID, true);
   rmAreaDefSetCliffType(cliffDefID, mapCliffType);
   rmAreaDefSetCliffEmbellishmentDensity(cliffDefID, 0.55);
   rmAreaDefSetCliffSideRadius(cliffDefID, 1, 2);
   rmAreaDefSetEdgeSmoothDistance(cliffDefID, 2);
   rmAreaDefSetHeight(cliffDefID, hillHeight);
   rmAreaDefAddHeightBlend(cliffDefID, cBlendCliffInside, cFilter3x3Gaussian, 0, 1, false);
   rmAreaDefSetEdgePerturbDistance(cliffDefID, 0.0, 4.5);
   int blendIdx = rmAreaDefAddHeightBlend(cliffDefID, cBlendEdge, cFilter5x5Gaussian, 8.0, 8.0, false, true);
   rmAreaDefAddHeightBlendExpansionConstraint(cliffDefID, blendIdx, vDefaultAvoidImpassableLand);

   // Cliff Placement.
   float segmentDistance = 12.0;

   for(int i = 0; i < 2; i++)
   {
      int tempHillID = rmAreaGetID("hill " + i);
      vector tempLoc = cliffLocs[i];

      int cliffID = rmAreaDefCreateArea(cliffDefID, "cliff " + i);
      rmAreaSetLoc(cliffID, tempLoc);

      float segmentMeters = (swapAxis) ? rmXMetersToFraction(segmentDistance) : rmZMetersToFraction(segmentDistance);
      if(i == 0)
      {
         if(swapAxis)
         {
            rmAreaAddInfluenceSegment(cliffID, tempLoc, vectorXZ(tempLoc.x - segmentMeters, tempLoc.z));
         }
         else
         {
            rmAreaAddInfluenceSegment(cliffID, tempLoc, vectorXZ(tempLoc.x, tempLoc.z - segmentMeters));
         } 
      }
      else
      {
         if(swapAxis)
         { 
            rmAreaAddInfluenceSegment(cliffID, tempLoc, vectorXZ(tempLoc.x + segmentMeters, tempLoc.z));
         }
         else
         {
            rmAreaAddInfluenceSegment(cliffID, tempLoc, vectorXZ(tempLoc.x, tempLoc.z + segmentMeters));
         }
      }

      rmAreaAddCliffEdgeConstraint(cliffID, cCliffEdgeInside, rmCreateAreaConstraint(tempHillID));
   }

   rmAreaBuildAll();

   // Gorge Forests.
   int cliffForestDefID = rmAreaDefCreate("cliff forest");
   rmAreaDefSetSizeRange(cliffForestDefID, rmTilesToAreaFraction(10), rmTilesToAreaFraction(17));
   rmAreaDefSetForestType(cliffForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(cliffForestDefID, 10.0);
   rmAreaDefAddConstraint(cliffForestDefID, vDefaultAvoidImpassableLand);
   rmAreaDefAddConstraint(cliffForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(cliffForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(cliffForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 3.0));
   rmAreaDefAddConstraint(cliffForestDefID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 6.0));
   rmAreaDefAddToClass(cliffForestDefID, forestClassID);
   rmAreaDefCreateAndBuildAreas(cliffForestDefID, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Gorge Player Forest.
   int gorgeSpecialForestDefID = rmAreaDefCreate("gorge forests");
   rmAreaDefSetForestType(gorgeSpecialForestDefID, mapForestType);
   rmAreaDefSetCoherence(gorgeSpecialForestDefID, 0.35);
   rmAreaDefSetEdgePerturbDistance(gorgeSpecialForestDefID, -2.0, 2.0, false);
   rmAreaDefSetEdgeSmoothDistance(gorgeSpecialForestDefID, 2, false);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(gorgeSpecialForestDefID, createPlayerLocDistanceConstraint(35.0));
   rmAreaDefAddToClass(gorgeSpecialForestDefID, forestClassID);

   // Forest Placement.
   if(gameIs1v1())
   {
      for(int i = 1; i <= cNumberPlayers; i++)
      {
         if(gameIs1v1())
         {
            vector cornerLoc = (i == 1) ? modSwapVectorAxis(0.0, 0.5, swapAxis) : modSwapVectorAxis(1.0, 0.5, swapAxis);
            int specialForestCornerID = rmAreaDefCreateArea(gorgeSpecialForestDefID);

            rmAreaSetSize(specialForestCornerID, 0.015);
            rmAreaSetLoc(specialForestCornerID, cornerLoc);
            rmAreaBuild(specialForestCornerID);
         }
      }
   }
   else
   {
      for(int i = 0; i < cNumberPlayers - 1; i++)
      {
         vector actualLoc = rmGetPlayerLoc(computedPlayers[i]);
         vector nextLoc = rmGetPlayerLoc(computedPlayers[i + 1]);

         vector lerpLoc = modVectorLerp(actualLoc, nextLoc, 0.5);
         
         int specialForestCornerID = rmAreaDefCreateArea(gorgeSpecialForestDefID);
         rmAreaSetLoc(specialForestCornerID, lerpLoc);
         rmAreaSetSize(specialForestCornerID, rmRadiusToAreaFraction(15));
      }
   }

   rmAreaBuildAll();

   // KotH.
   vector kotHLoc = cCenterLoc;

   if(!gameIs1v1())
   {
      kotHLoc = (xsRandBool(0.5) == true) ? modSwapVectorAxis(0.5, 0.2, swapAxis) : modSwapVectorAxis(0.5, 0.8, swapAxis);
   }

   placeKotHObjects(cUnitTypeShadePredator, kotHLoc);

   // Enable TOB conversion.
   rmSetTOBConversion(true);

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand2);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   bool settleBiasRandom = xsRandBool(0.5);
   for(int i = 0; i < 2; i++)
   {
      int hillAuxID = rmAreaGetID("hill " + i);
      string concatString = rmAreaGetName(hillAuxID);

      int forceToHill = rmCreateAreaConstraint(hillAuxID);
      int avoidHillEdges = rmCreateAreaEdgeDistanceConstraint(hillAuxID, 10.0);

      int settlementID = rmObjectDefCreate("settlement " + " from " + concatString);
      rmObjectDefAddItem(settlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(settlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(settlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(settlementID, forceToHill);
      rmObjectDefAddConstraint(settlementID, avoidHillEdges);  

      if(gameIs1v1())
      {
         if(i == 0)
         {
            if(settleBiasRandom)
            {
               addSimObjectLocsPerPlayerPair(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1, cBiasDefensive);
            }
            else
            {
               addSimObjectLocsPerPlayerPair(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1, cBiasAggressive);
            }
         }
         else if(i == 1)
         {
            if(settleBiasRandom)
            {
               addSimObjectLocsPerPlayerPair(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1, cBiasAggressive);
            }
            else
            {
               addSimObjectLocsPerPlayerPair(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1, cBiasDefensive);
            }
         }
      }
      else
      {
         int allyBias = getRandomAllyBias();
         addObjectLocsPerPlayer(settlementID, false, 1, 80.0, 145.0, cSettlementDist1v1, cBiasNone | allyBias);
      }
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
   rmObjectDefAddToClass(startingGoldID, goldClassID);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeSpottedDeer, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(2, 3));
      rmObjectDefAddItem(startingHuntID, cUnitTypeSpottedDeer, 3);
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
   rmObjectDefAddToClass(startingBerriesID, berriesClassID);
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
   float avoidForestMeters = 28.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(35), rmTilesToAreaFraction(45));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand14);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddToClass(forestDefID, forestClassID);
   rmAreaDefAddOriginConstraint(forestDefID, rmCreateClassDistanceConstraint(forestClassID, 14.0));

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 5.0);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 60.0;

   for(int i = 0; i < 2; i++)
   {
      int hillAuxID = rmAreaGetID("hill " + i);
      string concatString = rmAreaGetName(hillAuxID);

      int forceToHill = rmCreateAreaConstraint(hillAuxID);
      int avoidHillEdges = rmCreateAreaEdgeDistanceConstraint(hillAuxID, 20.0);

      int goldID = rmObjectDefCreate("gold " + " from " + concatString);
      rmObjectDefAddItem(goldID, cUnitTypeMineGoldLarge, 1);
      rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidAll);
      rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidImpassableLand);
      rmObjectDefAddConstraint(goldID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(goldID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(goldID, vDefaultAvoidCorner32);
      rmObjectDefAddConstraint(goldID, forceToHill);
      rmObjectDefAddConstraint(goldID, avoidHillEdges);
      rmObjectDefAddConstraint(goldID, goldAvoidEdge);
      rmObjectDefAddToClass(goldID, goldClassID);
      addObjectDefPlayerLocConstraint(goldID, 55.0);

      if(gameIs1v1())
      {
         addSimObjectLocsPerPlayerPair(goldID, false, 2 * getMapAreaSizeFactor(), 55.0, -1.0, avoidGoldMeters);
      }
      else
      {
         addObjectLocsPerPlayer(goldID, false, 2 * getMapAreaSizeFactor(), 55.0, -1.0, avoidGoldMeters);
      }
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeSpottedDeer, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(3, 5));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 50.0, 80.0, avoidHuntMeters);
   }

   // Hill Hunt.
   int numBonusHunt = 1 * getMapAreaSizeFactor(); // TODO: 2 maybe?

   for(int i = 0; i < 2; i++)
   {
      int hillAuxID = rmAreaGetID("hill " + i);
      string concatString = rmAreaGetName(hillAuxID);

      int forceToHill = rmCreateAreaConstraint(hillAuxID);
      int avoidHillEdges = rmCreateAreaEdgeDistanceConstraint(hillAuxID, 18.0);

      for(int j = 0; j < numBonusHunt; j++)
      {
         float bonusHuntFloat = xsRandFloat(0.0, 1.0);
         int bonusHuntID = rmObjectDefCreate("bonus hunt " + " from " + concatString + " - " + j);
         if(bonusHuntFloat < 0.25)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 4));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(2, 4));
         }
         else if (bonusHuntFloat < 0.45)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(3, 5));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
         }
         else if (bonusHuntFloat < 0.60)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 3));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
         }
         else if (bonusHuntFloat < 0.75)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(4, 6));
         }
         else if (bonusHuntFloat < 0.90)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 7));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 4));
         }
         else
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 5));
            rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(4, 6));
         }
         rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
         rmObjectDefAddConstraint(bonusHuntID, forceToHill);
         rmObjectDefAddConstraint(bonusHuntID, avoidHillEdges);
         rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(75.0));
         if(gameIs1v1() == true)
         {
            addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 70.0, 120.0, avoidHuntMeters);
         }
         else
         {
            addObjectLocsPerPlayer(bonusHuntID, false, 1, 70.0, -1.0, avoidHuntMeters);
         }
      }
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntID < 0.25)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 4));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(2, 4));
      }
      else if(largeMapHuntID < 0.45)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 5));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
      }
      else if(largeMapHuntID < 0.60)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 3));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 5));
      }
      else if(largeMapHuntID < 0.75)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 6));
      }
      else if(largeMapHuntID < 0.90)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGoldenPheasant, xsRandInt(3, 7));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeSpottedDeer, xsRandInt(3, 5));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 6));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 55.0;

   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(8, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farBerriesID, avoidHillEdges20);
   rmObjectDefAddToClass(farBerriesID, berriesClassID);
   addObjectDefPlayerLocConstraint(farBerriesID, 90.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farBerriesID, false, 2 * getMapSizeBonusFactor(), 90.0, 120.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farBerriesID, false, 2 * getMapSizeBonusFactor(), 90.0, -1.0, avoidBerriesMeters);
   }

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, mapHerdType, xsRandInt(2, 3), 4.0);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, 2, 3.0);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   int bonusHerd2ID = rmObjectDefCreate("bonus herd B");
   rmObjectDefAddItem(bonusHerd2ID, mapHerdType, xsRandInt(1, 2), 3.0);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerd2ID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerd2ID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

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
   rmObjectDefAddConstraint(closePredatorID, avoidHillEdges20);
   addObjectDefPlayerLocConstraint(closePredatorID, 75.0);
   addObjectLocsPerPlayer(closePredatorID, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidPredatorMeters);

   int farPredatorID = rmObjectDefCreate("far predator ");
   rmObjectDefAddItem(farPredatorID, cUnitTypeBlackBear, 2);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farPredatorID, avoidHillEdges20);
   addObjectDefPlayerLocConstraint(farPredatorID, 85.0);
   addObjectLocsPerPlayer(farPredatorID, false, 1 * getMapAreaSizeFactor(), 85.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.7);

   // Relics.
   float avoidRelicMeters = 80.0;

   for(int i = 0; i < 2; i++)
   {
      int hillAuxID = rmAreaGetID("hill " + i);
      string concatString = rmAreaGetName(hillAuxID);

      int forceToHill = rmCreateAreaConstraint(hillAuxID);
      int avoidHillEdges = rmCreateAreaEdgeDistanceConstraint(hillAuxID, 5.0);

      int relicID = rmObjectDefCreate("relic " + " from " + concatString);
      rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
      rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
      rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
      rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
      rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(relicID, forceToHill);
      rmObjectDefAddConstraint(relicID, avoidHillEdges);
      addObjectDefPlayerLocConstraint(relicID, 80.0);

      addObjectLocsPerPlayer(relicID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters, cBiasNone, cInAreaNone);
   }
   
   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   float avoidHillForestMeters = 28.0;

   int hillForestDefID = rmAreaDefCreate("gorge global forest");
   rmAreaDefSetSizeRange(hillForestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(75));
   rmAreaDefSetForestType(hillForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(hillForestDefID, avoidHillForestMeters);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddOriginConstraint(hillForestDefID, forestAvoidance);
   rmAreaDefAddConstraint(hillForestDefID, avoidHillEdges10);
   rmAreaDefAddConstraint(hillForestDefID, forceToHills);
   rmAreaDefAddConstraint(hillForestDefID, createPlayerLocDistanceConstraint(45.0));
   rmAreaDefAddOriginConstraint(hillForestDefID, createPlayerLocDistanceConstraint(60.0));
   rmAreaDefAddOriginConstraint(hillForestDefID, avoidHillEdges15);
   rmAreaDefAddToClass(hillForestDefID, forestClassID);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(hillForestDefID, 10 * getMapAreaSizeFactor());

   // Tiny Forest.
   float avoidTinyForestMeters = 25.0;

   int tinyGlobalForestDefID = rmAreaDefCreate("tiny forest");
   rmAreaDefSetSizeRange(tinyGlobalForestDefID, rmTilesToAreaFraction(15), rmTilesToAreaFraction(20));
   rmAreaDefSetForestType(tinyGlobalForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(tinyGlobalForestDefID, avoidTinyForestMeters);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidImpassableLand12);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultForestAvoidTownCenter);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(tinyGlobalForestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(tinyGlobalForestDefID, createPlayerLocDistanceConstraint(47.0)); 
   rmAreaDefAddOriginConstraint(tinyGlobalForestDefID, createPlayerLocDistanceConstraint(65.0));
   rmAreaDefAddToClass(tinyGlobalForestDefID, forestClassID);

   rmAreaDefCreateAndBuildAreas(tinyGlobalForestDefID, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Stragglers
   int numStragglers = xsRandInt(3, 4);
   int stragglerType = 0;
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int playerLocID = vDefaultTeamPlayerLocOrder[i];

      for(int j = 0; j < numStragglers; j++)
      {
         // Straggler case:
         int stragglerCase = xsRandInt(0, 5);
         if(stragglerCase == 0)
         {
            stragglerType = cUnitTypeTreePine;
         }
         else if(stragglerCase == 1)
         {
            stragglerType = cUnitTypeTreeChinesePine;
         }
         else if(stragglerCase == 2)
         {
            stragglerType = cUnitTypeTreeMetasequoia;
         }
         else if(stragglerCase == 3)
         {
            stragglerType = cUnitTypeTreeGinkgo;
         }
         else if(stragglerCase == 4)
         {
            stragglerType = cUnitTypeTreeOak;
         }
         else if(stragglerCase == 5)
         {
            if(xsRandBool(0.5) == true)
            {
               stragglerType = cUnitTypeTreeBamboo;
            }
            else
            {
               stragglerType = cUnitTypeTreeBambooSingle;
            }
         }        
         int startingStragglerID = rmObjectDefCreate("starting straggler" + playerLocID + " " + j);
         rmObjectDefAddItem(startingStragglerID, stragglerType, 1);
         rmObjectDefAddConstraint(startingStragglerID, vDefaultAvoidAll8);
         rmObjectDefPlaceAtLoc(startingStragglerID, 0, rmGetPlayerLocByID(playerLocID), cStartingStragglerMinDist,
                              cStartingStragglerMaxDist, 1, true);
      }  
   }

   rmSetProgress(0.9);  

   // Embellishment.

   // Embellishment areas.
   int beautificationDefID = rmAreaDefCreate("beautification area");
   rmAreaDefSetSizeRange(beautificationDefID, rmTilesToAreaFraction(120), rmTilesToAreaFraction(160));
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseGrassDirt2, 0);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseGrassDirt3, 1);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainChineseDirtRocks1, 2);
   rmAreaDefSetTerrainType(beautificationDefID, cTerrainChineseDirtRocks2);
   rmAreaDefAddConstraint(beautificationDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddConstraint(beautificationDefID, vDefaultAvoidAll4);
   rmAreaDefAddConstraint(beautificationDefID, avoidForest10);
   rmAreaDefSetAvoidSelfDistance(beautificationDefID, 45.0);
   rmAreaDefCreateAndBuildAreas(beautificationDefID, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Areas under forests.
   int forestSurroundAreaDefID = rmAreaDefCreate("forest surround");
   rmAreaDefSetSize(forestSurroundAreaDefID, 1.0);
   rmAreaDefSetTerrainType(forestSurroundAreaDefID, cTerrainChineseGrass1);
   rmAreaDefAddTerrainLayer(forestSurroundAreaDefID, cTerrainChineseGrassDirt1, 0);
   rmAreaDefAddConstraint(forestSurroundAreaDefID, vDefaultAvoidImpassableLand8);

   // Let extensive grasses surround the forests.
   int[] allForestIDs = rmClassGetAreas(forestClassID);
   int numForestAreas = allForestIDs.size();

   for(int i = 0; i < numForestAreas; i++)
   {
      int forestID = allForestIDs[i];

      vector forestLoc = rmAreaGetLoc(forestID);
      if(forestLoc == cInvalidVector)
      {
         continue;
      }

      int forestSurroundID = rmAreaDefCreateArea(forestSurroundAreaDefID);
      rmAreaSetLoc(forestSurroundID, forestLoc);
      rmAreaAddConstraint(forestSurroundID, rmCreateAreaMaxDistanceConstraint(forestID, 6.0));
      rmAreaAddTerrainConstraint(forestSurroundID, rmCreateAreaDistanceConstraint(forestID, 1.0));
      rmAreaBuild(forestSurroundID);
   }

   // Gold areas.
   // TODO: Apply the custom functions coded: rmIsLocInsideAreaTiles and rmGenerateAreasForClass to scan terrains generated by custom mix.
   // For now, it will be completely random.

   int[] goldMineIDs = rmClassGetObjects(goldClassID);
   int numTotalGoldMines = goldMineIDs.size();
   float goldDirtAreaSize = rmRadiusToAreaFraction(13);
   float goldGrassAreaSize = rmRadiusToAreaFraction(11);

   for(int i = 0; i < numTotalGoldMines; i++)
   {
      int goldID = goldMineIDs[i];

      int goldAreaID = rmAreaCreate("gold area" + i);
      rmAreaSetLoc(goldAreaID, rmObjectGetLoc(goldID));
      if(xsRandBool(0.5) == true)
      {
         rmAreaSetSize(goldAreaID, goldDirtAreaSize);
         rmAreaAddTerrainLayer(goldAreaID, cTerrainChineseGrassDirt2, 0);
         rmAreaAddTerrainLayer(goldAreaID, cTerrainChineseGrassDirt3, 1);
         rmAreaAddTerrainLayer(goldAreaID, cTerrainChineseDirtRocks1, 2);
         rmAreaSetTerrainType(goldAreaID, cTerrainChineseDirtRocks2);
      }
      else
      {
         rmAreaSetSize(goldAreaID, goldGrassAreaSize);
         rmAreaAddTerrainLayer(goldAreaID, cTerrainChineseGrassDirt1, 0);
         rmAreaAddTerrainLayer(goldAreaID, cTerrainChineseGrassRocks1, 1);
         rmAreaSetTerrainType(goldAreaID, cTerrainChineseGrassRocks2);
      }
      rmAreaAddConstraint(goldAreaID, vDefaultAvoidImpassableLand4);
      rmAreaAddConstraint(goldAreaID, vDefaultAvoidWater2);
   }

   rmAreaBuildAll();

   // Berries areas.
   int[] berriesIDs = rmClassGetObjects(berriesClassID);
   int numTotalBerries = berriesIDs.size();

   float berriesDirtAreaSize = rmRadiusToAreaFraction(12);
   float berriesGrassAreaSize = rmRadiusToAreaFraction(13);

   for(int i = 0; i < numTotalBerries; i++)
   {
      int berriesID = berriesIDs[i];

      int berriesAreaID = rmAreaCreate("berries area" + i);
      rmAreaSetLoc(berriesAreaID, rmObjectGetLoc(berriesID));
      if(xsRandBool(0.5) == true)
      {
         rmAreaSetSize(berriesAreaID, berriesDirtAreaSize);
         rmAreaAddTerrainLayer(berriesAreaID, cTerrainChineseGrassDirt3, 0);
         rmAreaAddTerrainLayer(berriesAreaID, cTerrainChineseGrassDirt2, 1);
         rmAreaSetTerrainType(berriesAreaID, cTerrainChineseGrassDirt1);
      }
      else
      {
         rmAreaSetSize(berriesAreaID, berriesGrassAreaSize);
         rmAreaAddTerrainLayer(berriesAreaID, cTerrainChineseGrassDirt1, 0);
         rmAreaAddTerrainLayer(berriesAreaID, cTerrainChineseGrass1, 1);
         rmAreaSetTerrainType(berriesAreaID, cTerrainChineseGrass2);
      }
      rmAreaAddConstraint(berriesAreaID, vDefaultAvoidImpassableLand4);
      rmAreaAddConstraint(berriesAreaID, vDefaultAvoidWater2);
   }

   rmAreaBuildAll();

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockChineseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 55 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockChineseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 55 * cNumberPlayers * getMapAreaSizeFactor());

   int rockMediumID = rmObjectDefCreate("rock medium");
   rmObjectDefAddItem(rockMediumID, cUnitTypeRockChineseMedium, 1);
   rmObjectDefAddConstraint(rockMediumID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockMediumID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 3.0));
   rmObjectDefPlaceAnywhere(rockMediumID, 0, 2);

   int rockLargeID = rmObjectDefCreate("rock large");
   rmObjectDefAddItem(rockLargeID, cUnitTypeRockChineseLarge, 1);
   rmObjectDefAddConstraint(rockLargeID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockLargeID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 2.0));
   rmObjectDefPlaceAnywhere(rockLargeID, 0, 3);

   // Columns
   int columnsBrokenID = rmObjectDefCreate("columns broken");
   rmObjectDefAddItem(columnsBrokenID, cUnitTypeColumnsBroken, 1);
   rmObjectDefAddConstraint(columnsBrokenID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(columnsBrokenID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 2.0));
   rmObjectDefPlaceAnywhere(columnsBrokenID, 0, 3);

   int columnsID = rmObjectDefCreate("columns");
   rmObjectDefAddItem(columnsID, cUnitTypeColumns, 1);
   rmObjectDefAddConstraint(columnsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(columnsID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 2.0));
   rmObjectDefPlaceAnywhere(columnsID, 0, 3);
   
   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseRoad2, 2.5);

   int avoidChineseDirtRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseDirtRocks1, 2.5);
   int avoidChineseDirtRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainChineseDirtRocks2, 2.5);

   // Random trees placement.
   for(int i = 0; i < 7; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = 28 / 7;

      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreePine; treeName = "pine "; break; }
         case 1: { treeTypeID = cUnitTypeTreeChinesePine; treeName = "chinese pine "; break; }
         case 2: { treeTypeID = cUnitTypeTreeMetasequoia; treeName = "metasequoia "; break; }
         case 3: { treeTypeID = cUnitTypeTreeGinkgo; treeName = "ginkgo "; break; }
         case 4: { treeTypeID = cUnitTypeTreeOak; treeName = "oak  "; break; }
         case 5: { treeTypeID = cUnitTypeTreeBamboo; treeName = "bamboo  ";  treeDensity *= 0.5; break; }
         case 6: { treeTypeID = cUnitTypeTreeBambooSingle; treeName = "bamboo single ";  treeDensity *= 0.5; break; }
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
      rmObjectDefAddConstraint(treeDefID, avoidChineseDirtRocks1);
      rmObjectDefAddConstraint(treeDefID, avoidChineseDirtRocks2);
      rmObjectDefPlaceAnywhere(treeDefID, 0, treeDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 45;
      int plantsGroupDensity = 10;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantChineseBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantChineseShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantChineseFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantChineseWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantChineseGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantChineseFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantChineseWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidChineseDirtRocks1);
      rmObjectDefAddConstraint(plantTypeDef, avoidChineseDirtRocks2);
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
   rmObjectDefAddConstraint(flowersID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(flowersID, avoidChineseDirtRocks2);
   rmObjectDefPlaceAnywhere(flowersID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);   
   rmObjectDefAddConstraint(flowersGroupID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(flowersGroupID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Meadow Flowers.
   int meadowFlowersID = rmObjectDefCreate("meadow flowers");
   rmObjectDefAddItemRange(meadowFlowersID, cUnitTypeMeadowFlower, 1);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(meadowFlowersID, avoidRoad1);
   rmObjectDefAddConstraint(meadowFlowersID, avoidRoad2);
   rmObjectDefAddConstraint(meadowFlowersID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(meadowFlowersID, avoidChineseDirtRocks2);
   rmObjectDefPlaceAnywhere(meadowFlowersID, 0, 150 * cNumberPlayers * getMapAreaSizeFactor());

   // Meadow Flowers Group.        
   int meadowFlowersGroupID = rmObjectDefCreate("Meadow flowers group");
   rmObjectDefAddItemRange(meadowFlowersGroupID, cUnitTypeMeadowFlower, 5, 8, 0.0, 0.5);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidRoad2);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidChineseDirtRocks1);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidChineseDirtRocks2);
   rmObjectDefAddConstraint(meadowFlowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(meadowFlowersGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

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

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeEagle, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Lighting Override.
   lightingOverride();

   rmSetProgress(1.0);
}
