include "lib2/rm_core.xs";

/*
** King of the Hill
** Author: AL (AoM DE XS CODE)
** Based on "King of the Hill map" by AoE IV Team
** Date: January 12, 2025 (Reworked version)
** Final revision: March 30, 2026
*/

vector[] buildRampPathsByClass(int numRamps = 0, float rampPathAngle = 0.0, float pathMinCostNoise = 0, float pathMaxCostNoise = 0, 
                     int pathClassID = cInvalidID)
{
   float rampPathStepness = cTwoPi / numRamps;
   vector[] edgeLocs = new vector(0, cInvalidVector);

   // TODO: No rmClassGetName?
   for(int i = 0; i < numRamps; i++)
   {
      vector edgeLoc = getLocOnEdgeAtAngle(rampPathAngle);
      int lowerRampPathID = rmPathCreate(); // + Class name maybe?
      rmPathAddWaypoint(lowerRampPathID, cCenterLoc);
      rmPathAddWaypoint(lowerRampPathID, edgeLoc);
      rmPathSetCostNoise(lowerRampPathID, pathMinCostNoise, pathMaxCostNoise);
      rmPathAddToClass(lowerRampPathID, pathClassID);
      rmPathBuild(lowerRampPathID);

      rampPathAngle += rampPathStepness;

      // Normalize the angle.
      makeAngleBetweenZeroAndTwoPi(rampPathAngle);
      edgeLocs.add(edgeLoc);
   }

   return edgeLocs;
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.3, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt2, 1.0);

   // Define Default Tree Type.
   rmSetDefaultTreeType((xsRandBool(0.5) == true) ? cUnitTypeTreeOak : cUnitTypeTreePine);

   // Biome Assets.
   int mapForestType = cForestNorseOak;
   int mapCliffType = cCliffNorseGrass;
   int mapCliffTerrainType = cTerrainNorseCliff1;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypeCow;

   // Map size and terrain init.
   int axisSize = (cNumberPlayers <= 3) ? 155 : 145;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.75, 0.8));

   // Map Stuff.
   float kothSize = 0.165;
   float placementAngle = randRadian();
   float playerKothEdgeDistMeters = 55.0;
   float placementRadiusMeters = rmFractionToAreaRadius(kothSize) + playerKothEdgeDistMeters;
   float placementFraction = smallerMetersToFraction(placementRadiusMeters);

   if(gameIs1v1() && (cMapSizeCurrent == cMapSizeStandard))
   {
      // Overrides.
      placementAngle = xsRandBool(0.5) ? cPiOver4 : cPiOver4 - c3PiOver2;
   }

   rmPlacePlayersOnCircle(placementFraction, 0.0, 0.0, placementAngle);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetFott26);

   // Define Classes.
   int forestClassID = rmClassCreate("forest class");
   int hillClassID = rmClassCreate("hill class");
   int lowerRampsPathClassID = rmClassCreate("lower ramp class");
   int upperRampsPathClassID = rmClassCreate("upper ramp class");

   // Define Classes Constraints.
   int avoidEdgeForest7 = rmCreateClassDistanceConstraint(forestClassID, 7.0, cClassAreaDistance, "anything vs forest class in 7 meters");
   int avoidEdgeForest10 = rmCreateClassDistanceConstraint(forestClassID, 10.0, cClassAreaDistance, "anything vs forest class in 10 meters");

   // These values ​​define the width of the ramps.                                         ↓
   int forceLowerRampsOnPath = rmCreateClassMaxDistanceConstraint(lowerRampsPathClassID, 11.0, cClassAreaDistance, "force ramps to lower path");
   int forceUpperRampsOnPath = rmCreateClassMaxDistanceConstraint(upperRampsPathClassID, 8.0, cClassAreaDistance, "force ramps to upper path");

   int avoidRamps15 = rmCreateClassDistanceConstraint(hillClassID, 15.0, cClassAreaCliffRampDistance, "anything vs ramps in 15 meters");

   int avoidHill15 = rmCreateClassDistanceConstraint(hillClassID, 15.0, cClassAreaDistance, "anything vs hill in 15 meters");
   int forceToHills = rmCreateClassMaxDistanceConstraint(hillClassID, 0.1, cClassAreaDistance, "force anything to hills");

   // Define Type Constraints.
   int avoidStatue = rmCreateTypeDistanceConstraint(cUnitTypeStatueMajorGod, 5.0, true, "forest vs statue major god");
   int avoidTorch = rmCreateTypeDistanceConstraint(cUnitTypeTorch, 5.0, true, "forest vs torch");

   // Define Overrides.

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 3.0, 0.05, 2, 0.5);

   // Edge Forests.
   int edgeForestDefID = rmAreaDefCreate("edge forest");
   rmAreaDefSetSize(edgeForestDefID, 0.06);
   rmAreaDefSetForestType(edgeForestDefID, mapForestType);
  // rmAreaDefSetForestTreeDensity(edgeForestDefID, 0.80);
   rmAreaDefAddToClass(edgeForestDefID, forestClassID);
   for(int i = 0; i < 4; i++)
   {
      int edgeForestID = rmAreaDefCreateArea(edgeForestDefID);
      if(i == 0)
      {
         rmAreaSetLoc(edgeForestID, vectorXZ(0.5, 0.0));
         rmAreaAddInfluenceSegment(edgeForestID, vectorXZ(0.0, 0.0), vectorXZ(1.0, 0.0));
      }
      else if(i == 1)
      {
         rmAreaSetLoc(edgeForestID, vectorXZ(0.5, 1.0));
         rmAreaAddInfluenceSegment(edgeForestID, vectorXZ(0.0, 1.0), vectorXZ(1.0, 1.0));
      }
      else if(i == 2)
      {
         rmAreaSetLoc(edgeForestID, vectorXZ(0.0, 0.5));
         rmAreaAddInfluenceSegment(edgeForestID, vectorXZ(0.0, 0.0), vectorXZ(0.0, 1.0));
      }
      else if(i == 3)
      {
         rmAreaSetLoc(edgeForestID, vectorXZ(1.0, 0.5)); 
         rmAreaAddInfluenceSegment(edgeForestID, vectorXZ(1.0, 0.0), vectorXZ(1.0, 1.0));
      }
   }
   
   rmAreaBuildAll();

   // Define the number of ramps.
   int numLowerRamps = 3 * sqrt(cNumberPlayers * 2);
   int numUpperRamps = 2 * sqrt(cNumberPlayers * 2);

   buildRampPathsByClass(numLowerRamps, randRadian() / numLowerRamps, 0.0, 0.0, lowerRampsPathClassID);
   vector[] upperRampsEdgeLocs = buildRampPathsByClass(numUpperRamps, randRadian() / numUpperRamps, 0.0, 0.0, upperRampsPathClassID);

   // Plateau Template.
   int hillDefID = rmAreaDefCreate("plateau def");
   rmAreaDefSetMix(hillDefID, baseMixID);
   rmAreaDefSetCoherence(hillDefID, 0.25);
   rmAreaDefSetCliffType(hillDefID, mapCliffType);
   rmAreaDefSetCliffEmbellishmentDensity(hillDefID, 0.45);
   rmAreaDefSetCliffRampSteepness(hillDefID, 70.0);
   rmAreaDefSetCliffSideRadius(hillDefID, 1, 1);
   rmAreaDefSetHeightNoise(hillDefID, cNoiseFractalSum, 4.0, 0.05, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(hillDefID, 1.0);
   int innerBlendID = rmAreaDefAddHeightBlend(hillDefID, cBlendEdge, cFilter3x3Gaussian, 1);
   int rampBlendID = rmAreaDefAddHeightBlend(hillDefID, cBlendCliffRamp, cFilter5x5Gaussian, 30, 30, true, true); 
   rmAreaDefAddHeightBlendExpansionConstraint(hillDefID, rampBlendID, vDefaultAvoidImpassableLand);
   rmAreaDefSetEdgeSmoothDistance(hillDefID, 5);
   rmAreaDefSetEdgePerturbDistance(hillDefID, -2.0, 2.0);
   rmAreaDefAddToClass(hillDefID, hillClassID);

   // Disable TOB conversion or they might be floating in the air due to blending after painting.
   rmSetTOBConversion(false);

   // Lower hill.
   float lowerHillSize = 0.16;
   float lowerHillHeight = 12.0;

   int lowerHillID = rmAreaDefCreateArea(hillDefID, "lower hill");
   rmAreaSetLoc(lowerHillID, cCenterLoc);
   rmAreaSetSize(lowerHillID, lowerHillSize);
   rmAreaSetHeight(lowerHillID, lowerHillHeight);
   rmAreaSetCliffSideSheernessThreshold(lowerHillID, degToRad(60.0)); // This will give the appearance of a cool rocky transition.
   // Build ramps according to the constraint to prevent them from being 
   // blocked or reduced by enclosure caused by irregular tile edges.
   rmAreaAddCliffEdgeConstraint(lowerHillID, cCliffEdgeRamp, forceLowerRampsOnPath); 
   rmAreaBuild(lowerHillID);

   // Upper hill.
   float upperHillSize = lowerHillSize * 0.185;
   float upperHillHeight = lowerHillHeight + 10.0;

   int upperHillID = rmAreaDefCreateArea(hillDefID, "upper hill");
   rmAreaSetParent(upperHillID, lowerHillID);
   rmAreaSetLoc(upperHillID, cCenterLoc);
   rmAreaSetEdgePerturbDistance(upperHillID, -1.5, 1.5); // Override.
   rmAreaSetHeight(upperHillID, upperHillHeight);
   rmAreaSetCliffSideSheernessThreshold(upperHillID, degToRad(75.0));
   rmAreaSetSize(upperHillID, upperHillSize);
   rmAreaAddCliffEdgeConstraint(upperHillID, cCliffEdgeRamp, forceUpperRampsOnPath); 
   rmAreaAddConstraint(upperHillID, rmCreateAreaEdgeDistanceConstraint(lowerHillID, 35.0));
   rmAreaBuild(upperHillID);

   // Enable TOB conversion.
   rmSetTOBConversion(true);

   // Add some cool details.

   // Statue Major God Definition.
   int statueMajorGodDefID = rmObjectDefCreate("statue major god def ");
   rmObjectDefAddItem(statueMajorGodDefID, cUnitTypeStatueMajorGod, 1);

   // Torch Definition.
   int torchDefID = rmObjectDefCreate("torch def");
   rmObjectDefAddItem(torchDefID, cUnitTypeTorch, 1);
   rmObjectDefSetItemVariation(torchDefID, 0, 0);

   // Get the path ids.
   int[] upperPathIDs = rmClassGetPaths(upperRampsPathClassID);

   // Create an array that will serve for multiloc constraints.
   vector[] storedLocs = new vector(0, cOriginVector);

   // Create a fake center that will serve as an edge constraint.
   int fakeCenterID = rmAreaCreate("fake center");
   rmAreaSetParent(fakeCenterID, upperHillID);
   rmAreaSetLoc(fakeCenterID, cCenterLoc);
   rmAreaSetSize(fakeCenterID, 1.0);
   rmAreaSetEdgeSmoothDistance(fakeCenterID, 7);
   rmAreaAddConstraint(fakeCenterID, rmCreateAreaEdgeDistanceConstraint(upperHillID, 1.75));
   rmAreaBuild(fakeCenterID);

   // Start iterating the paths.
   float pathSize = rmRadiusToAreaFraction(37.0 + (0.5 * cNumberPlayers));
   for(int i = 0; i < numUpperRamps; i++)
   {
      // Get the path id.
      int pathID = upperPathIDs[i];
      int numLocs = 2;

      // Create a path area that will act as a placement constraint for the statues.
      int pathAreaID = rmAreaCreate("path area " + i);
      rmAreaSetPath(pathAreaID, pathID);
      rmAreaSetSize(pathAreaID, pathSize);
      rmAreaSetEdgeSmoothDistance(pathAreaID, 15);
      rmAreaAddConstraint(pathAreaID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 1.0));
      rmAreaBuild(pathAreaID);
      
      // Start searching for the desired locations.
      for(int j = 0; j < numLocs; j++)
      {
         // Enforce a minimum and maximum distance from impassable land (cliff)
         rmAddClosestLocConstraint(rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 3.5));
         rmAddClosestLocConstraint(rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 0.75));

         // Enforce that the location must be inside the path area.
         rmAddClosestLocConstraint(rmCreateAreaMaxDistanceConstraint(pathAreaID, 1.0));

         // Enforce that the location lies on the edge of the fake center.
         rmAddClosestLocConstraint(rmCreateAreaEdgeConstraint(fakeCenterID));

         if(j > 0)
         {  // If this is the second iteration, enable the multiloc constraint to prevent overlaps during the search.
            rmAddClosestLocConstraint(rmCreateMultiLocDistanceConstraint(storedLocs, 3.0));
         }

         // Finally, get the loc.
         vector loc = rmGetClosestLoc(cCenterLoc, -1.0);

         // Store the loc in the array.
         storedLocs.add(loc);

         // Statue placement.
         // Push the found loc further outward to establish a future tangent arc reference.
         vector angleReferenceLoc = loc.translateXZ(rmXMetersToFraction(6), xsVectorAngleAroundY(loc, cCenterLoc));

         // Get the atan.
         float statueAngle = xsVectorAngleAroundY(loc, angleReferenceLoc) + cPiOver2;

         // Place the statue facing outward according to the defined angle.
         int statueMajorGodID = rmObjectDefCreateObject(statueMajorGodDefID);
         rmObjectSetItemRotation(statueMajorGodID, 0, cItemRotateCustom, statueAngle);
         rmObjectPlaceAtLoc(statueMajorGodID, 0, loc);

         // Torch placement.
         vector torcheLoc = angleReferenceLoc;

         int torchID = rmObjectDefCreateObject(torchDefID);
         rmObjectPlaceAtLoc(torchID, 0, torcheLoc);
         
      }

      // Reset constraints.
      rmClearClosestLocConstraints();
   }

   // Hill Constraints.
   int avoidOuterEdges = rmCreateAreaEdgeDistanceConstraint(lowerHillID, 10.0);
   int avoidInnerEdges = rmCreateAreaEdgeDistanceConstraint(upperHillID, 5.0);

   // Add small forests around the hill.
   int edgeCliffForestDefID = rmAreaDefCreate("edge cliff forest def");
   rmAreaDefSetSizeRange(edgeCliffForestDefID, rmTilesToAreaFraction(15), rmTilesToAreaFraction(20));
   rmAreaDefSetForestType(edgeCliffForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(edgeCliffForestDefID, 15.0);
   rmAreaDefAddConstraint(edgeCliffForestDefID, vDefaultAvoidImpassableLand);
   rmAreaDefAddConstraint(edgeCliffForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(edgeCliffForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(edgeCliffForestDefID, vDefaultAvoidKotH);
   rmAreaDefAddConstraint(edgeCliffForestDefID, avoidStatue);
   rmAreaDefAddConstraint(edgeCliffForestDefID, avoidTorch);
   rmAreaDefAddConstraint(edgeCliffForestDefID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 3.0));
   rmAreaDefAddToClass(edgeCliffForestDefID, forestClassID);
   rmAreaDefCreateAndBuildAreas(edgeCliffForestDefID, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand6);
   rmObjectDefAddConstraint(startingTowerID, avoidEdgeForest7);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Hill Settlement.
   float extraWolves = (cNumberPlayers > 4) ? cNumberPlayers / 2 : 0;

   if(gameIsKotH() == false)
   {
      int hillSettlementID = rmObjectCreate("hill settlement");
      rmObjectAddItem(hillSettlementID, cUnitTypeSettlement, 1);
      rmObjectPlaceAtLoc(hillSettlementID, 0, cCenterLoc);
   }

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, avoidEdgeForest10);
   rmObjectDefAddConstraint(firstSettlementID, avoidRamps15);
   rmObjectDefAddConstraint(firstSettlementID, rmCreateAreaDistanceConstraint(upperHillID, 5.0));

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, avoidEdgeForest10);
   rmObjectDefAddConstraint(secondSettlementID, rmCreateAreaDistanceConstraint(upperHillID, 5.0));
   rmObjectDefAddConstraint(secondSettlementID, avoidRamps15);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 65.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, 
                                    cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 65.0, 125.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      // Randomize inside/outside.
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 65.0, -1.0, cFarSettlementDist, cBiasAggressive | allyBias);
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
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, avoidEdgeForest10);
      rmObjectDefAddConstraint(bonusSettlementID, avoidRamps15);
      rmObjectDefAddConstraint(bonusSettlementID, rmCreateAreaDistanceConstraint(upperHillID, 5.0));
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
   {  // Yeah, simlocs in 1v1.
      addSimObjectLocsPerPlayerPair(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, 
                              cBiasVeryAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, 
                              cBiasVeryAggressive);
   }

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(5, 6), 2.0);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(2, 3), 2.0);
      rmObjectDefAddItem(startingHuntID, cUnitTypeElk, xsRandInt(3, 4), 2.0);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(7, 9), 2.0);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(4, 5), cBerryClusterRadius);
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
   float avoidForestMeters = 28.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(60));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(forestClassID, 12.0));
   rmAreaDefAddOriginConstraint(forestDefID, rmCreateClassDistanceConstraint(forestClassID, 17.0));
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidImpassableLand20);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 8.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 8.0);
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
   rmObjectDefAddConstraint(closeGoldID, avoidHill15);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward, cInAreaDefault, 
                                    cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   float avoidBonusGoldMeters = 40.0;

   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, forceToHills);
   rmObjectDefAddConstraint(bonusGoldID, avoidOuterEdges);
   rmObjectDefAddConstraint(bonusGoldID, avoidInnerEdges);
   addObjectDefPlayerLocConstraint(bonusGoldID, 35.0);

   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 35.0, -1.0, avoidBonusGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 35.0, -1.0, avoidBonusGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(4, 5));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeElk, xsRandInt(4, 5));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }

   // Far hunt.
   int farHuntID = rmObjectDefCreate("far hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeBoar, xsRandInt(4, 5));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeAurochs, xsRandInt(4, 5));
   }
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
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(2, 3));
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElk, xsRandInt(2, 3));
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 3));
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

   // Large / Giant map size hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      float largeHuntFloat = xsRandFloat(0.0, 1.0);
      if(largeHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 4));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
      }
      else if(largeHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(5, 6));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(5, 6));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(largeMapHuntID, createTownCenterConstraint(70.0));
      addObjectLocsPerPlayer(largeMapHuntID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(8, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 75.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 75.0, 120.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 75.0, -1.0, avoidBerriesMeters);
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
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(45.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 11 * getMapAreaSizeFactor());

   // Hill Forests.
   float avoidHillForestMeters = 20.0;

   int hillForestDefID = rmAreaDefCreate("hill forest");
   rmAreaDefSetSizeRange(hillForestDefID, rmTilesToAreaFraction(15), rmTilesToAreaFraction(23));
   rmAreaDefSetForestType(hillForestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(hillForestDefID, avoidHillForestMeters);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidImpassableLand12);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(hillForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(hillForestDefID, forceToHills);
   rmAreaDefAddOriginConstraint(hillForestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddOriginConstraint(hillForestDefID, avoidRamps15);
   rmAreaDefCreateAndBuildAreas(hillForestDefID, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Stragglers.
   int numStragglers = xsRandInt(4, 5);
   int stragglerType = 0;
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      vector loc = rmGetPlayerLoc(i, 0);

      for(int j = 0; j < numStragglers; j++)
      {
         // Straggler rand.
         int stragglerRand = xsRandInt(0, 2);

         stragglerType = (xsRandBool(0.5) == true) ? cUnitTypeTreeOak : cUnitTypeTreePine;

         int startingStragglerID = rmObjectDefCreate("starting straggler " + i + j);
         rmObjectDefAddItem(startingStragglerID, stragglerType, 1);
         rmObjectDefAddConstraint(startingStragglerID, vDefaultAvoidAll8);
         rmObjectDefPlaceAtLoc(startingStragglerID, 0, loc, cStartingStragglerMinDist, cStartingStragglerMaxDist, 1, true);
      }  
   }

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockMediumID = rmObjectDefCreate("rock medium");
   rmObjectDefAddItem(rockMediumID, cUnitTypeRockNorseMedium, 1);
   rmObjectDefAddConstraint(rockMediumID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockMediumID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 3.0));
   rmObjectDefPlaceAnywhere(rockMediumID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   int rockLargeID = rmObjectDefCreate("rock large");
   rmObjectDefAddItem(rockLargeID, cUnitTypeRockNorseLarge, 1);
   rmObjectDefAddConstraint(rockLargeID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockLargeID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 2.0));
   rmObjectDefPlaceAnywhere(rockLargeID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Columns
   int columnsBrokenID = rmObjectDefCreate("columns broken");
   rmObjectDefAddItem(columnsBrokenID, cUnitTypeColumnsBroken, 1);
   rmObjectDefAddConstraint(columnsBrokenID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(columnsBrokenID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 2.0));
   rmObjectDefPlaceAnywhere(columnsBrokenID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   int columnsID = rmObjectDefCreate("columns");
   rmObjectDefAddItem(columnsID, cUnitTypeColumns, 1);
   rmObjectDefAddConstraint(columnsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(columnsID, rmCreateTerrainTypeMaxDistanceConstraint(mapCliffTerrainType, 2.0));
   rmObjectDefPlaceAnywhere(columnsID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadDirt, 2.5);

   // Random trees placement.
   for(int i = 0; i < 3; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = 18 / 2;
      if(i == 2)
      {
         treeDensity = xsRandInt(2, 3);
      }
      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreePine; treeName = "pine "; break; }
         case 1: { treeTypeID = cUnitTypeTreeOak; treeName = "oak "; break; }
         case 2: { treeTypeID = cUnitTypeTreeHades; treeName = "dead tree "; break; }
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
      int plantsDensity= 28;
      int plantsGroupDensity = 10;
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantNorseBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantNorseShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantNorseFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantNorseWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantNorseGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantNorseFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantNorseWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
   rmObjectDefPlaceAnywhere(flowersID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers Group.        
   int flowersGroupID = rmObjectDefCreate("flowers group");
   rmObjectDefAddItemRange(flowersGroupID, cUnitTypeFlowers, 2, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(flowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(flowersGroupID, avoidRoad2);   
   rmObjectDefAddConstraint(flowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(flowersGroupID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Meadow Flowers.
   int meadowFlowersID = rmObjectDefCreate("meadow flowers");
   rmObjectDefAddItemRange(meadowFlowersID, cUnitTypeMeadowFlower, 1);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(meadowFlowersID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(meadowFlowersID, avoidRoad1);
   rmObjectDefAddConstraint(meadowFlowersID, avoidRoad2);
   rmObjectDefPlaceAnywhere(meadowFlowersID, 0, 80 * cNumberPlayers * getMapAreaSizeFactor());

   // Meadow Flowers Group.        
   int meadowFlowersGroupID = rmObjectDefCreate("Meadow flowers group");
   rmObjectDefAddItemRange(meadowFlowersGroupID, cUnitTypeMeadowFlower, 5, 8, 0.0, 0.5);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(meadowFlowersGroupID, vDefaultEmbellishmentAvoidWater);   
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidRoad1);
   rmObjectDefAddConstraint(meadowFlowersGroupID, avoidRoad2);
   rmObjectDefAddConstraint(meadowFlowersGroupID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefPlaceAnywhere(meadowFlowersGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
