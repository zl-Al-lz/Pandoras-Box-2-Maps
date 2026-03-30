include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

/*
** Frozen Wastes
** Author: AL (AoM DE XS CODE)
** Based on "Frozen Wastes" by Bubble and Rebels Rising.
** Date: January 15, 2026
** Final revision: March 30, 2026
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_boreal_snowfield_sunset_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}"); 
}

// Custom functions to avoid duplication.
int modCreateGoldPath(string pathString = cEmptyString, vector wayPointA = cInvalidVector, vector wayPointB = cInvalidVector, 
                     int[] constraints = default)
{
   int numConstraints = constraints.size();

   int pathID = rmPathCreate(pathString);
   rmPathAddWaypoint(pathID, wayPointA);
   rmPathAddWaypoint(pathID, wayPointB);
   for(int i = 0; i < numConstraints; i++)
   {
      rmPathAddConstraint(pathID, constraints[i]);
   }
   rmPathBuild(pathID);

   return pathID;
}

bool modAddMultiClosestLocConstraints(ref int[] constraints, float bufferDist = 0.0, bool cleanArr = false)
{
   int numConstraints = constraints.size();
   for(int i = 0; i < numConstraints; i++)
   {
      rmAddClosestLocConstraint(constraints[i], bufferDist);
   }
   if(cleanArr)
   {
      constraints.clear();
   }

   return numConstraints > 0;
}

vector[] modCreateVectorIntervals(vector[] arrLocs = default, int jumpEvery = 0, int skipStart = 0, int skipEnd = 0)
{
   vector[] result = new vector(0, cOriginVector);

   int numLocs = arrLocs.size();

   if(numLocs <= 0 || jumpEvery <= 0)
   {
      return result;
   }

   if(skipStart < 0) skipStart = 0;
   if(skipEnd < 0) skipEnd = 0;

   int startIndex = skipStart;
   int endIndex = numLocs - 1 - skipEnd;

   if(startIndex > endIndex)
   {
      return result;
   }

   result.add(arrLocs[startIndex]);

   for(int i = startIndex + jumpEvery; i < endIndex; i += jumpEvery)
   {
      result.add(arrLocs[i]);
   }

   vector lastAdded = result[result.size() - 1];
   vector lastTile  = arrLocs[endIndex];

   if(xsVectorLength(lastAdded - lastTile) > 0.01)
   {
      result.add(lastTile);
   }

   return result;
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.

   // Base mix.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow3, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass1, 2.0);

   // Ice mix.
   int iceMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(iceMixID, cNoiseRandom);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce1, 1.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce2, 2.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce3, 2.0);

   // Define Default Tree Type.
   rmSetDefaultTreeType(cUnitTypeTreePineSnow);

   // Biome Assets.
   int mapForestType = cForestNorsePineSnow;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypeCow;

   // Map size and terrain init.
   int axisSize = 160;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(iceMixID);

   // Continent Stuff.
   float continentFraction = 0.525;
   float playerContinentEdgeDistMeters = (gameIs1v1() == true) ? 50.0 : 62.0 + cNumberPlayers;
   float placementRadiusMeters = rmFractionToAreaRadius(continentFraction) - playerContinentEdgeDistMeters;
   float placementFraction = rmXMetersToFraction(placementRadiusMeters);

   // Compute the players to obtain their actual placement order.
   int[] computedPlayers = rmComputePlayersForPlacement();

   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnSquare(placementFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetTrailerChimera2);

   // Define Classes.
   int continentClassID = rmClassCreate("continent class");

   /// Define Classes Constraints.
   int forceToContinent = rmCreateClassMaxDistanceConstraint(continentClassID, 0.1, cClassAreaDistance, "force to continent");
   int avoidContinent = rmCreateClassDistanceConstraint(continentClassID, 5.0, cClassAreaDistance, "avoid continent");
   int avoidShores2 = rmCreateClassDistanceConstraint(continentClassID, 2.0, cClassAreaEdgeDistance, "avoid continent edge 2");
   int avoidShores3 = rmCreateClassDistanceConstraint(continentClassID, 3.0, cClassAreaEdgeDistance, "avoid continent edge 3");
   int avoidShores5 = rmCreateClassDistanceConstraint(continentClassID, 5.0, cClassAreaEdgeDistance, "avoid continent edge 5");
   int avoidShores10 = rmCreateClassDistanceConstraint(continentClassID, 10.0, cClassAreaEdgeDistance, "avoid continent edge 10");
   int avoidShores15 = rmCreateClassDistanceConstraint(continentClassID, 15.0, cClassAreaEdgeDistance, "avoid continent edge 15");
   int avoidShores20 = rmCreateClassDistanceConstraint(continentClassID, 20.0, cClassAreaEdgeDistance, "avoid continent edge 20");
   int avoidShores25 = rmCreateClassDistanceConstraint(continentClassID, 25.0, cClassAreaEdgeDistance, "avoid continent edge 25");
   int avoidShores30 = rmCreateClassDistanceConstraint(continentClassID, 30.0, cClassAreaEdgeDistance, "avoid continent edge 30");

   int forceToNearShores15 = rmCreateClassMaxDistanceConstraint(continentClassID, 15.0, cClassAreaEdgeDistance, "force to shores 15");  
   int forceToNearShores20 = rmCreateClassMaxDistanceConstraint(continentClassID, 20.0, cClassAreaEdgeDistance, "force to shores 20");  
   int forceToNearShores30 = rmCreateClassMaxDistanceConstraint(continentClassID, 30.0, cClassAreaEdgeDistance, "force to shores 30");  

   // Define Type Contraints.
   int settlementAvoidGold = rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 12.0, true, "settlement vs gold");

   // Define Overrides.

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 1.0, 0.05, 2, 0.5);

   // Continent.
   int continentID = rmAreaCreate("continent");
   rmAreaSetSize(continentID, continentFraction);
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseShore1, 0, 0.7);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseSnowRocks2, 1, 2);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseSnowRocks1, 2, 3);
   rmAreaSetMix(continentID, baseMixID);
   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 2.5, 0.05, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0);
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 15.0);
   rmAreaSetHeight(continentID, 5.25);
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 10, 10);
   rmAreaSetCoherenceSquare(continentID, true);
   rmAreaSetCoherence(continentID, 0.55);
   rmAreaSetEdgeSmoothDistance(continentID, 5);
   rmAreaAddConstraint(continentID, createSymmetricBoxConstraint(0.07));
   rmAreaAddToClass(continentID, continentClassID);
   rmAreaBuild(continentID);

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, forceToContinent);
   rmObjectDefAddConstraint(startingTowerID, avoidShores3);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Gold Definition.
   float avoidGoldMeters = (cNumberPlayers <= 4) ? 45.0 : 40.0;

   int goldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(goldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidCorner40);

   // If the number of players is large, they will have higher priority for placement over settlements.
   if(cNumberPlayers > 5)
   {
      int numBonusGoldMines = (cNumberPlayers <= 8) ? 4 * getMapAreaSizeFactor() : 3 * getMapAreaSizeFactor();

      // Get the paths that connect the player to the edge of the map.
      int[] edgePathIDs = rmClassGetPaths(vPlayerLocEdgePathClass);

      int[] goldPathIDS = new int(0, cInvalidID);
      vector[] closestLocs = new vector(0, cOriginVector);

      for(int i = 0; i < cNumberPlayers - 1; i++)
      {
         // Temporary Constraints.
         float edgeDistanceInMeters = 12.0;

         int[] constraints = new int(0, cInvalidID);
         int numConstraints = constraints.size();

         // Define the necessary constraints to obtain the necessary locs.
         int tempForceToContinent = rmCreateAreaConstraint(continentID);
         int tempAvoidContinentEdge = rmCreateAreaEdgeDistanceConstraint(continentID, edgeDistanceInMeters);
         int tempForceNearEdges = rmCreateAreaEdgeMaxDistanceConstraint(continentID, edgeDistanceInMeters + 2.0);
         
         constraints.add(tempForceToContinent);
         constraints.add(tempAvoidContinentEdge);
         constraints.add(tempForceNearEdges);

         // Get the player ID from the current index and the next one.
         int p1ID = computedPlayers[i];
         int p2ID = (i < cNumberPlayers - 1) ? computedPlayers[i + 1] : computedPlayers[0];

         // Now, get the players' locs.
         vector p1Loc = rmGetPlayerLoc(p1ID);
         vector p2Loc = rmGetPlayerLoc(p2ID);

         // We create a custom function to avoid code duplication; the constraints previously 
         // stored in the array will be assigned as constraints.
         modAddMultiClosestLocConstraints(constraints);

         // Force the closest loc to be created within the path.
         rmAddClosestLocConstraint(rmCreatePathMaxDistanceConstraint(edgePathIDs[i]), 1.0);

         // Get the closest loc.
         vector connectionLocA = rmGetClosestLoc(p1Loc, 40.0);

         if(i == 0)
         {  // If it is the first iteration, add the loc element to the array.
            closestLocs.add(connectionLocA);
         }

         // Clear the constraints to move on to the next loc.
         rmClearClosestLocConstraints();

         // The same steps as before, but with the following index.
         modAddMultiClosestLocConstraints(constraints);
         rmAddClosestLocConstraint(rmCreatePathMaxDistanceConstraint(edgePathIDs[i + 1]), 1.0);

         vector connectionLocB = rmGetClosestLoc(p2Loc, 40.0);

         // Add to array.
         closestLocs.add(connectionLocB);

         // Clear constraints to move on to the next iteration.
         rmClearClosestLocConstraints();

         // Before moving on to the next iteration, create the path between the two closest locs obtained.
         int pathID = modCreateGoldPath("gold path" + i, connectionLocA, connectionLocB, constraints);
         goldPathIDS.add(pathID);

         // In the final iteration, we connect the first one to the last one.
         if(i == cNumberPlayers - 2)
         {
            int finalPathID = modCreateGoldPath("final gold path" + i, closestLocs[0], closestLocs[i + 1], constraints);
            goldPathIDS.add(finalPathID);
         }

      }

      // It's time to start placing the gold mines.
      int numPaths = goldPathIDS.size();

      for(int i = 0; i < numPaths; i++)
      {
         // Get the path and its number of tiles.
         int pathID = goldPathIDS[i];
         vector[] pathTiles = rmPathGetTiles(pathID);
         int numTiles = pathTiles.size();

         // Fraction Conversion.
         for(int j = 0; j < numTiles; j++)
         {
            vector tempLoc = pathTiles[j];
            tempLoc = rmTileIndexToFraction(tempLoc);
            pathTiles[j] = tempLoc;
         }

         // Optimize the path to pass to the spline.
         vector[] goldWayPoints = modCreateVectorIntervals(pathTiles, 6, 25, 25); // TODO: Spline evaluate at range could be better?

         int numWaypoints = goldWayPoints.size();

         // Define spline.
         int goldSplineID = rmSplineCreate("spline " + i);

         // Add waypoints to the spline.
         for(int j = 0; j < numWaypoints; j++)
         {
            rmSplineAddLoc(goldSplineID, goldWayPoints[j]);
         }

         rmSplineInitialize(goldSplineID);

         // Define the evaluated parts to be omitted from the spline.
         vector[] goldLocs = rmSplineEvaluate(goldSplineID, numBonusGoldMines); 

         // Finally, place the gold mines.
         for(int j = 0; j < numBonusGoldMines; j++)
         {
            rmObjectDefPlaceAtLoc(goldID, 0, goldLocs[j]);
         }
      }
   }

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(firstSettlementID, avoidShores25);
   rmObjectDefAddConstraint(firstSettlementID, forceToContinent);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidGold);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, avoidShores30);
   rmObjectDefAddConstraint(secondSettlementID, forceToContinent);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidGold);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 75.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, 
                                    cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 75.0, 100.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 125.0, cFarSettlementDist, cBiasAggressive | getRandomAllyBias());
   }

   // Other map sizes settlements.
   if(cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, avoidShores20);
      rmObjectDefAddConstraint(bonusSettlementID, forceToContinent);
      rmObjectDefAddConstraint(bonusSettlementID, settlementAvoidGold);
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
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   rmObjectDefAddConstraint(startingGoldID, avoidShores10);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   rmObjectDefAddItem(startingHuntID, cUnitTypeCaribou, xsRandInt(5, 6));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   rmObjectDefAddConstraint(startingHuntID, avoidShores10);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   int chickenNum = xsRandInt(5, 7);

   for(int i = 0; i < chickenNum; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, avoidShores10);
   rmObjectDefAddConstraint(startingChickenID, forceToContinent);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);
   
   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, avoidShores15);
   rmObjectDefAddConstraint(startingBerriesID, forceToContinent);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, avoidShores10);
   rmObjectDefAddConstraint(startingHerdID, forceToContinent);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forest.
   vDefaultForestAvoidAll = vDefaultAvoidAll8;
   float avoidForestMeters = 29.5;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(88));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, forceToContinent);
   rmAreaDefAddConstraint(forestDefID, avoidShores5);
   rmAreaDefAddOriginConstraint(forestDefID, avoidShores15);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 10.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 10.0);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   if(cNumberPlayers <= 5)
   {
      rmObjectDefAddConstraint(goldID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(goldID, avoidShores5);
      rmObjectDefAddConstraint(goldID, forceToNearShores15, cObjectConstraintBufferNone, cNumberPlayers);
      rmObjectDefAddConstraint(goldID, forceToContinent);
   }
   if(gameIs1v1())
   {
      rmObjectDefAddConstraint(goldID, vDefaultAvoidSettlementRange);
   }

   if(gameIs1v1() == true || (cNumberPlayers == 4))
   {  
      // Don't use cNumberplayers % 2 = 0 as more players enter the square, there will be fewer spaces. 
      // In this case, one solution would be to change the continent to a circle, but I don't want it to look repetitive 
      // to Frozen Continent.
      addObjectDefPlayerLocConstraint(goldID, 45.0);
      addMirroredObjectLocsPerPlayerPair(goldID, false, 5 * getMapAreaSizeFactor(), 45.0, -1.0, avoidGoldMeters);
   }
   else if(cNumberPlayers <= 5)
   {
      addObjectDefPlayerLocConstraint(goldID, 35.0);
      addObjectLocsPerPlayer(goldID, false, 4 * getMapAreaSizeFactor(), 35.0, -1.0, avoidGoldMeters);
   }
   
   generateLocs("gold locs");

   rmSetProgress(0.5);
   
   // Hunt.
   float avoidHuntMeters = 45.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeElk, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeCaribou, xsRandInt(5, 6));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, forceToContinent);
   rmObjectDefAddConstraint(closeHuntID, avoidShores10);
   addObjectDefPlayerLocConstraint(closeHuntID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt ");
   rmObjectDefAddItem(bonusHuntID, cUnitTypeWalrus, xsRandInt(5, 6));
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, forceToContinent);
   rmObjectDefAddConstraint(bonusHuntID, avoidShores15);
   rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(70.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 70.0, 120.0, avoidHuntMeters, cBiasVeryAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 70.0, -1.0, avoidHuntMeters, cBiasVeryAggressive);
   }

   // Bonus Hunt 2 & 3
   int numExtraHuntPerPlayer = 2;

   for(int i = 0; i < numExtraHuntPerPlayer; i++)
   {
      float extraHuntFloat = xsRandFloat(0.0, 1.0);

      int bonusExtraHunt = rmObjectDefCreate("bonus extra hunt" + i);

      if(extraHuntFloat < 0.10)
      {
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeBoar, xsRandInt(5, 6));
      }
      else if(extraHuntFloat < 0.40)

      {
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeElk, xsRandInt(6, 7));
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeAurochs, 2);
      }
      else if(extraHuntFloat < 0.70)
      {
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeCaribou, xsRandInt(5, 6));
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeBoar, xsRandInt(2, 3));
      }
      else
      {
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeCaribou, xsRandInt(3, 4));
         rmObjectDefAddItem(bonusExtraHunt, cUnitTypeElk, xsRandInt(2, 4));
      }
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(bonusExtraHunt, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusExtraHunt, forceToContinent);
      if(i == 0)
      {
         rmObjectDefAddConstraint(bonusExtraHunt, avoidShores20);
      }
      else if(i == 1)
      {
         rmObjectDefAddConstraint(bonusExtraHunt, avoidShores30);
      }

      if(gameIs1v1() == true)
      {
         addSimObjectLocsPerPlayerPair(bonusExtraHunt, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidHuntMeters, cBiasVeryAggressive);
      }
      else
      {
         addObjectLocsPerPlayer(bonusExtraHunt, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidHuntMeters, cBiasVeryAggressive);
      }

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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(6, 9));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 5));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(3, 6));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(largeMapHuntID, forceToContinent);
         rmObjectDefAddConstraint(largeMapHuntID, avoidShores5);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 90.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 90.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int closeBerriesID = rmObjectDefCreate("close berries");
   rmObjectDefAddItem(closeBerriesID, cUnitTypeBerryBush, xsRandInt(5, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeBerriesID, forceToContinent);
   rmObjectDefAddConstraint(closeBerriesID, avoidShores15);
   addObjectDefPlayerLocConstraint(closeBerriesID, 55.0);
   addObjectLocsPerPlayer(closeBerriesID, false, 1 * getMapSizeBonusFactor(), 55.0, 75.0, avoidBerriesMeters);

   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(8, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farBerriesID, forceToContinent);
   rmObjectDefAddConstraint(farBerriesID, avoidShores15);
   addObjectDefPlayerLocConstraint(farBerriesID, 70.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 70.0, 120.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidBerriesMeters);
   }

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 45.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, mapHerdType, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, forceToContinent);
   rmObjectDefAddConstraint(closeHerdID, avoidShores2);
   addObjectDefPlayerLocConstraint(closeHerdID, 45.0);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 45.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, forceToContinent);
   rmObjectDefAddConstraint(bonusHerdID, avoidShores2);
   addObjectDefPlayerLocConstraint(bonusHerdID, 60.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int farPredatorID = rmObjectDefCreate("far predator ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(farPredatorID, cUnitTypeArcticWolf, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(farPredatorID, cUnitTypePolarBear, 2);
   }
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farPredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farPredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farPredatorID, forceToContinent);
   rmObjectDefAddConstraint(farPredatorID, avoidShores5);
   addObjectDefPlayerLocConstraint(farPredatorID, 75.0);
   addObjectLocsPerPlayer(farPredatorID, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.7);

   // Relics.
   float avoidRelicMeters = 75.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, forceToContinent);
   rmObjectDefAddConstraint(relicID, avoidShores5);
   addObjectDefPlayerLocConstraint(relicID, 75.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 75.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(40.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(60.0));
   
   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 8 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow, 3, 4);

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(goldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 9.0);
   buildAreaUnderObjectDef(closeBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 9.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 9.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 60 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 60 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadSnow1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoadSnow2, 2.5);

   // Random tree pine snow.
   int randomTreePineSnowID = rmObjectDefCreate("random tree pine snow");
   rmObjectDefAddItem(randomTreePineSnowID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidRoad2);
   rmObjectDefAddConstraint(randomTreePineSnowID, forceToContinent);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidShores2);
   rmObjectDefPlaceAnywhere(randomTreePineSnowID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 20;
      int plantsGroupDensity = xsRandInt(8, 10);
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantSnowBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantSnowShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantSnowFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantSnowWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantSnowGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantSnowFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantSnowWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, forceToContinent);
      rmObjectDefAddConstraint(plantTypeDef, avoidShores2);
      if(i >= 5)
      {
         rmObjectDefAddConstraint(plantTypeDef, avoidShores5);
      }
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
   rmObjectDefAddConstraint(logID, forceToContinent);
   rmObjectDefAddConstraint(logID, avoidShores5);
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
   rmObjectDefAddConstraint(logGroupID, forceToContinent);
   rmObjectDefAddConstraint(logGroupID, avoidShores5);
   rmObjectDefPlaceAnywhere(logGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Snowmist.
   int snowmistID = rmObjectDefCreate("snowmist");
   rmObjectDefAddItem(snowmistID, cUnitTypeVFXSnowDriftPlain, 1);
   rmObjectDefAddConstraint(snowmistID, avoidContinent);
   rmObjectDefPlaceAnywhere(snowmistID, 0, 6 * cNumberPlayers * getMapAreaSizeFactor());

   // Light snowfall.
   rmTriggerAddScriptLine("rule _snow");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trRenderSnow(1.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");

   // Lighting Override.
   lightingOverride();

   rmSetProgress(1.0);
}
