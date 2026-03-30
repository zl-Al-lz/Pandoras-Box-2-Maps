include "lib2/rm_core.xs";

/*
** Frozen Continent (A reimagined version of Frozen Wastes)
** Author: AL (AoM DE XS CODE)
** Based on "Frozen Wastes" by Bubble and RR
** Date: August 4, 2025
** Update: January 31, 2026
** Final revision: March 30, 2026
*/

void generate()
{
   rmSetProgress(0.0);

   // Ice Mix.
   int iceMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(iceMixID, cNoiseRandom);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce1, 1.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce2, 2.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce3, 2.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.25, 3, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnow1, 3.8);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnow2, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnowGrass1, 1.8);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnowDirt1, 1.8);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnowDirt2, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnowGrass2, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainJapaneseSnow3, 0.4);

   // Define Default Tree Type.
   rmSetDefaultTreeType(cUnitTypeTreePineBuddhistSnow);

   // Biome Assets.
   int mapForestType = cForestJapaneseBuddhistPineSnow;
   int mapWaterType = cWaterJapaneseLake;
   int mapCliffType = cCliffJapaneseSnow;
   int mapCliffTerrainType = cTerrainJapaneseCliffSnow1;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = cUnitTypeCow;

   // Water overrides.
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainJapaneseShore1, 2.0, 2.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainJapaneseSnowRocks2, 5.0, 2.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainJapaneseSnowRocks1, 7.0, 2.0);

   // Map size and terrain init.
   int axisSize = 160;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(iceMixID);

   // Map Stuff.
   float continentFraction = 0.46;
   float playerContinentEdgeDistMeters = 44.0;
   float placementRadiusMeters = rmFractionToAreaRadius(continentFraction) - playerContinentEdgeDistMeters;
   float placementFraction = smallerMetersToFraction(placementRadiusMeters);
   float maxDistanceFromPondMeters = 13.0;

   // Player placement.
   rmSetTeamSpacingModifier(0.8);
   rmPlacePlayersOnCircle(placementFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureJapanese);

   // Lighting.
   rmSetLighting(cLightingSetRmKerlaugar01);
   
   // Define Classes.
   int continentClassID = rmClassCreate("continent class");
   int pondClassID = rmClassCreate("pond class");
   int playerAreaClassID = rmClassCreate("player area class");
   int cliffClassID = rmClassCreate("cliff class");

   // Define Classes Constraints.
   int cliffAvoidance = rmCreateClassDistanceConstraint(cliffClassID, 50.0, cClassAreaDistance, "cliff vs cliff");
   int avoidPlayerArea = rmCreateClassDistanceConstraint(playerAreaClassID, 12.0, cClassAreaDistance, "cliff vs player area");
   int avoidContinent = rmCreateClassDistanceConstraint(continentClassID, 1.0, cClassAreaDistance, "avoid continent");
   int forceToContinent = rmCreateClassMaxDistanceConstraint(continentClassID, 0.01, cClassAreaDistance, "force to continent");
   int avoidContinentShores3 = rmCreateClassDistanceConstraint(continentClassID, 3.0, cClassAreaEdgeDistance, "avoid continent edge 3");
   int avoidContinentShores5 = rmCreateClassDistanceConstraint(continentClassID, 5.0, cClassAreaEdgeDistance, "avoid continent edge 5");
   int avoidContinentShores10 = rmCreateClassDistanceConstraint(continentClassID, 10.0, cClassAreaEdgeDistance, "avoid continent edge 10");
   int avoidContinentShores13 = rmCreateClassDistanceConstraint(continentClassID, 13.0, cClassAreaEdgeDistance, "avoid continent edge 13");
   int avoidContinentShores15 = rmCreateClassDistanceConstraint(continentClassID, 15.0, cClassAreaEdgeDistance, "avoid continent edge 15");
   int avoidContinentShores20 = rmCreateClassDistanceConstraint(continentClassID, 20.0, cClassAreaEdgeDistance, "avoid continent edge 20");
   int forceToPondRadius = rmCreateClassMaxDistanceConstraint(pondClassID, maxDistanceFromPondMeters, cClassAreaDistance, "force anything to pond radius");
   int forceToPondMinRadius = rmCreateClassMaxDistanceConstraint(pondClassID, 9.0, cClassAreaDistance, "force anything to pond min radius");

   // Define Type Constraints.
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 25.0, true, "cliff vs buildings");
   int cliffOriginAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 30.0, true, "cliff origin vs buildings");
   int SnowmistAvoidance = rmCreateTypeDistanceConstraint(cUnitTypeVFXSnowDriftPlain, 18.0, true, "snowmist vs snowmist");
   int SnowmistAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 30.0, true, "snowmist vs building");
   int shoreTreeAvoidance = rmCreateTypeDistanceConstraint(cUnitTypeTreePineBuddhistSnow, 30.0, true, "shore tree vs shore tree");

   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0, "reed vs land");
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0, "reed near land");

   int forceToShores = rmCreateWaterMaxDistanceConstraint(true, 3.0, "force near shores");
   int forceTreeToShores = rmCreateWaterMaxDistanceConstraint(true, 4.0, "force tree near shores");

   // Define Overrides.
   vDefaultRelicAvoidWater = vDefaultAvoidWater4;

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 1.0, 0.05, 2, 0.5);

   // Player base areas.
   float playerBaseAreaSize = rmRadiusToAreaFraction(46.0);
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int playerBaseAreaID = rmAreaCreate("player base area " + p);
      rmAreaSetLocPlayer(playerBaseAreaID, p);
      rmAreaSetSize(playerBaseAreaID, playerBaseAreaSize);
      rmAreaSetMix(playerBaseAreaID, baseMixID);
      rmAreaSetCoherence(playerBaseAreaID, 1.0);
      rmAreaSetHeight(playerBaseAreaID, 0.5);
      rmAreaAddHeightBlend(playerBaseAreaID, cBlendAll, cFilter5x5Gaussian, 2);
      rmAreaAddToClass(playerBaseAreaID, playerAreaClassID);
   }  
   
   rmAreaBuildAll();

   // Continent.
   int continentID = rmAreaCreate("continent");
   rmAreaSetMix(continentID, baseMixID);
   rmAreaSetSize(continentID, continentFraction);
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaAddTerrainLayer(continentID, cTerrainJapaneseShore1, 0, 0.7);
   rmAreaAddTerrainLayer(continentID, cTerrainJapaneseSnowRocks2, 1, 2);
   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 2.5, 0.05, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0);
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 20.0);
   rmAreaSetHeight(continentID, 5.25);
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 10, 10);
   rmAreaSetCoherence(continentID, 0.45);
   rmAreaSetEdgeSmoothDistance(continentID, 10);
   rmAreaAddConstraint(continentID, createSymmetricBoxConstraint(0.075), 0.0, 7.0);
   rmAreaAddToClass(continentID, continentClassID);
   rmAreaBuild(continentID);

   // Ponds
   float pondMinSize = rmTilesToAreaFraction(90);
   float pondMaxSize = rmTilesToAreaFraction(95);

   int numPodsPerPlayer = (gameIs1v1()) ? 8 * getMapAreaSizeFactor() : 6 * getMapAreaSizeFactor();

   float pondPaintedAreaAvoidance = 35.0;
   float pondOriginAvoidance = 55.0;
   float pondMinPlayerDistance = 50.0;
   float pondMaxPlayerDistance = -1.0;

   // ↑ All of this is expressed in floating meters.
   
   int pondID = rmAreaDefCreate("pond def");
   rmAreaDefSetWaterType(pondID, mapWaterType);
   rmAreaDefSetWaterHeightBlend(pondID, cFilter3x3Gaussian, 25.0, 10);
   rmAreaDefSetSizeRange(pondID, pondMinSize, pondMaxSize);
   rmAreaDefSetCoherence(pondID, 0.5);
   rmAreaDefSetAvoidSelfDistance(pondID, pondPaintedAreaAvoidance);
   rmAreaDefAddConstraint(pondID, avoidContinent);
   rmAreaDefAddConstraint(pondID, avoidContinentShores13, 0.5);
   rmAreaDefAddOriginConstraint(pondID, createSymmetricBoxConstraint(rmXTileIndexToFraction(3), rmXTileIndexToFraction(3)));
   rmAreaDefAddOriginConstraint(pondID, avoidContinentShores15, 3.5);
   rmAreaDefAddToClass(pondID, pondClassID);
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(pondID, numPodsPerPlayer, pondMinPlayerDistance, pondMaxPlayerDistance, pondOriginAvoidance);
   }
   else
   {
      addAreaLocsPerPlayer(pondID, numPodsPerPlayer, pondMinPlayerDistance, pondMaxPlayerDistance, pondOriginAvoidance);
   }

   // Place the locs.
   bool pondLocsBool = runLocGen("pond locs", true);

   // Get the number of areas created.
   int numPonds = rmLocGenGetNumberLocs();
   
   if(pondLocsBool == true)
   {
      // Generate LocGen Paths.
      generateLocGenPaths();

      // Build but don't paint yet.
      rmLocGenApply(true, false);

      // Create a layer around the pond.
      for(int i = 0; i < numPonds; i++)
      {
         int pondAuxID = rmAreaDefGetCreatedArea(pondID, i);
         vector pondLoc = rmAreaGetLoc(pondAuxID);

         int pondLayerID = rmAreaCreate("pond layer" + i);
         rmAreaSetSize(pondLayerID, 1.0);
         rmAreaSetLoc(pondLayerID, pondLoc);
         rmAreaAddTerrainLayer(pondLayerID, cTerrainJapaneseShore1, 0);
         rmAreaAddTerrainLayer(pondLayerID, cTerrainJapaneseSnowGrass1, 1, 2);
         rmAreaAddTerrainLayer(pondLayerID, cTerrainJapaneseSnowRocks1, 3, 5);
         rmAreaSetTerrainType(pondLayerID, cTerrainJapaneseSnowRocks2);
         rmAreaSetEdgePerturbDistance(pondLayerID, -0.5, 1.5, false);
         rmAreaAddConstraint(pondLayerID, rmCreateAreaMaxDistanceConstraint(pondAuxID, maxDistanceFromPondMeters));
         rmAreaAddConstraint(pondLayerID, avoidContinent);
         rmAreaBuild(pondLayerID);

      }

      // Since there's nothing else to paint, paint them all at once.
      rmAreaPaintAll();

   }

   // Finally, reset LocGen.
   resetLocGen();

   // Fish definition.
   int fishID = rmObjectDefCreate("fish");
   rmObjectDefAddItem(fishID, cUnitTypeSalmon, 1);

   // Fish Placement.
   int numFish = 2; // TODO: 3 Could be better?
   for(int i = 0; i < numPonds; i++)
   {
      // Pond stuff.
      int pondAuxID = rmAreaDefGetCreatedArea(pondID, i);
      vector pondLoc = rmAreaGetLoc(pondAuxID);

      // Place fish on a circumference. 
      placeObjectDefInCircle(fishID, 0, numFish, 2.8, randRadian(), 0.0, 0.0, pondLoc);

   }

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
   rmObjectDefAddConstraint(firstSettlementID, forceToContinent);
   rmObjectDefAddConstraint(firstSettlementID, avoidContinentShores13);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, forceToContinent);
   rmObjectDefAddConstraint(secondSettlementID, avoidContinentShores13);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 65.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 65.0, 90.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      // Randomize inside/outside.
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 65.0, 110.0, cFarSettlementDist, cBiasAggressive | allyBias);
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
      rmObjectDefAddConstraint(bonusSettlementID, forceToContinent);
      rmObjectDefAddConstraint(bonusSettlementID, avoidContinentShores13);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   // Disable TOB conversion or they might be floating in the air due to blending after painting.
   rmSetTOBConversion(false);

   // Continent Cliffs.
   float continentCliffPaintedAreaAvoidance = 45.0;
   float continentCliffOriginAvoidance = 60.0;
   float continentCliffMinPlayerDistance = 40.0;
   float continentCliffMaxPlayerDistance = -1.0;

   // ↑ All of this is expressed in floating meters.

   int numContinentCliffsPerPlayer = (gameIs1v1()) ? 2 * getMapAreaSizeFactor() : 3 * getMapAreaSizeFactor();

   float cliffMinSize = rmTilesToAreaFraction(15);
   float cliffMaxSize = rmTilesToAreaFraction(18);

   int continentCliffDefID = rmAreaDefCreate("continent cliff");
   rmAreaDefSetCliffType(continentCliffDefID, mapCliffType);
   rmAreaDefSetCliffSideRadius(continentCliffDefID, 1, 2);
   rmAreaDefSetCliffEmbellishmentDensity(continentCliffDefID, 0.35);
   rmAreaDefSetCliffPaintInsideAsSide(continentCliffDefID, true);
   rmAreaDefSetSizeRange(continentCliffDefID, cliffMinSize, cliffMaxSize);
   rmAreaDefSetAvoidSelfDistance(continentCliffDefID, continentCliffPaintedAreaAvoidance);
   rmAreaDefSetHeightNoise(continentCliffDefID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(continentCliffDefID, 1.0);
   rmAreaDefAddHeightBlend(continentCliffDefID, cBlendEdge, cFilter3x3Gaussian, 2);    
   rmAreaDefSetHeightRelative(continentCliffDefID, 4.0);
   rmAreaDefAddConstraint(continentCliffDefID, forceToContinent);
   rmAreaDefAddConstraint(continentCliffDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(continentCliffDefID, avoidContinentShores15);
   rmAreaDefAddConstraint(continentCliffDefID, cliffAvoidBuildings);
   rmAreaDefAddConstraint(continentCliffDefID, vDefaultAvoidKotH);
   rmAreaDefAddOriginConstraint(continentCliffDefID, cliffOriginAvoidBuildings);
   rmAreaDefAddOriginConstraint(continentCliffDefID, avoidContinentShores20);
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(continentCliffDefID, numContinentCliffsPerPlayer, continentCliffMinPlayerDistance, 
                                    continentCliffMaxPlayerDistance, continentCliffOriginAvoidance, cBiasVeryAggressive);
   }
   else
   {
      addAreaLocsPerPlayer(continentCliffDefID, numContinentCliffsPerPlayer, continentCliffMinPlayerDistance, 
                           continentCliffMaxPlayerDistance, continentCliffOriginAvoidance, cBiasVeryAggressive);
   }
   
   generateLocs("continent cliffs locs");

   // Ice Cliffs.
   int numIceCliffsPerPlayer = 6 * getMapAreaSizeFactor();

   int iceCliffOriginAvoidEdge = createSymmetricBoxConstraint(rmXTileIndexToFraction(3.5), rmXTileIndexToFraction(3.5));

   float iceCliffPaintedAreaAvoidance = 40.0;
   float iceCliffOriginAvoidance = 48.0;
   float iceCliffMinPlayerDistance = 30.0;
   float iceCliffMaxPlayerDistance = -1.0;
   int iceCliffDefID = rmAreaDefCreate("ice cliff");
   rmAreaDefSetCliffType(iceCliffDefID, mapCliffType);
   rmAreaDefSetCliffSideRadius(iceCliffDefID, 1, 2);
   rmAreaDefSetCliffEmbellishmentDensity(iceCliffDefID, 0.35);
   rmAreaDefSetCliffPaintInsideAsSide(iceCliffDefID, true);
   /*
   rmAreaDefSetCliffLayerPaint(iceCliffDefID, cCliffLayerOuterSideClose, false);
   rmAreaDefSetCliffLayerPaint(iceCliffDefID, cCliffLayerOuterSideFar, false);
*/
   rmAreaDefAddCliffOuterLayerConstraint(iceCliffDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce1, 1.0));
   rmAreaDefAddCliffOuterLayerConstraint(iceCliffDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce2, 1.0));
   rmAreaDefAddCliffOuterLayerConstraint(iceCliffDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce3, 1.0));
   rmAreaDefSetSizeRange(iceCliffDefID, cliffMinSize * 1.35, cliffMaxSize * 1.35);
   rmAreaDefSetAvoidSelfDistance(iceCliffDefID, iceCliffPaintedAreaAvoidance);
   rmAreaDefSetHeightNoise(iceCliffDefID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(iceCliffDefID, 1.0);
   rmAreaDefAddHeightBlend(iceCliffDefID, cBlendEdge, cFilter3x3Gaussian, 2);    
   rmAreaDefSetHeightRelative(iceCliffDefID, 7.0);
   rmAreaDefAddConstraint(iceCliffDefID, avoidContinent);
   rmAreaDefAddConstraint(iceCliffDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(iceCliffDefID, avoidContinentShores10);
   rmAreaDefAddConstraint(iceCliffDefID, vDefaultAvoidWater10);
   rmAreaDefAddOriginConstraint(iceCliffDefID, avoidContinentShores15);
   rmAreaDefAddOriginConstraint(iceCliffDefID, vDefaultAvoidWater16);
   rmAreaDefAddOriginConstraint(iceCliffDefID, iceCliffOriginAvoidEdge);
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(iceCliffDefID, numIceCliffsPerPlayer, iceCliffMinPlayerDistance, iceCliffMaxPlayerDistance, 
                                    iceCliffOriginAvoidance);
   }
   else
   {
      addAreaLocsPerPlayer(iceCliffDefID, numIceCliffsPerPlayer, iceCliffMinPlayerDistance, iceCliffMaxPlayerDistance, 
                           iceCliffOriginAvoidance);
   }
   
   generateLocs("ice cliffs locs");

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
   rmObjectDefAddConstraint(startingGoldID, forceToContinent);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   rmObjectDefAddItem(startingHuntID, cUnitTypeSerow, xsRandInt(5, 6), 2.0);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   rmObjectDefAddConstraint(startingHuntID, forceToContinent);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 6), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, forceToContinent);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");

   int chickenNum = xsRandInt(5, 6);

   for(int i = 0; i < chickenNum; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, forceToContinent);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, mapHerdType, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(startingHerdID, forceToContinent);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Forest.
   float avoidForestMeters = 27.0;
   vDefaultForestAvoidAll = vDefaultAvoidAll8; // A little more tolerance.
   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(65), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, forceToContinent);
   rmAreaDefAddConstraint(forestDefID, avoidContinentShores3);
   rmAreaDefAddOriginConstraint(forestDefID, avoidContinentShores10, 2.0);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidAll10);

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
   float avoidGoldMeters = 55.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, forceToContinent);
   rmObjectDefAddConstraint(closeGoldID, avoidContinentShores5);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward);
      addObjectLocsPerPlayer(closeGoldID, false, 1, 60.0, 80.0, avoidGoldMeters, cBiasForward);
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
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, forceToContinent);
   rmObjectDefAddConstraint(bonusGoldID, avoidContinentShores10);
   addObjectDefPlayerLocConstraint(bonusGoldID, 60.0);

   addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 45.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeSerow, xsRandInt(8, 9), 2.0);
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeSnowMonkey, xsRandInt(8, 11), 2.0);
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(closeHuntID, forceToContinent);
   rmObjectDefAddConstraint(closeHuntID, avoidContinentShores10);
   rmObjectDefAddConstraint(closeHuntID, createTownCenterConstraint(60.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 90.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(3, 6));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, forceToContinent);
   rmObjectDefAddConstraint(bonusHuntID, avoidContinentShores10);
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
   float bonusHunt2Float = xsRandFloat(0.0, 1.0);
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2 ");
   if(bonusHunt2Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElk, xsRandInt(4, 7));
   }
   else if(bonusHunt2Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeSnowMonkey, xsRandInt(5, 8));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeSerow, xsRandInt(4, 6));
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHunt2ID, forceToContinent);
   rmObjectDefAddConstraint(bonusHunt2ID, avoidContinentShores10);
   rmObjectDefAddConstraint(bonusHunt2ID, createTownCenterConstraint(75.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 75.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 75.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(8, 9));
      }
      else if(largeMapHuntFloat < 2.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeSerow, xsRandInt(5, 7));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(0, 2));
      }
      else if(largeMapHuntFloat < 3.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(4, 5));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeSnowMonkey, xsRandInt(8, 12));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, forceToContinent);
      rmObjectDefAddConstraint(largeMapHuntID, avoidContinentShores10);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 55.0;

   int berriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(8, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, forceToContinent);
   rmObjectDefAddConstraint(berriesID, avoidContinentShores15);
   addObjectDefPlayerLocConstraint(berriesID, 65.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 65.0, 120.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 65.0, -1.0, avoidBerriesMeters);
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
   rmObjectDefAddConstraint(closeHerdID, forceToContinent);
   rmObjectDefAddConstraint(closeHerdID, avoidContinentShores10);
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
   rmObjectDefAddConstraint(bonusHerdID, avoidContinentShores10);
   addObjectDefPlayerLocConstraint(bonusHerdID, 55.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 2 * getMapAreaSizeFactor(), 55.0, -1.0, avoidHerdMeters);

   int pondHerdID = rmObjectDefCreate("pond bonus herd");
   rmObjectDefAddItem(pondHerdID, mapHerdType, 1);
   rmObjectDefAddConstraint(pondHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(pondHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(pondHerdID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(pondHerdID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(pondHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(pondHerdID, forceToPondMinRadius);
   rmObjectDefAddConstraint(pondHerdID, avoidContinentShores10);
   addObjectDefPlayerLocConstraint(pondHerdID, 55.0);

   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(pondHerdID, false, 4 * getMapAreaSizeFactor(), 55.0, -1.0, avoidHerdMeters);
   }
   else
   {
      addObjectLocsPerPlayer(pondHerdID, false, 4 * getMapAreaSizeFactor(), 55.0, -1.0, avoidHerdMeters);
   }
   
   generateLocs("herd locs");

   // Predators
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
   rmObjectDefAddConstraint(farPredatorID, avoidContinentShores10);
   addObjectDefPlayerLocConstraint(farPredatorID, 75.0);
   addObjectLocsPerPlayer(farPredatorID, false, 1 * getMapAreaSizeFactor(), 75.0, -1.0, avoidPredatorMeters);

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
   rmObjectDefAddConstraint(relicID, avoidContinent);
   rmObjectDefAddConstraint(relicID, avoidContinentShores20);
   rmObjectDefAddConstraint(relicID, forceToPondMinRadius);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 3 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   rmAreaDefAddOriginConstraint(forestDefID, avoidContinentShores15);

   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(40.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(50.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 6 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineBuddhistSnow, 3, 4);

   rmSetProgress(0.9);  

   // Embellishment.

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainJapaneseSnowRocks2, cTerrainJapaneseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainJapaneseSnowRocks2, cTerrainJapaneseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainJapaneseSnowRocks2, cTerrainJapaneseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainJapaneseSnowGrass2, cTerrainJapaneseSnowGrass1, 9.0);
   buildAreaUnderObjectDef(berriesID, cTerrainJapaneseSnowGrass2, cTerrainJapaneseSnowGrass1, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockJapaneseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 60 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockJapaneseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 60 * cNumberPlayers * getMapAreaSizeFactor());

   int pondRockTinyID = rmObjectDefCreate("pond rock tiny");
   rmObjectDefAddItem(pondRockTinyID, cUnitTypeRockJapaneseTiny, 1);
   rmObjectDefAddConstraint(pondRockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(pondRockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(pondRockTinyID, forceToPondRadius);
   rmObjectDefPlaceAnywhere(pondRockTinyID, 0, 90 * cNumberPlayers * getMapAreaSizeFactor());

   int pondRockSmallID = rmObjectDefCreate("rock rock small");
   rmObjectDefAddItem(pondRockSmallID, cUnitTypeRockJapaneseSmall, 1);
   rmObjectDefAddConstraint(pondRockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(pondRockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(pondRockSmallID, forceToPondRadius);
   rmObjectDefPlaceAnywhere(pondRockSmallID, 0, 90 * cNumberPlayers * getMapAreaSizeFactor());

   // Road Avoidance
   int avoidJapaneseRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainJapaneseRoad1, 5.0);
   int avoidJapaneseRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainJapaneseRoad2, 5.0);
   int avoidJapaneseRoadSnow1 = rmCreateTerrainTypeDistanceConstraint(cTerrainJapaneseRoadSnow1, 5.0);
   int avoidJapaneseRoadSnow2 = rmCreateTerrainTypeDistanceConstraint(cTerrainJapaneseRoadSnow2, 5.0);

   // Ice Avoidance.
   int avoidIce1 = rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce1, 1.0);
   int avoidIce2 = rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce2, 1.0);
   int avoidIce3 = rmCreateTerrainTypeDistanceConstraint(cTerrainDefaultIce3, 1.0);
   int avoidShore = rmCreateTerrainTypeDistanceConstraint(cTerrainJapaneseShore1, 1.0);

   // Random Tree - Pine Buddhist Snow.
   int randomTreePineSnowID = rmObjectDefCreate("random tree pine buddhist snow");
   rmObjectDefAddItem(randomTreePineSnowID, cUnitTypeTreePineBuddhistSnow, 1);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePineSnowID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidJapaneseRoad1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidJapaneseRoad2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidJapaneseRoadSnow1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidJapaneseRoadSnow2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidIce1);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidIce2);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidIce3);
   rmObjectDefAddConstraint(randomTreePineSnowID, avoidShore);
   rmObjectDefPlaceAnywhere(randomTreePineSnowID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 25;
      int plantsGroupDensity = xsRandInt(12, 15);
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
      rmObjectDefAddConstraint(plantTypeDef, avoidJapaneseRoad1);
      rmObjectDefAddConstraint(plantTypeDef, avoidJapaneseRoad2);
      rmObjectDefAddConstraint(plantTypeDef, avoidJapaneseRoadSnow1);
      rmObjectDefAddConstraint(plantTypeDef, avoidJapaneseRoadSnow2);
      rmObjectDefAddConstraint(plantTypeDef, avoidIce1);
      rmObjectDefAddConstraint(plantTypeDef, avoidIce2);
      rmObjectDefAddConstraint(plantTypeDef, avoidIce3);
      rmObjectDefAddConstraint(plantTypeDef, avoidShore);
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
   rmObjectDefAddConstraint(logID, avoidJapaneseRoad1);
   rmObjectDefAddConstraint(logID, avoidJapaneseRoad2);
   rmObjectDefAddConstraint(logID, avoidJapaneseRoadSnow1);
   rmObjectDefAddConstraint(logID, avoidJapaneseRoadSnow2);
   rmObjectDefAddConstraint(logID, avoidIce1);
   rmObjectDefAddConstraint(logID, avoidIce2);
   rmObjectDefAddConstraint(logID, avoidIce3);
   rmObjectDefAddConstraint(logID, avoidShore);
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int logGroupID = rmObjectDefCreate("log group");
   rmObjectDefAddItem(logGroupID, cUnitTypeRottingLog, 2, 2.0);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidImpassableLand10);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidEdge);   
   rmObjectDefAddConstraint(logGroupID, avoidJapaneseRoad1);
   rmObjectDefAddConstraint(logGroupID, avoidJapaneseRoad2);
   rmObjectDefAddConstraint(logGroupID, avoidJapaneseRoadSnow1);
   rmObjectDefAddConstraint(logGroupID, avoidJapaneseRoadSnow2);
   rmObjectDefAddConstraint(logGroupID, avoidIce1);
   rmObjectDefAddConstraint(logGroupID, avoidIce2);
   rmObjectDefAddConstraint(logGroupID, avoidIce3);
   rmObjectDefAddConstraint(logGroupID, avoidShore);
   rmObjectDefPlaceAnywhere(logGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 18 * cNumberPlayers * getMapAreaSizeFactor());

   int waterReedGroupID = rmObjectDefCreate("reed group");
   rmObjectDefAddItemRange(waterReedGroupID, cUnitTypeWaterReeds, 2, 3);
   rmObjectDefAddConstraint(waterReedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedGroupID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedGroupID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedGroupID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Shore Plants.

   // Shore Bush.
   int shoreBushID = rmObjectDefCreate("shore bush");
   rmObjectDefAddItem(shoreBushID, cUnitTypePlantSnowBush, 1);
   rmObjectDefAddConstraint(shoreBushID, forceToShores);
   rmObjectDefAddConstraint(shoreBushID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(shoreBushID, 0, 5 * numPonds * getMapAreaSizeFactor());

   // Shore Shrub.
   int shoreShrubID = rmObjectDefCreate("shore shrub");
   rmObjectDefAddItem(shoreShrubID, cUnitTypePlantSnowShrub, 1);
   rmObjectDefAddConstraint(shoreShrubID, forceToShores);
   rmObjectDefAddConstraint(shoreShrubID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(shoreShrubID, 0, 5 * numPonds * getMapAreaSizeFactor());

   // Shore Weeds.
   int shoreWeedsID = rmObjectDefCreate("shore weeds");
   rmObjectDefAddItem(shoreWeedsID, cUnitTypePlantSnowWeeds, 1);
   rmObjectDefAddConstraint(shoreWeedsID, forceToShores);
   rmObjectDefAddConstraint(shoreWeedsID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(shoreWeedsID, 0, 5 * numPonds * getMapAreaSizeFactor());

   // Shore Grass.
   int shoreGrassID = rmObjectDefCreate("shore grass");
   rmObjectDefAddItem(shoreGrassID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(shoreGrassID, forceToShores);
   rmObjectDefAddConstraint(shoreGrassID, vDefaultAvoidEdge, cObjectConstraintBufferNone, 2.0);
   rmObjectDefPlaceAnywhere(shoreGrassID, 0, 2 * numPonds * getMapAreaSizeFactor());

   // Shore Tree.
   int shoreTreeID = rmObjectDefCreate("shore tree");
   rmObjectDefAddItem(shoreTreeID, cUnitTypeTreePineBuddhistSnow, 1);
   rmObjectDefAddConstraint(shoreTreeID, forceTreeToShores);
   rmObjectDefAddConstraint(shoreTreeID, vDefaultAvoidEdge, cObjectConstraintBufferNone, 2.0);
   // Ensure sufficient spacing between trees to prevent obstruction of building placement.
   rmObjectDefAddConstraint(shoreTreeID, shoreTreeAvoidance);
   rmObjectDefPlaceAnywhere(shoreTreeID, 0, 3 * numPonds * getMapAreaSizeFactor());

   // Seaweeds near from the shores.
   int shoreSeaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(shoreSeaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(shoreSeaweedID, rmCreateMaxWaterDepthConstraint(2.35));
   rmObjectDefPlaceAnywhere(shoreSeaweedID, 0, 30 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Snowmist.
   int snowmistID = rmObjectDefCreate("snowmist ");
   rmObjectDefAddItem(snowmistID, cUnitTypeVFXSnowDriftPlain, 1);
   rmObjectDefAddConstraint(snowmistID, vDefaultAvoidCollideable8);
   rmObjectDefAddConstraint(snowmistID, SnowmistAvoidBuildings);
   rmObjectDefAddConstraint(snowmistID, SnowmistAvoidance);
   rmObjectDefAddConstraint(snowmistID, vDefaultAvoidWater10);
   rmObjectDefPlaceAnywhere(snowmistID, 0, 6 * cNumberPlayers * getMapAreaSizeFactor());

   // Light snowfall.
   rmTriggerAddScriptLine("rule _snow");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trRenderSnow(1.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
