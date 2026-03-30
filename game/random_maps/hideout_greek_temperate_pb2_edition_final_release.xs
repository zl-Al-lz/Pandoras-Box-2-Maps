include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

/*
** Hideout (Without walls)
** Author: AL (AoM DE XS CODE)
** Based on "Hideout" by AoE II DE & AOE IV Team
** Date: January 14, 2026
*/

void lightingOverride()
{
   rmTriggerAddScriptLine("rule _customLighting");
   rmTriggerAddScriptLine("highFrequency"); 
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"biome_greek_temperate_day_01_mod\",0.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
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

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate("Greek Temperate Mix");
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.3, 2);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 2.0);
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

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypePig;

   // If true, it creates a GPs blocking barrier in the center of the map, preventing divine powers 
   // like the Wither from opening a path at the start of the game.

   bool gpBarrier = false; // DEPRECATED: Read below to find out why.
   
   // In KOTH we need more space so that predators don't bother the player.

   // Map size and terrain init.
   int axisSize = (!gameIsKotH()) ? 140 : 148;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Map Stuff.
   float centerSize = (!gameIsKotH()) ? 0.265 : 0.3;
   if(gpBarrier && gameIs1v1())
   {
      centerSize += smallerMetersToFraction(10.0);
   }
   else
   {
      centerSize += smallerMetersToFraction(5.0);
   }

   float playerCenterEdgeDistMeters = 31.0;
   float placementRadiusMeters = rmFractionToAreaRadius(centerSize) - playerCenterEdgeDistMeters;
   float placemenFraction = rmXMetersToFraction(placementRadiusMeters);

   // Player placement.
   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnCircle(placemenFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Lighting.
   rmSetLighting(cLightingSetRmAcropolis01);

   // Define Classes.
   int forestClassID = rmClassCreate("forest class");
   int playerAreaClassID = rmClassCreate("player area class");
   int pathClassID = rmClassCreate("path area class");
   int beautificationPathClassID = rmClassCreate("beautification path class");

   // Define Classes Constraints.
   int forestAvoidance = rmCreateClassDistanceConstraint(forestClassID, 1.0, cClassAreaDistance, "forest vs forest");
   int avoidPlayerArea = rmCreateClassDistanceConstraint(playerAreaClassID, 1.0, cClassAreaDistance, "forest vs player area");
   int playerAreaAvoidance = rmCreateClassDistanceConstraint(playerAreaClassID, 22.0, cClassAreaDistance, "player area vs player area");
   int avoidPath = rmCreateClassDistanceConstraint(pathClassID, 1.0, cClassAreaDistance, "forest vs path");
   int avoidForest15 = rmCreateClassDistanceConstraint(forestClassID, 15.0, cClassAreaDistance, "anything vs forest 15");
   int avoidBeautificationPath = rmCreateClassDistanceConstraint(beautificationPathClassID, 1.0, cClassAreaDistance, 
                                                                  "resources layers  vs beautification path");

   // Define Type Constraints.
   int avoidTower5 = rmCreateTypeDistanceConstraint(cUnitTypeSentryTower, 5.0, true, "forest vs tower");

   // Define Overrides.

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 6.5, 0.04, 1.5, 1.0);

   // KotH.
   placeKotHObjects();

   // Path Definition.
   int pathDefID = rmPathDefCreate("path def");

   // Path Area Definition.
   int pathAreaDefID = rmAreaDefCreate("path area def");
   rmAreaDefAddToClass(pathAreaDefID, pathClassID);

   if(gameIsKotH())
   {
      float kotHPathWidth = 20.0;
      createPlayerToLocConnections("player to center koth connection", pathDefID, pathAreaDefID, cCenterLoc, kotHPathWidth);
   }

   rmSetProgress(0.2);

   // Starting Towers first.

   // Beautification Path Definition
   int beautificationPathDefID = rmPathDefCreate("beautification path def");
   rmPathDefSetCostNoise(beautificationPathDefID, 0.0, 5.0);

   int beautificationPathAreaDefID = rmAreaDefCreate("beautification path area def");
   rmAreaDefSetTerrainType(beautificationPathAreaDefID, cTerrainGreekGrassDirt2);
   rmAreaDefAddToClass(beautificationPathAreaDefID, beautificationPathClassID);

   // Starting Towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);

   for(int i = 1; i <= cNumberPlayers; i++)
   {

      int numFrontTowers = 3;

      int p = vDefaultTeamPlayerOrder[i];
      vector pLoc = rmGetPlayerLoc(p);
      vector dir = pLoc - cCenterLoc;

      float angle = atan2(dir.z, dir.x);

      vector towerCenterLoc = pLoc.translateXZ(rmXMetersToFraction(1.0), angle);

      vector[] frontPoints = placeLocationsInCircle(numFrontTowers, 30.0, angle, 0.0, 0.0, towerCenterLoc, 0.4);

      // The one in the middle will always be a little further ahead.
      vector tempLoc = frontPoints[1];

      frontPoints[1] = tempLoc.translateXZ(rmXMetersToFraction(6.0), angle);
      frontPoints.add(pLoc.translateXZ(-rmXMetersToFraction(28.0), angle));

      numFrontTowers = frontPoints.size();

      for(int j = 0; j < numFrontTowers; j++)
      {

         // This is unnecessary and not mandatory, but it's a nice touch :)
         createLocConnection("starting tower" + j + "from player" + p, beautificationPathDefID, beautificationPathAreaDefID, 
                              pLoc, frontPoints[j], 0.0);

         float towerAngle = xsVectorAngleAroundY(frontPoints[j], pLoc);
         rmObjectDefSetItemRotation(startingTowerID, 0, cItemRotateCustom, towerAngle + cPiOver2);

         // Tower Placement.
         rmObjectDefPlaceAtLoc(startingTowerID, p, frontPoints[j]); 

      }

   }

   // Town Center.
   placeStartingTownCenters();

   // Center Area.
   int centerAreaID = rmAreaCreate("center area");
   rmAreaSetLoc(centerAreaID, cCenterLoc);
   rmAreaSetSize(centerAreaID, centerSize);
   rmAreaSetCoherence(centerAreaID, 0.10);
   rmAreaSetEdgePerturbDistance(centerAreaID, 0.0, 7.0);
   rmAreaSetEdgeSmoothDistance(centerAreaID, 5.0);
   rmAreaBuild(centerAreaID);

   // Center Area Constraints.
   int avoidCenterForest10 = rmCreateAreaEdgeDistanceConstraint(centerAreaID, 10.0, "anything vs center area in 10 meters");
   int avoidCenterForest15 = rmCreateAreaEdgeDistanceConstraint(centerAreaID, 15.0, "anything vs center area in 15 meters");
   int avoidCenterForest20 = rmCreateAreaEdgeDistanceConstraint(centerAreaID, 20.0, "anything vs center area in 20 meters");
   int avoidCenterForest25 = rmCreateAreaEdgeDistanceConstraint(centerAreaID, 25.0, "anything vs center area in 25 meters");

   // Changed area distance to edge distance. Now objects in KOTH mode can be placed on paths ↑

   // Player Areas.
   float playerAreaSize = rmRadiusToAreaFraction(36.5);
   for(int i = 1; i <= cNumberPlayers; i++)
   {

      int p = vDefaultTeamPlayerOrder[i];

      // We're not going to create the area as such in the player's origin location, we're going to push it, 
      // because if I push both, the town center will be too far out, so we'll only push the fake avoidance area.
      // Perhaps a simple glance might be imperceptible, but hey, small details.

      vector pLoc = rmGetPlayerLoc(p);
      
      vector dir = pLoc - cCenterLoc;

      float angle = atan2(dir.z, dir.x);

      vector areaLoc = pLoc.translateXZ(rmXMetersToFraction(4.0), angle);

      int playerAreaID = rmAreaCreate("player area" + p);
      rmAreaSetLoc(playerAreaID, areaLoc);
      rmAreaSetSize(playerAreaID, playerAreaSize);
      rmAreaSetCoherence(playerAreaID, 0.35);
      rmAreaSetEdgeSmoothDistance(playerAreaID, 2.0);
      rmAreaSetEdgePerturbDistance(playerAreaID, -4.0, 0.0);

      // At first glance, you might not understand why this is. ↓
      rmAreaAddConstraint(playerAreaID, rmCreateAreaEdgeDistanceConstraint(centerAreaID, 8.0));
      // ↑ This will help avoid gaps between the player area and the edges of the central area caused by edgePerturbDistance. 
      // Don't worry, pathClass ensures the player isn't enclosed and is more precise.
      rmAreaAddConstraint(playerAreaID, playerAreaAvoidance);
      rmAreaAddToClass(playerAreaID, playerAreaClassID);
   }

   rmAreaBuildAll();

   // Path Placement.
   for(int i = 1; i <= cNumberPlayers; i++)
   {

      /*
      float playerAngle = vPlayerAngles[p];
      vector edgeLoc = getLocOnEdgeAtAngle(playerAngle);
      */  

      // Since I don't trust the accuracy of edgeLoc, I will create a more secure and precise location.
      int p = vDefaultTeamPlayerOrder[i];
      vector pLoc = rmGetPlayerLoc(p);
      float pathWidth = 45.0;
      vector dir = pLoc - cCenterLoc;

      float angle = atan2(dir.z, dir.x);

      vector connectionLoc = pLoc.translateXZ(rmXMetersToFraction(60.0), angle);
      
      createLocConnection("player" + p + "connection", pathDefID, pathAreaDefID, pLoc, connectionLoc, pathWidth);
   }

   // Forest Definition.
   int centerForestDefID = rmAreaDefCreate("center forest def");
   rmAreaDefSetForestType(centerForestDefID, mapForestType);
   rmAreaDefSetSize(centerForestDefID, 1.0);
   rmAreaDefAddConstraint(centerForestDefID, rmCreateAreaConstraint(centerAreaID));
   rmAreaDefAddConstraint(centerForestDefID, forestAvoidance);
   rmAreaDefAddConstraint(centerForestDefID, avoidPlayerArea);
   rmAreaDefAddConstraint(centerForestDefID, avoidPath);
   rmAreaDefAddConstraint(centerForestDefID, avoidTower5);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidKotH);
   rmAreaDefAddToClass(centerForestDefID, forestClassID);   

   // Forest Placement.
   while(true)
   {
      int centerForestID = rmAreaDefCreateArea(centerForestDefID);
      
      if(!rmAreaFindOriginLoc(centerForestID))
      {
         rmAreaSetFailed(centerForestID);
         break;
      }

      rmAreaBuild(centerForestID);
   }

