include "lib2/rm_core.xs";

/*
** Haywire
** Author: AL (AoM DE XS CODE)
** Based on "Haywire" by AoE IV DE Team
** Date: December 21, 2025
** Date: March 30, 2026 (Final PB2 revision)
*/

float modGetAngularDeltaAroundLoc(vector locA = cInvalidVector, vector locB = cInvalidVector, vector referenceLoc = cCenterLoc)
{
   vector locADir = locA - referenceLoc;
   float angleA = atan2(locADir.z, locADir.x);

   vector locBDir = locB - referenceLoc;
   float angleB = atan2(locBDir.z, locBDir.x);

   return makeAngleBetweenZeroAndTwoPi(angleB - angleA);
}

float modGetFractionOfAngularDelta(vector locA = cInvalidVector, vector locB = cInvalidVector, vector referenceLoc = cCenterLoc, 
                                float fraction = 0.5)
{
   fraction = clamp(fraction, 0.0, 1.0);

   float delta = modGetAngularDeltaAroundLoc(locA, locB, referenceLoc);
   return makeAngleBetweenZeroAndTwoPi(delta * fraction);
}

vector modGetAngularInterpolatedLoc(vector locA = cInvalidVector, vector locB = cInvalidVector, vector referenceLoc = cCenterLoc, 
                           float fraction = 0.5)
{
   fraction = clamp(fraction, 0.0, 1.0);
   
   // TODO: Should we also consider the angle var?
   return xsVectorRotateXZ(locA, modGetFractionOfAngularDelta(locA, locB, referenceLoc, fraction), referenceLoc);
}

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_mediterranean_day_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.2, 8, 0.4);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt3, 3.0);

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
   int mapForestType = cForestGreekMediterraneanLush;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypePig;

   // Map size and terrain init.
   int axisSize = (gameIs1v1() == true) ? 160 : 145;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Map Stuff.
   float outerForestAreaSize = gameIs1v1() ? 0.33 : 0.3;
   float forestWidth = gameIs1v1() ? 24.0 : 27.0;

   // If the map size is larger than standard, increase the forest thickness. Also, reduce the size of the ring a little.
   if(cMapSizeCurrent > cMapSizeStandard)
   {
      forestWidth += (4.0 * getMapSizeBonusFactor());
      outerForestAreaSize *= (0.95 - (0.05 * getMapSizeBonusFactor()));
   }

   // Placement stuff.
   float playerOuterEdgeDistMeters = 33.0 + forestWidth;
   float placementRadiusMeters = rmFractionToAreaRadius(outerForestAreaSize) - playerOuterEdgeDistMeters;
   float placementFraction = smallerMetersToFraction(placementRadiusMeters);

   // Compute the players to obtain their actual placement order.
   int[] computedPlayers = rmComputePlayersForPlacement();

   // Player placement.
   rmSetTeamSpacingModifier(0.9); // A little closeness between players of the same team, after all, the interpolation is now dynamic.
   rmPlacePlayersOnCircle(placementFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Lighting.
   rmSetLighting(cLightingSetRmMediterranean01);

   // Define Classes.
   int centerClassID = rmClassCreate("playable area class");
   int forestClassID = rmClassCreate("forest class");
   int pathClassID = rmClassCreate("path class");

   // Define Classes Constraints.
   int forestAvoidPlayableArea = rmCreateClassDistanceConstraint(centerClassID, 1.0, cClassAreaDistance, "forest vs player area");
   int avoidHaywireForest4 = rmCreateClassDistanceConstraint(forestClassID, 4.0, cClassAreaDistance, "avoid haywire forest 4");
   int avoidHaywireForest6 = rmCreateClassDistanceConstraint(forestClassID, 6.0, cClassAreaDistance, "avoid haywire forest 6");
   int avoidHaywireForest10 = rmCreateClassDistanceConstraint(forestClassID, 10.0, cClassAreaDistance, "avoid haywire forest 10");
   int avoidHaywireForest15 = rmCreateClassDistanceConstraint(forestClassID, 15.0, cClassAreaDistance, "avoid haywire forest 15");
   int avoidHaywireForest25 = rmCreateClassDistanceConstraint(forestClassID, 25.0, cClassAreaDistance, "avoid haywire forest 25");
   int avoidPath = rmCreateClassDistanceConstraint(pathClassID, 1.0, cClassAreaDistance, "predators vs path");
   int forestAvoidance = rmCreateClassDistanceConstraint(forestClassID, 1.0, cClassAreaDistance, "forest vs forest");

   // Define Type Constraints.
   int forestAvoidPlayerLoc = createPlayerLocDistanceConstraint(34.0);

   // Define Overrides.
   vDefaultSettlementAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(10), rmZTilesToFraction(10));

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 2.5, 0.05, 2, 0.5);

   // Outer forest area.
   int outerForestAreaID = rmAreaCreate("outer forest area");
   rmAreaSetLoc(outerForestAreaID, cCenterLoc);
   rmAreaSetSize(outerForestAreaID, outerForestAreaSize);
   rmAreaSetCoherence(outerForestAreaID, 0.15);
   rmAreaSetEdgePerturbDistance(outerForestAreaID, -4.0, 6.0);
   rmAreaSetEdgeSmoothDistance(outerForestAreaID, 8);
   rmAreaAddConstraint(outerForestAreaID, createSymmetricBoxConstraint(smallerMetersToFraction(30.0)));
   rmAreaBuild(outerForestAreaID);

   // Outer area constraints.
   int avoidOuterEdge5 = rmCreateAreaEdgeDistanceConstraint(outerForestAreaID, 5.0);
   int avoidOuterEdge10 = rmCreateAreaEdgeDistanceConstraint(outerForestAreaID, 10.0);
   int avoidOuterEdge15 = rmCreateAreaEdgeDistanceConstraint(outerForestAreaID, 15.0);
   int avoidOuterArea15 = rmCreateAreaDistanceConstraint(outerForestAreaID, 15.0);

   // Inner forest area.
   int innerForestAreaID = rmAreaCreate("inner forest area");
   rmAreaSetParent(innerForestAreaID, outerForestAreaID);
   rmAreaSetLoc(innerForestAreaID, cCenterLoc);
   rmAreaSetSize(innerForestAreaID, 1.0); 
   rmAreaSetCoherence(innerForestAreaID, 0.2);
   rmAreaSetEdgePerturbDistance(innerForestAreaID, -4.0, 6.0);
   rmAreaAddConstraint(innerForestAreaID, rmCreateAreaEdgeDistanceConstraint(outerForestAreaID, forestWidth));
   rmAreaAddToClass(innerForestAreaID, centerClassID);
   rmAreaBuild(innerForestAreaID);

   // Inner area constraints
   int forceToInnerArea = rmCreateAreaConstraint(innerForestAreaID);
   int avoidInnerEdge2 = rmCreateAreaEdgeDistanceConstraint(innerForestAreaID, 2.0);
   int avoidInnerEdge5 = rmCreateAreaEdgeDistanceConstraint(innerForestAreaID, 5.0);
   int avoidInnerEdge10 = rmCreateAreaEdgeDistanceConstraint(innerForestAreaID, 10.0);

   // Path Definition.
   int forestGapPathDefID = rmPathDefCreate("center connection path");

   if(cNumberPlayers <= 4)
   {
      if(cMapSizeCurrent == cMapSizeStandard)
      {
         rmPathDefSetCostNoise(forestGapPathDefID, -1.0, 1.0);
      }
      else
      {
         rmPathDefSetCostNoise(forestGapPathDefID, -1.75, 1.75);
      }
   }

   rmPathDefAddToClass(forestGapPathDefID, pathClassID);

   // Path Area Definition.
   int pathAreaDefID = rmAreaDefCreate("player connection area");
   rmAreaDefSetEdgePerturbDistance(pathAreaDefID, -2.0, 2.0);
   rmAreaDefAddToClass(pathAreaDefID, centerClassID);

   // Connections. (Angles dehardcoded for better maintainability and future reuse if desired)
   // We start idx 0, because we use the array of computed players.
   float interpolatedFraction = gameIs1v1() ? xsRandFloat(0.47, 0.53) : 0.5;

   for(int i = 0; i < cNumberPlayers; i++)
   {
      // Get the ID of the current index and the next one.
      int locAID = computedPlayers[i];
      int locBID = (i < cNumberPlayers - 1) ? computedPlayers[i + 1] : computedPlayers[0]; // If this is the last iteration, back to index 0

      // Get locs based on IDs.
      vector locA = rmGetPlayerLoc(locAID);
      vector locB = rmGetPlayerLoc(locBID);

      // Interpolate the locs using a more angular approach instead of a vector approach.
      vector loc = modGetAngularInterpolatedLoc(locA, locB, cCenterLoc, interpolatedFraction);

      // Get the edgeLoc to make the connection from the center.
      vector edgeLoc = getLocOnEdgeAtAngle(xsVectorAngleAroundY(loc, cCenterLoc));

      // Forest Gap Path.
      int forestGapPathID = rmPathDefCreatePath(forestGapPathDefID);
      rmPathAddWaypoint(forestGapPathID, cCenterLoc);
      rmPathAddWaypoint(forestGapPathID, edgeLoc);
      rmPathBuild(forestGapPathID);

      // We will use areas intentionally, as they will have variation in thickness in each iteration.
      // I could use classDistance with randfloat in the while true loop, but I think in this case this is better.
  
      int forestGapPathAreaID = rmAreaDefCreateArea(pathAreaDefID);
      rmAreaSetPath(forestGapPathAreaID, forestGapPathID, xsRandFloat(28.0, 34.0));

   }

   rmAreaBuildAll();

   // Forest Definition.
   int haywireForestDefID = rmAreaDefCreate("haywire forest def");
   rmAreaDefSetParent(haywireForestDefID, outerForestAreaID);
   rmAreaDefSetForestType(haywireForestDefID, mapForestType);
   rmAreaDefSetSize(haywireForestDefID, 1.0);
   rmAreaDefAddConstraint(haywireForestDefID, forestAvoidance);
   rmAreaDefAddConstraint(haywireForestDefID, forestAvoidPlayableArea);
   rmAreaDefAddConstraint(haywireForestDefID, forestAvoidPlayerLoc);
   rmAreaDefAddToClass(haywireForestDefID, forestClassID);

   // Forest Placement.
   while(true)
   {
      int haywireForestID = rmAreaDefCreateArea(haywireForestDefID);

      if(rmAreaFindOriginLoc(haywireForestID) == false)
      {
         rmAreaSetFailed(haywireForestID);
         break;
      }

      rmAreaBuild(haywireForestID);
   }

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   float distanceReduction = 2.5;

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, avoidHaywireForest6);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(startingTowerID, true, 4, cStartingTowerMinDist - distanceReduction, cStartingTowerMaxDist - 
                              distanceReduction, cStartingTowerAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist - distanceReduction, cStartingTowerMaxDist - 
                              distanceReduction, cStartingTowerAvoidanceMeters);
   }

   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, avoidHaywireForest25);
   rmObjectDefAddConstraint(firstSettlementID, avoidInnerEdge10);
   rmObjectDefAddConstraint(firstSettlementID, avoidOuterEdge10);
   if((cMapSizeCurrent == cMapSizeStandard) && (gameIs1v1()))
   {
      rmObjectDefAddConstraint(firstSettlementID, avoidOuterArea15);
   }
   
   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, avoidHaywireForest25);
   rmObjectDefAddConstraint(secondSettlementID, avoidInnerEdge10);
   rmObjectDefAddConstraint(secondSettlementID, avoidOuterEdge10);
   if((cMapSizeCurrent == cMapSizeStandard) && (gameIs1v1()))
   {
      rmObjectDefAddConstraint(secondSettlementID, avoidOuterArea15);
   }
   
   if(gameIs1v1() == true)
   { 
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 70.0, 135.0, cFarSettlementDist * 1.25, cBiasBackward, cInAreaDefault, 
                                    cLocSideOpposite);
      // TODO: Consider more bias variances.
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 125.0, 170.0, cFarSettlementDist * 1.25, cBiasDeadBehind | 
                                    cBiasVeryAggressive, cInAreaDefault, cLocSideRandom);
   }
   else
   {
      int allyBias = getRandomAllyBias();
      if(cNumberPlayers <= 8)
      {
         addObjectLocsPerPlayer(firstSettlementID, false, 1, 70.0, 135.0, cFarSettlementDist, cBiasBackward | allyBias);
      }
      else
      {
         addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 175.0, cFarSettlementDist, cBiasBackward | allyBias);
      }
         addObjectLocsPerPlayer(secondSettlementID, false, 1, 135.0, -1.0, cFarSettlementDist, cBiasAggressive | allyBias);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, avoidHaywireForest25);
      rmObjectDefAddConstraint(bonusSettlementID, avoidInnerEdge10);
      rmObjectDefAddConstraint(bonusSettlementID, avoidOuterEdge10);
      rmObjectDefAddConstraint(bonusSettlementID, avoidOuterArea15);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 80.0);
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
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   rmObjectDefAddConstraint(startingGoldID, avoidHaywireForest4);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(startingGoldID, false, 1, cStartingGoldMinDist - distanceReduction, cStartingGoldMaxDist - 
                                    distanceReduction, cStartingObjectAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist - distanceReduction, cStartingGoldMaxDist - 
                              distanceReduction, cStartingObjectAvoidanceMeters);
   }

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(5, 7), 2.0);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   rmObjectDefAddConstraint(startingHuntID, avoidHaywireForest4);
   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(startingHuntID, false, 1, cStartingHuntMinDist - distanceReduction, cStartingHuntMaxDist -
                           distanceReduction, cStartingObjectAvoidanceMeters);
   }
   else
   {
      addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist - distanceReduction, cStartingHuntMaxDist -
                           distanceReduction, cStartingObjectAvoidanceMeters);
   }

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 6), 2.0);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, avoidHaywireForest4);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist - distanceReduction, cStartingChickenMaxDist - 
                           distanceReduction, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 7), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, avoidHaywireForest4);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist  - distanceReduction, cStartingBerriesMaxDist - 
                           distanceReduction, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, avoidHaywireForest4);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist - distanceReduction, cStartingHerdMaxDist - 
                           distanceReduction);

   generateLocs("starting food locs");

   // Forests.
   float avoidPlayerForestMeters = 25.0;
   float startingForestMinDist = 15.0;
   float startingForestMaxDist = 30.0;

   int startingForestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(startingForestDefID, rmTilesToAreaFraction(20), rmTilesToAreaFraction(25));
   rmAreaDefSetForestType(startingForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(startingForestDefID, avoidPlayerForestMeters);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultAvoidAll6);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(startingForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddToClass(startingForestDefID, forestClassID);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(startingForestDefID, 3, startingForestMinDist, startingForestMaxDist, avoidPlayerForestMeters + 8.0, 
                                 cBiasAggressive);
   }
   else
   {
      addAreaLocsPerPlayer(startingForestDefID, 3, startingForestMinDist, startingForestMaxDist, avoidPlayerForestMeters + 5.0, 
                              cBiasAggressive);
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
   rmObjectDefAddConstraint(closeGoldID, forceToInnerArea);
   rmObjectDefAddConstraint(closeGoldID, avoidInnerEdge5);
   addObjectDefPlayerLocConstraint(closeGoldID, 45.0);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(closeGoldID, false, 1, 45.0, 65.0, avoidGoldMeters, cBiasAggressive);
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
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidHaywireForest10);
   rmObjectDefAddConstraint(bonusGoldID, avoidOuterEdge5);
   rmObjectDefAddConstraint(bonusGoldID, avoidInnerEdge5); // ↓ Make sure to avoid the closest manually placed gold mine. 
  // rmObjectDefAddConstraint(bonusGoldID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, avoidGoldMeters)); 
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters * 1.4);
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters * 1.4);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(4, 5) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters * 1.10);
   }
   
   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(5, 6), 2.0);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, avoidOuterEdge5);
   rmObjectDefAddConstraint(bonusHuntID, avoidInnerEdge5);
   rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(75.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 75.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 75.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 2.
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2 ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeBoar, xsRandInt(5, 6), 2.0);
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeAurochs, xsRandInt(4, 6), 2.0);
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHunt2ID, avoidOuterEdge5);
   rmObjectDefAddConstraint(bonusHunt2ID, avoidInnerEdge5);
   rmObjectDefAddConstraint(bonusHunt2ID, createTownCenterConstraint(80.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 80.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 3.
   int bonusHunt3ID = rmObjectDefCreate("bonus hunt 3 ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeBoar, xsRandInt(5, 6), 2.0);
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeDeer, xsRandInt(0, 3), 2.0);
   }
   else
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeWaterBuffalo, xsRandInt(4, 6), 2.0);
   }
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHunt3ID, avoidOuterEdge5);
   rmObjectDefAddConstraint(bonusHunt3ID, avoidInnerEdge5);
   rmObjectDefAddConstraint(bonusHunt3ID, createTownCenterConstraint(85.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt3ID, false, 1, 85.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt3ID, false, 1, 85.0, -1.0, avoidHuntMeters);
   }

   // Large / Giant map size hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      float largeHuntFloat = xsRandFloat(0.0, 1.0);
      if(largeHuntFloat < 1.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(5, 6));
      }
      else if(largeHuntFloat < 2.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 3));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 4));
      }
      else if(largeHuntFloat < 3.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeWaterBuffalo, xsRandInt(2, 3));
      }
      else if(largeHuntFloat < 4.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCrownedCrane, xsRandInt(6, 8));
      }
      else if(largeHuntFloat < 5.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(6, 8));
      }
      else if(largeHuntFloat < 6.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeWaterBuffalo, xsRandInt(4, 6));
      }
      else if(largeHuntFloat < 7.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(5, 7));
      }
      else if(largeHuntFloat < 8.0 / 9.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 4));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCrownedCrane, xsRandInt(4, 6));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeWaterBuffalo, xsRandInt(2, 3));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(largeMapHuntID, avoidInnerEdge5);
      rmObjectDefAddConstraint(largeMapHuntID, avoidOuterEdge5);
      rmObjectDefAddConstraint(largeMapHuntID, createTownCenterConstraint(70.0));
      addObjectLocsPerPlayer(largeMapHuntID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(8, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farBerriesID, avoidInnerEdge5);
   rmObjectDefAddConstraint(farBerriesID, avoidOuterEdge5);
   addObjectDefPlayerLocConstraint(farBerriesID, 80.0);
   if(gameIs1v1() == true)
   {
      if(cMapSizeCurrent == cMapSizeStandard)
      {
         addObjectLocsPerPlayer(farBerriesID, false, 2 * getMapSizeBonusFactor(), 80.0, 120.0, avoidBerriesMeters);
      }
      else
      {
         addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 80.0, 135.0, avoidBerriesMeters);
         addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);
      }
   }
   else
   {
      addObjectLocsPerPlayer(farBerriesID, false, 2 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);
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
   rmObjectDefAddConstraint(closeHerdID, avoidInnerEdge2);
   rmObjectDefAddConstraint(closeHerdID, avoidOuterEdge5);
   rmObjectDefAddConstraint(closeHerdID, forceToInnerArea);
   addObjectDefPlayerLocConstraint(closeHerdID, 45.0);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 45.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidInnerEdge5);
   rmObjectDefAddConstraint(bonusHerdID, avoidOuterEdge5);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("far predator ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeLion, 2);
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeCrocodile, 2);
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, avoidInnerEdge5);
   rmObjectDefAddConstraint(predatorID, avoidOuterEdge5);
   rmObjectDefAddConstraint(predatorID, avoidPath); // It's annoying when predators are lurking at the only exit.
   addObjectDefPlayerLocConstraint(predatorID, 75.0);
   addObjectLocsPerPlayer(predatorID, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidPredatorMeters);

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

   // Inner Forest.
   float avoidForestMeters = 25.0;
   int avoidGlobalForestClassID = rmCreateClassDistanceConstraint(forestClassID, avoidForestMeters);

   int innerForestDefID = rmAreaDefCreate("inner forest");
   rmAreaDefSetSizeRange(innerForestDefID, rmTilesToAreaFraction(20), rmTilesToAreaFraction(25));
   rmAreaDefSetParent(innerForestDefID, innerForestAreaID);
   rmAreaDefSetForestType(innerForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(innerForestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(innerForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(innerForestDefID, vDefaultAvoidImpassableLand6);
   rmAreaDefAddConstraint(innerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(innerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(innerForestDefID, avoidGlobalForestClassID);
   rmAreaDefAddConstraint(innerForestDefID, avoidInnerEdge10);
   rmAreaDefAddToClass(innerForestDefID, forestClassID);

   rmAreaDefCreateAndBuildAreas(innerForestDefID, 4 * cNumberPlayers * getMapSizeBonusFactor());

   // Outer Forest.
   float avoidOuterForestMeters = 42.0;

   int outerForestDefID = rmAreaDefCreate("outer forest");
   rmAreaDefSetSizeRange(outerForestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(90));
   rmAreaDefSetForestType(outerForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(outerForestDefID, avoidOuterForestMeters);
   rmAreaDefSetEdgePerturbDistance(outerForestDefID, -4.0, 4.0);
   rmAreaDefSetCoherence(outerForestDefID, -0.25);
   rmAreaDefAddConstraint(outerForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(outerForestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(outerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(outerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(outerForestDefID, avoidGlobalForestClassID);
   rmAreaDefAddConstraint(outerForestDefID, avoidInnerEdge10);
   rmAreaDefAddConstraint(outerForestDefID, avoidOuterEdge15);
   rmAreaDefAddConstraint(outerForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 25.0));
   rmAreaDefAddConstraint(outerForestDefID, avoidHaywireForest15);
   rmAreaDefAddConstraint(outerForestDefID, vDefaultAvoidOwnerPaths, 1.0);

   rmAreaDefAddToClass(outerForestDefID, forestClassID);

   rmAreaDefCreateAndBuildAreas(outerForestDefID, 12 * cNumberPlayers * getMapSizeBonusFactor());

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

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold.

   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekGrassDirt1, cTerrainGreekGrassDirt2, 10.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainGreekGrassDirt1, cTerrainGreekGrassDirt2, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 55 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 55 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad2, 2.5);

   // Random trees placement.
   for(int i = 0; i < 3; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = (i == 0) ? 20 : 8;

      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreeCypress; treeName = "cypress "; break; }
         case 1: { treeTypeID = cUnitTypeTreeOak; treeName = "oak "; break; }
         case 2: { treeTypeID = cUnitTypeTreeOlive; treeName = "olive "; break; }
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
      int plantsDensity= 60;
      int plantsGroupDensity = 12;
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
   rmObjectDefPlaceAnywhere(flowersID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);   
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 12 * cNumberPlayers * getMapAreaSizeFactor());

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