// DEPRECATED: Sadly, GP blockers have no effect when you run the script from Skirmish, but they do work from the editor.
/*
   // IMPORTANT: Designed for 1v1 only and standard map size.
   if(gpBarrier && gameIs1v1())
   {
      // Creating constraints on the path to avoid playerAreaClassID can be inaccurate; 
      // we need something much more faithful to the painted forest.
      int fakeCenterID = rmAreaCreate("fake center");
      rmAreaSetParent(fakeCenterID, centerAreaID);
      rmAreaSetLoc(fakeCenterID, cCenterLoc);
      rmAreaSetSize(fakeCenterID, 0.1); // Don't switch to 1.0, it will consume the entire center; 0.1 is more than enough radius.
      rmAreaAddConstraint(fakeCenterID, rmCreateClassDistanceConstraint(playerAreaClassID, 1.0));
      rmAreaBuild(fakeCenterID);

      // Create the path.
      int gpAvoidancePathID = rmPathCreate("god power avoidance path");
      for(int i = 1; i <= 2; i++)
      {
         // Obtain the player's loc, and rotate it by cPI / 2 (number of players, there's no need to interpolate the locs)
         // This is only for competitive 1v1, I'm not interested in deshardcoding this.
         vector pLoc = rmGetPlayerLoc(i);
         vector rotatedLoc = xsVectorRotateXZ(pLoc, cPi / 2, cCenterLoc);

         // Move it a little further towards the center, so that the path is not created so close to the edges.
         rotatedLoc = xsVectorTranslateXZ(rotatedLoc, -smallerMetersToFraction(5.0), xsVectorAngleAroundY(rotatedLoc, cCenterLoc));
         rmPathAddWaypoint(gpAvoidancePathID, rotatedLoc);

         if(i == 1)
         {  // Always force an intermediate waypoint in the center for better symmetry.
            rmPathAddWaypoint(gpAvoidancePathID, cCenterLoc);
         }
      }

      // This is more accurate than avoiding player area.
      // I considered using splines, but I need constraint control when building the path.
      rmPathAddConstraint(gpAvoidancePathID, rmCreateAreaEdgeDistanceConstraint(fakeCenterID, 6.0)); 

      rmPathAddConstraint(gpAvoidancePathID, rmCreateAreaConstraint(centerAreaID));
      rmPathBuild(gpAvoidancePathID);

      // Get the tiles from the builded path.
      vector[] pathTiles = rmPathGetTiles(gpAvoidancePathID);
      int numPathTiles = pathTiles.size();

      // Fraction conversion.
      for(int i = 0; i < numPathTiles; i++)
      {
         pathTiles[i] = rmTileIndexToFraction(pathTiles[i]);
         vector tempLoc = pathTiles[i];
      }  

      // Create waypoints with an interval of 4 tiles.
      vector[] gpAvoidanceWaypoints = modMakePathWaypointsFromTiles(pathTiles, 4);
      int numGPAvoidanceWaypoints = gpAvoidanceWaypoints.size();
  
      // God Power Blocker Definition.
      int godPowerBlockerDefID = rmObjectDefCreate("god power blocker def");
      rmObjectDefAddItem(godPowerBlockerDefID, cUnitTypeGodPowerBlocker);

      // Place GP blockers at each waypoint.
      for(int i = 0; i < numGPAvoidanceWaypoints; i++)
      {
         rmObjectDefPlaceAtLoc(godPowerBlockerDefID, 0, gpAvoidanceWaypoints[i]);
      }

      // The block radius isn't enough. We need to expand it so no one can take advantage of the situation.
      increaseGPBlockerRadius(); // TODO: Remove the barrier on late game?

      // If a dev is reading this, I could have limited the GP Blocker radius to 1 tile and retrieved all the tiles within a 
      // created area, then convert each tile index to fractional coordinates using rmTileIndexToFraction 
      // (with an expansion buffer) and place an object on each tile.

      // However, that would be a brutal hit to performance (yes, even for a relatively small center, 
      // it would mean over a thousand tiles), so it would be great if an engineer with access to the source code could 
      // implement this feature instead.
      // And while you're at it, it could be made even more flexible by supporting GP IDs, player IDs, or even an array of GP IDs.
   }
*/

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, avoidForest15);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, avoidForest15);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 75.0, 85.0, cSettlementDist1v1, cBiasBackward,
                                    cInAreaDefault, cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 90.0, 135.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 75.0, 90.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 120.0, 165.0, cFarSettlementDist, cBiasAggressive | allyBias);
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
      rmObjectDefAddConstraint(bonusSettlementID, avoidForest15);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Starting objects.
   float distanceReduction = 2.0;

   // Starting Gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasDefensive);

   generateLocs("starting gold locs");

   // Berries.
   vDefaultBerriesAvoidAll = vDefaultAvoidAll6;
   vDefaultBerriesAvoidImpassableLand = vDefaultAvoidImpassableLand6;

   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidImpassableLand6);
   if(gpBarrier && gameIs1v1())
   {  // In case the powers are blocked, make sure it's far enough away to use Poseidon's GP.
      rmObjectDefAddConstraint(startingBerriesID, rmCreateLocDistanceConstraint(cCenterLoc, 38.0));
   }
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, 
                           cStartingObjectAvoidanceMeters); // Only on min distance.

   vDefaultBerriesAvoidAll = vDefaultAvoidAll8;
   vDefaultBerriesAvoidImpassableLand = vDefaultAvoidImpassableLand8;

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(5, 6), 2.0);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidAll6);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidImpassableLand4);
   if(gpBarrier && gameIs1v1())
   {  // In case the powers are blocked, make sure it's far enough away to use Poseidon's GP.
      rmObjectDefAddConstraint(startingHuntID, rmCreateLocDistanceConstraint(cCenterLoc, 38.0));
   }
  // rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist , cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7), 2.0);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidAll6);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidImpassableLand4);
   if(gpBarrier && gameIs1v1())
   {  // In case the powers are blocked, make sure it's far enough away to use Poseidon's GP.
      rmObjectDefAddConstraint(startingChickenID, rmCreateLocDistanceConstraint(cCenterLoc, 38.0));
   }
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidCenterForest20);
   addObjectDefPlayerLocConstraint(bonusGoldID, 65.0);

   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 4 * getMapAreaSizeFactor(), 65.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 4 * getMapAreaSizeFactor(), 65.0, -1.0, avoidGoldMeters);
   }
   
   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 45.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(5, 6));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(3, 4));
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   if(gameIs1v1())
   {
      rmObjectDefAddConstraint(closeHuntID, avoidCenterForest20);
   }
   else
   {
      rmObjectDefAddConstraint(closeHuntID, avoidCenterForest10);
   }
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
      rmObjectDefAddItem(farHuntID, cUnitTypeBoar, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(farHuntID, avoidCenterForest20);
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
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(3, 4));

   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, avoidCenterForest20);
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
   rmObjectDefAddItem(bonusHunt2ID, cUnitTypeDeer, xsRandInt(6, 7));
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHunt2ID, avoidCenterForest20);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 90.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 90.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 90.0, -1.0, avoidHuntMeters);
   }

   // Large / Giant map size hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      float largeHuntFloat = xsRandFloat(0.0, 1.0);
      if(largeHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 4));
      }
      else if(largeHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(5, 6));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(largeMapHuntID, avoidCenterForest20);
      rmObjectDefAddConstraint(largeMapHuntID, createTownCenterConstraint(70.0));
      addObjectLocsPerPlayer(largeMapHuntID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
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
   rmObjectDefAddConstraint(farBerriesID, avoidCenterForest20);
   addObjectDefPlayerLocConstraint(farBerriesID, 75.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 75.0, 120.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapSizeBonusFactor(), 75.0, -1.0, avoidBerriesMeters);
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
   if(gameIs1v1())
   {
      rmObjectDefAddConstraint(closeHerdID, avoidCenterForest15);
   }
   else
   {
      rmObjectDefAddConstraint(closeHerdID, avoidCenterForest10);
   }
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidCenterForest15);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

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
   rmObjectDefAddConstraint(closePredatorID, avoidCenterForest15);
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
   rmObjectDefAddConstraint(farPredatorID, avoidCenterForest15);
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
   rmObjectDefAddConstraint(relicID, avoidCenterForest20);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forest.
   float avoidForestMeters = 40.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(55), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   rmAreaDefAddConstraint(forestDefID, avoidCenterForest15);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(45.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));
   rmAreaDefAddOriginConstraint(forestDefID, avoidCenterForest25);
   rmAreaDefAddToClass(forestDefID, forestClassID);   

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 7 * getMapAreaSizeFactor());

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

   // Gold areas.
   int numStartingGolds = rmObjectDefGetNumberCreatedObjects(startingGoldID);
   float goldAreaSize = rmRadiusToAreaFraction(6.0);

   for(int i = 0; i < numStartingGolds; i++)
   {
      int goldID = rmObjectDefGetCreatedObject(startingGoldID, i);
      vector goldLoc = rmObjectGetLoc(goldID);

      int goldAreaID = rmAreaCreate("gold area" + i);
      rmAreaSetLoc(goldAreaID, goldLoc);
      rmAreaSetSize(goldAreaID, goldAreaSize);
      rmAreaSetTerrainType(goldAreaID, cTerrainGreekGrassRocks2);
      rmAreaAddTerrainConstraint(goldAreaID, rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrassRocks2, 1.0));
      rmAreaAddTerrainLayer(goldAreaID, cTerrainGreekGrassRocks1, 0);
      rmAreaAddConstraint(goldAreaID, avoidBeautificationPath, 1.0);
      rmAreaBuild(goldAreaID);
   }

   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);

   // Berries areas.
   int numStartingBerries = rmObjectDefGetNumberCreatedObjects(startingBerriesID);
   float berriesAreaSize = rmRadiusToAreaFraction(10.0);

   for(int i = 0; i < numStartingBerries; i++)
   {
      int berriesID = rmObjectDefGetCreatedObject(startingBerriesID, i);
      vector berriesLoc = rmObjectGetLoc(berriesID);

      int berriesAreaID = rmAreaCreate("berries area" + i);
      rmAreaSetLoc(berriesAreaID, berriesLoc);
      rmAreaSetSize(berriesAreaID, berriesAreaSize);
      rmAreaSetTerrainType(berriesAreaID, cTerrainGreekGrass2);
      rmAreaAddTerrainConstraint(berriesAreaID, rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrass2, 1.0));
      rmAreaAddTerrainLayer(berriesAreaID, cTerrainGreekGrass1, 0);
      rmAreaAddConstraint(berriesAreaID, avoidBeautificationPath, 1.0);
      rmAreaBuild(berriesAreaID);
   }

   buildAreaUnderObjectDef(farBerriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);

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

   // Spots.
   int spotsBeautificationClassID = rmClassCreate("spot class");
   int spotsAvoidance = rmCreateClassDistanceConstraint(spotsBeautificationClassID, 30.0);

   int grassDirtSpotsID = rmAreaDefCreate("grass dirt spots beautification area");
   rmAreaDefSetSizeRange(grassDirtSpotsID, rmTilesToAreaFraction(100), rmTilesToAreaFraction(135));
   rmAreaDefAddTerrainLayer(grassDirtSpotsID, cTerrainGreekGrassDirt1, 0);
   rmAreaDefAddTerrainLayer(grassDirtSpotsID, cTerrainGreekGrassDirt2, 1);
   rmAreaDefAddTerrainLayer(grassDirtSpotsID, cTerrainGreekGrassDirt2, 2);
   rmAreaDefSetTerrainType(grassDirtSpotsID, cTerrainGreekGrassDirt3);
   rmAreaDefAddConstraint(grassDirtSpotsID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(grassDirtSpotsID, vDefaultAvoidCollideable4);
   rmAreaDefAddConstraint(grassDirtSpotsID, avoidBeautificationPath, 2.0);
   rmAreaDefAddConstraint(grassDirtSpotsID, avoidRoad1);
   rmAreaDefAddConstraint(grassDirtSpotsID, avoidRoad2);
   rmAreaDefAddConstraint(grassDirtSpotsID, rmCreateClassDistanceConstraint(forestClassID, 3.0));
   rmAreaDefAddConstraint(grassDirtSpotsID, spotsAvoidance);
   rmAreaDefAddToClass(grassDirtSpotsID, spotsBeautificationClassID);
   rmAreaDefCreateAndBuildAreas(grassDirtSpotsID, 2 * cNumberPlayers * getMapAreaSizeFactor());

   int denseGrassSpotsID = rmAreaDefCreate("dense grass spots beautification area");
   rmAreaDefSetSizeRange(denseGrassSpotsID, rmTilesToAreaFraction(100), rmTilesToAreaFraction(135));
   rmAreaDefAddTerrainLayer(denseGrassSpotsID, cTerrainGreekGrass1, 0);
   rmAreaDefSetTerrainType(denseGrassSpotsID, cTerrainGreekGrass2);
   rmAreaDefAddConstraint(denseGrassSpotsID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(denseGrassSpotsID, vDefaultAvoidCollideable4);
   rmAreaDefAddConstraint(denseGrassSpotsID, avoidBeautificationPath, 2.0);
   rmAreaDefAddConstraint(denseGrassSpotsID, avoidRoad1);
   rmAreaDefAddConstraint(denseGrassSpotsID, avoidRoad2);
   rmAreaDefAddConstraint(denseGrassSpotsID, rmCreateClassDistanceConstraint(forestClassID, 3.0));
   rmAreaDefAddConstraint(denseGrassSpotsID, spotsAvoidance);
   rmAreaDefAddToClass(denseGrassSpotsID, spotsBeautificationClassID);
   rmAreaDefCreateAndBuildAreas(denseGrassSpotsID, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Random trees placement.
   for(int i = 0; i < 3; i++)
   {
      // Tree stuff.
      int treeTypeID = cInvalidID;
      string treeName = cEmptyString;
      int treeDensity = 0;

      if(i == 2)
      {
         treeDensity = xsRandInt(4, 5);
      }
      switch(i)
      {
         case 0: { treeTypeID = cUnitTypeTreeOak; treeName = "oak "; treeDensity = 18; break; }
         case 1: { treeTypeID = cUnitTypeTreeOlive; treeName = "olive "; treeDensity = 5; break; }
         case 2: { treeTypeID = cUnitTypeTreeCypress; treeName = "cypress "; treeDensity = 3; break; }
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
      int plantsDensity= 30;
      int plantsGroupDensity = xsRandInt(5, 8);
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

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Lighting Override.
   lightingOverride();

   rmSetProgress(1.0);
}
