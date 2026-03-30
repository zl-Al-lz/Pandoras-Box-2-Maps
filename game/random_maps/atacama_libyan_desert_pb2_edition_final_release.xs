include "lib2/rm_core.xs";

/*
** Atacama
** Author: AL (AoM DE XS CODE)
** Based on "Atacama" by AoE IV Team
** Date: March 30, 2026 (Final PB2 revision)
*/

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.10, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 2.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt3, 1.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirtRocks1, 1.7);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirtRocks2, 0.5);

   // Biome Assets.
   int mapForestType = cForestEgyptPalmMix;
   int mapWaterType = cWaterEgyptWateringHole;

   // Define Default Tree Type.
   int defaultTreeType = 0;
   if(xsRandBool(0.5) == true)
   {
      defaultTreeType = cUnitTypeTreePalm;
   }
   else
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

   rmSetDefaultTreeType(defaultTreeType);

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = cUnitTypeGoat;

   // Water overrides.
   rmWaterTypeAddShoreLayer(mapWaterType, cTerrainEgyptShore1);

   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainEgyptGrassRocks1, 0.0);
   rmWaterTypeAddBeachLayer(mapWaterType, cTerrainEgyptGrassRocks2, 1.0);

   // Map size and terrain init.
   int axisSize = 128;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnCircle(0.35);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetFott14);

   // Define Classes.
   int pondClassID = rmClassCreate("pond class");
   int oaseClassID = rmClassCreate("oase class");

   // Define Classes constraints.
   int forceToShores = rmCreateClassMaxDistanceConstraint(pondClassID, 1.5, cClassAreaEdgeDistance);
   int forceTreeToShores = rmCreateClassMaxDistanceConstraint(pondClassID, 1.6, cClassAreaEdgeDistance);

   int forceToOases = rmCreateClassMaxDistanceConstraint(oaseClassID, 1.0, cClassAreaDistance, "force plants near oases");
   int avoidOaseEdges = rmCreateClassDistanceConstraint(oaseClassID, 3.5, cClassAreaEdgeDistance, "plants vs oase edges");

   // Define type constraints.
   int papyrusAvoidLand = rmCreateWaterDistanceConstraint(false, 4.0, "papyrus vs land");
   int forcePapyrusNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "force papyrus near land");

   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 3.0, "lily vs land");
   int forceLilyNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0, "force lily near land");

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 3.0, 0.05, 2, 0.5);

   // Center
   float centerSize = 0.147;

   int centerID = rmAreaCreate("center");
   rmAreaSetLoc(centerID, cCenterLoc);
   rmAreaSetSize(centerID, centerSize);
   rmAreaSetCoherence(centerID, 0.35);
   rmAreaAddConstraint(centerID, createPlayerLocDistanceConstraint(45.0));
   rmAreaBuild(centerID);

   // Center Constraints.
   int avoidCenter5 = rmCreateAreaDistanceConstraint(centerID, 5.0);
   int avoidCenter10 = rmCreateAreaDistanceConstraint(centerID, 10.0);
   int avoidCenter15 = rmCreateAreaDistanceConstraint(centerID, 15.0);
   int avoidCenter20 = rmCreateAreaDistanceConstraint(centerID, 20.0);
   int avoidCenterEdge = rmCreateAreaEdgeDistanceConstraint(centerID, 1.0);
   int avoidCenterEdge5 = rmCreateAreaEdgeDistanceConstraint(centerID, 5.0);
   int avoidCenterEdge10 = rmCreateAreaEdgeDistanceConstraint(centerID, 10.0);

   // KotH.
   placeKotHObjects();

   // Center Forest.
   float avoidCenterForestMeters = 12.0;

   int centerForestDefID = rmAreaDefCreate("center forest");
   rmAreaDefSetParent(centerForestDefID, centerID);
   rmAreaDefSetSizeRange(centerForestDefID, rmTilesToAreaFraction(35), rmTilesToAreaFraction(40));
   rmAreaDefSetForestType(centerForestDefID, mapForestType);
   rmAreaDefSetEdgePerturbDistance(centerForestDefID, -4.0, 4.0);
   rmAreaDefSetAvoidSelfDistance(centerForestDefID, avoidCenterForestMeters);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(centerForestDefID, avoidCenterEdge);
   buildAreaDefInTeamAreas(centerForestDefID, 9 * getMapAreaSizeFactor());

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
   rmObjectDefAddConstraint(firstSettlementID, avoidCenter10);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, avoidCenter10);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, 
                                   cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | getRandomAllyBias());
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
      rmObjectDefAddConstraint(bonusSettlementID, avoidCenter15);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 90.0);
   }

   generateLocs("settlement locs");

   // Oase Definition.
   int oaseDefID = rmAreaDefCreate("oase def");
   rmAreaDefSetSize(oaseDefID, 1.0);
   rmAreaDefSetTerrainType(oaseDefID, cTerrainEgyptGrass1);
   rmAreaDefAddTerrainLayer(oaseDefID, cTerrainEgyptGrassDirt3, 0, 1);
   rmAreaDefAddTerrainLayer(oaseDefID, cTerrainEgyptGrassDirt2, 1, 2);
   rmAreaDefAddTerrainLayer(oaseDefID, cTerrainEgyptGrassDirt1, 2, 3);
   rmAreaDefAddToClass(oaseDefID, oaseClassID);

   // Ponds
   int pondsPerPlayer = 3 * getMapAreaSizeFactor();
   float pondMinSize = rmTilesToAreaFraction(75);
   float pondMaxSize = rmTilesToAreaFraction(85);

   float pondOriginAvoidance = 55.0;
   float pondAvoidance = 40.0;
   float pondOriginAvoidPlayerLoc = 50.0;
   int pondAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0, true, "pond vs buildings");

   int pondID = rmAreaDefCreate("pond");
   rmAreaDefSetWaterType(pondID, mapWaterType);
   rmAreaDefSetWaterHeightBlend(pondID, cFilter5x5Gaussian, 25.0, 10);
   rmAreaDefSetSizeRange(pondID, pondMinSize, pondMaxSize);
   rmAreaDefSetAvoidSelfDistance(pondID, pondAvoidance);
   rmAreaDefSetCoherence(pondID, 0.5);
   rmAreaDefAddConstraint(pondID, pondAvoidBuildings);
   rmAreaDefAddConstraint(pondID, avoidCenter15);
   rmAreaDefAddOriginConstraint(pondID, createSymmetricBoxConstraint(rmXTileIndexToFraction(8), rmXTileIndexToFraction(8)));
   rmAreaDefAddOriginConstraint(pondID, avoidCenter15, 10.0);
   rmAreaDefAddOriginConstraint(pondID, pondAvoidBuildings, 8.0);
   rmAreaDefAddToClass(pondID, pondClassID);
   if(gameIs1v1() == true)
   {  // TODO: Consider more radial and angular variance.
      addSimAreaLocsPerPlayerPair(pondID, pondsPerPlayer, pondOriginAvoidPlayerLoc, -1.0, pondOriginAvoidance);
   }
   else
   {
      addAreaLocsPerPlayer(pondID, pondsPerPlayer, pondOriginAvoidPlayerLoc, -1.0, pondOriginAvoidance);
   }

   // Generate the locs, but do not build the areas yet.
   bool pondSuccessful = generateLocs("pond locs", true, false, true, false);

   // Get the total of ponds.
   int numPonds = rmLocGenGetNumberLocs();

   if(pondSuccessful)
   {
      // Build the areas from here, but don't paint them yet.
      rmLocGenApply(true, false);

      // Iterate each pond, to place a layer of grass before painting them.
      for(int i = 0; i < numPonds; i++)
      {
         int pondTempID = rmLocGenGetLocArea(i);

         int oaseID = rmAreaDefCreateArea(oaseDefID);
         rmAreaSetLoc(oaseID, rmAreaGetLoc(pondTempID));
         rmAreaAddConstraint(oaseID, rmCreateAreaMaxDistanceConstraint(pondTempID, 13.0));
         rmAreaBuild(oaseID);

         // Paint the pond.
         rmAreaPaint(pondTempID);
      }

      // Next, paint all the remaining areas, i.e., the ponds.
      rmAreaPaintAll();

      // Place the hippos around the ponds.
      for(int i = 0; i < numPonds; i++)
      {

         int pondTempID = rmLocGenGetLocArea(i);

         // Pond Hunt.
         int pondHuntDefID = rmObjectDefCreate("pond hunt def" + i);
         rmObjectDefAddItem(pondHuntDefID, cUnitTypeHippopotamus, 1);
         rmObjectDefAddConstraint(pondHuntDefID, vDefaultAvoidWater);
         rmObjectDefAddConstraint(pondHuntDefID, rmCreateTypeDistanceConstraint(cUnitTypeHippopotamus, 5.0));
         rmObjectDefAddConstraint(pondHuntDefID, rmCreateAreaMaxDistanceConstraint(pondTempID, 3.0));
         rmObjectDefPlaceAtArea(pondHuntDefID, 0, pondTempID, 10.0, 15.0, 2);
      }

      // Finally, we restart LocGen.
      resetLocGen();
   }
   
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
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, 
                           cBiasAggressive);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(5, 7));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(5, 7));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(4, 6));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 6), cBerryClusterRadius);
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
   float avoidForestMeters = 45.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(20), rmTilesToAreaFraction(25));
   rmAreaDefSetForestType(forestDefID, mapForestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, avoidCenter10);
   rmAreaDefAddOriginConstraint(forestDefID, createSymmetricBoxConstraint(rmXTileIndexToFraction(4), rmXTileIndexToFraction(4)));
   rmAreaDefAddOriginConstraint(forestDefID, avoidCenter15, 3.0);
   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 2, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 7.0);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 2, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters + 7.0);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, avoidCenter10);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 2, 50.0, 70.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 2, 50.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidCenter5);
   addObjectDefPlayerLocConstraint(bonusGoldID, 75.0);

   if(gameIs1v1())
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 75.0, -1.0, avoidGoldMeters, cBiasNone,
                                    cInAreaDefault, cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 75.0, -1.0, avoidGoldMeters);
   }
   
   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   float closeHuntFloat = xsRandFloat(0.0, 1.0);
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(closeHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   else if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(3, 5));
      rmObjectDefAddItem(closeHuntID, cUnitTypeGiraffe, xsRandInt(0, 1));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeZebra, xsRandInt(3, 5));
      rmObjectDefAddItem(closeHuntID, cUnitTypeGiraffe, xsRandInt(0, 1));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidCenter5);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 60.0, 80.0, avoidHuntMeters);
   }

   // Far hunt.
   int farHuntID = rmObjectDefCreate("far hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeZebra, xsRandInt(3, 5));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeGazelle, xsRandInt(3, 5));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(farHuntID, avoidCenter5);
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
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElephant, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeRhinoceros, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(bonusHuntID, avoidCenter5);
   rmObjectDefAddConstraint(bonusHuntID, createTownCenterConstraint(75.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 80.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 4));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 4));
      }
      else if(largeMapHuntFloat < 2.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(3, 4));
      }
      else if(largeMapHuntFloat < 3.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 5));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 2));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, avoidCenter5);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // TODO: Can we consider berries on this map?

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
   rmObjectDefAddConstraint(closePredatorID, avoidCenter5);
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
   rmObjectDefAddConstraint(farPredatorID, avoidCenter5);
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
   rmObjectDefAddConstraint(relicID, avoidCenter10);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater16);
   rmAreaDefAddOriginConstraint(forestDefID, vDefaultAvoidWater24);

   // We don't want any global forest to cause a player to have a extra starting forest.
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(85.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 5 * getMapAreaSizeFactor());

   // Stragglers
   int numStragglers = xsRandInt(3, 4);
   int stragglerType = 0;
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      vector loc = rmGetPlayerLoc(i, 0);

      for(int j = 0; j < numStragglers; j++)
      {

         if(xsRandBool(0.5) == true)
         {
            stragglerType = cUnitTypeTreePalm;
         }
         else
         {
            stragglerType = cUnitTypeTreeSavannah;
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
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad2, 2.5);

   // Grass Avoidance.
   int avoidEgyptGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass1, 1.0);
   int avoidEgyptGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass2, 1.0);
   int avoidEgyptGrassDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt1, 1.0);
   int avoidEgyptGrassDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt2, 1.0);
   int avoidEgyptGrassDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt3, 1.0);

   // Random palms.
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

   int randomTreePalmOaseID = rmObjectDefCreate("random tree palm oase");
   rmObjectDefAddItem(randomTreePalmOaseID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreePalmOaseID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreePalmOaseID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreePalmOaseID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreePalmOaseID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreePalmOaseID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreePalmOaseID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreePalmOaseID, forceToOases);
   rmObjectDefAddConstraint(randomTreePalmOaseID, avoidOaseEdges);
   rmObjectDefPlaceAnywhere(randomTreePalmOaseID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Random Savannah trees.
   int randomTreeSavannahID = rmObjectDefCreate("random tree savannah");
   rmObjectDefAddItem(randomTreeSavannahID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeSavannahID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreeSavannahID, avoidRoad2);
   rmObjectDefPlaceAnywhere(randomTreeSavannahID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   int randomTreeSavannahOldID = rmObjectDefCreate("random tree savannah old");
   rmObjectDefAddItem(randomTreeSavannahOldID, cUnitTypeTreeSavannahOld, 1);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, avoidRoad1);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, avoidRoad2);
   rmObjectDefPlaceAnywhere(randomTreeSavannahOldID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Dead plants placement.
   for(int i = 0; i < 7; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= 22;
      int plantsGroupDensity = xsRandInt(3, 4);
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantDeadBush; plantName = "plant bush "; break; }
         case 1: { plantID = cUnitTypePlantDeadShrub; plantName = "plant shrub "; break; }
         case 2: { plantID = cUnitTypePlantDeadFern; plantName = "plant fern "; break; }
         case 3: { plantID = cUnitTypePlantDeadWeeds; plantName = "plant weeds "; break; }
         case 4: { plantID = cUnitTypePlantDeadGrass; plantName = "plant grass "; plantsDensity *= 0.65; break; }

         // Plants groups.
         case 5: { plantID = cUnitTypePlantDeadFern; plantName = "plant fern group "; plantsDensity = plantsGroupDensity; break; }
         case 6: { plantID = cUnitTypePlantDeadWeeds; plantName = "plant weeds group "; plantsDensity = plantsGroupDensity; break; }
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
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrass1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrass2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt1);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt2);
      rmObjectDefAddConstraint(plantTypeDef, avoidEgyptGrassDirt3);
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
   rmObjectDefPlaceAnywhere(logID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyGroupID = rmObjectDefCreate("lily group");
   rmObjectDefAddItemRange(waterLilyGroupID, cUnitTypeWaterLily, 2, 4);
   rmObjectDefAddConstraint(waterLilyGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyRedID = rmObjectDefCreate("lily red");
   rmObjectDefAddItem(waterLilyRedID, cUnitTypeWaterLilyRed, 1);
   rmObjectDefAddConstraint(waterLilyRedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyRedID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyRedID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyRedID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyRedGroupID = rmObjectDefCreate("lily red group");
   rmObjectDefAddItemRange(waterLilyRedGroupID, cUnitTypeWaterLilyRed, 2, 4);
   rmObjectDefAddConstraint(waterLilyRedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyRedGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyRedGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyRedGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Water plants.
   int waterPlantID = rmObjectDefCreate("water plant shores");
   rmObjectDefAddItem(waterPlantID, cUnitTypeWaterPlant, 1);
   rmObjectDefAddConstraint(waterPlantID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(waterPlantID, rmCreateMaxWaterDepthConstraint(2.6));
   rmObjectDefPlaceAnywhere(waterPlantID, 0, 10 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Papirus
   int papyrusID = rmObjectDefCreate("Papyrus");
   rmObjectDefAddItem(papyrusID, cUnitTypePapyrus, 1);
   rmObjectDefAddConstraint(papyrusID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   int papyrusGroupID = rmObjectDefCreate("Papyrus group");
   rmObjectDefAddItemRange(papyrusGroupID, cUnitTypePapyrus, 3, 5);
   rmObjectDefAddConstraint(papyrusGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusGroupID, papyrusAvoidLand);
   rmObjectDefAddConstraint(papyrusGroupID, forcePapyrusNearLand);
   rmObjectDefPlaceAnywhere(papyrusGroupID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Pond Plants.

   // Disable TOB conversion to prevent plants from floating due to the blend and depth of the ponds.
   rmSetTOBConversion(false);

   // Shore Bush.
   int shoreBushID = rmObjectDefCreate("shore bush");
   rmObjectDefAddItem(shoreBushID, cUnitTypePlantEgyptianBush, 1);
   rmObjectDefAddConstraint(shoreBushID, avoidRoad1);
   rmObjectDefAddConstraint(shoreBushID, avoidRoad2);
   rmObjectDefAddConstraint(shoreBushID, forceToShores);
   rmObjectDefPlaceAnywhere(shoreBushID, 0, 25 * numPonds);

   // Shore Shrub.
   int shoreShrubID = rmObjectDefCreate("shore shrub");
   rmObjectDefAddItem(shoreShrubID, cUnitTypePlantEgyptianShrub, 1);
   rmObjectDefAddConstraint(shoreShrubID, avoidRoad1);
   rmObjectDefAddConstraint(shoreShrubID, avoidRoad2);
   rmObjectDefAddConstraint(shoreShrubID, forceToShores);
   rmObjectDefPlaceAnywhere(shoreShrubID, 0, 25 * numPonds);

   // Shore Weeds.
   int shoreWeedsID = rmObjectDefCreate("shore weeds");
   rmObjectDefAddItem(shoreWeedsID, cUnitTypePlantEgyptianWeeds, 1);
   rmObjectDefAddConstraint(shoreWeedsID, avoidRoad1);
   rmObjectDefAddConstraint(shoreWeedsID, avoidRoad2);
   rmObjectDefAddConstraint(shoreWeedsID, forceToShores);
   rmObjectDefPlaceAnywhere(shoreWeedsID, 0, 25 * numPonds);

   // Shore Grass.
   int shoreGrassID = rmObjectDefCreate("shore grass");
   rmObjectDefAddItem(shoreGrassID, cUnitTypePlantEgyptianGrass, 1);
   rmObjectDefAddConstraint(shoreGrassID, avoidRoad1);
   rmObjectDefAddConstraint(shoreGrassID, avoidRoad2);
   rmObjectDefAddConstraint(shoreGrassID, forceToShores);
   rmObjectDefPlaceAnywhere(shoreGrassID, 0, 15 * numPonds);

   // Shore Tree palm.
   int shoreTreePalmID = rmObjectDefCreate("shore palm");
   rmObjectDefAddItem(shoreTreePalmID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(shoreTreePalmID, vDefaultTreeAvoidTree, cObjectConstraintBufferDefault, 4.0);
   rmObjectDefAddConstraint(shoreTreePalmID, forceTreeToShores);
   rmObjectDefAddConstraint(shoreTreePalmID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(shoreTreePalmID, 0, 6 * numPonds);

   // Shore Tree savannah.
   int shoreTreeSavannahID = rmObjectDefCreate("shore savannah tree");
   rmObjectDefAddItem(shoreTreeSavannahID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(shoreTreeSavannahID, vDefaultTreeAvoidTree, cObjectConstraintBufferDefault, 4.0);
   rmObjectDefAddConstraint(shoreTreeSavannahID, forceTreeToShores);
   rmObjectDefAddConstraint(shoreTreeSavannahID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(shoreTreeSavannahID, 0, 6 * numPonds);

   // Grass plants around the oases.
   for(int i = 0; i < 5; i++)
   {  
      // Plants Stuff.
      int plantID = cInvalidID;
      string plantName = cEmptyString;
      int plantsDensity= xsRandInt(7, 10);
      switch(i)
      {
         // Plants.
         case 0: { plantID = cUnitTypePlantEgyptianBush; plantName = "oase bush "; break; }
         case 1: { plantID = cUnitTypePlantEgyptianShrub; plantName = "oase shrub "; break; }
         case 2: { plantID = cUnitTypePlantEgyptianFern; plantName = "oase fern "; break; }
         case 3: { plantID = cUnitTypePlantEgyptianWeeds; plantName = "oase weeds "; break; }
         case 4: { plantID = cUnitTypePlantEgyptianGrass; plantName = "oase grass "; plantsDensity *= 0.65; break; }

      }
      
      // Plant template.
      int plantTypeDef = rmObjectDefCreate(plantName);
      if(i < 5)
      {
         rmObjectDefAddItem(plantTypeDef, plantID, 1);
      }
      rmObjectDefAddConstraint(plantTypeDef, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidImpassableLand2);
      rmObjectDefAddConstraint(plantTypeDef, vDefaultEmbellishmentAvoidWater); 
      rmObjectDefAddConstraint(plantTypeDef, forceToOases);
      rmObjectDefAddConstraint(plantTypeDef, avoidOaseEdges);
      if(i == 4)
      {
         rmObjectDefAddConstraint(plantTypeDef, vDefaultAvoidEdge);
      }

      // Plant Placement.
      rmObjectDefPlaceAnywhere(plantTypeDef, 0, plantsDensity * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Rock Underwater.
   int rockUnderWaterID = rmObjectDefCreate("rock underwater");
   rmObjectDefAddItem(rockUnderWaterID, cUnitTypeRockUnderwater, 1);
   rmObjectDefSetItemRotation(rockUnderWaterID, 0, cItemRotateFull);
   rmObjectDefAddConstraint(rockUnderWaterID, rmCreateTypeDistanceConstraint(cUnitTypeMonkeyRaft, 10.0));
   rmObjectDefAddConstraint(rockUnderWaterID, rmCreateMinWaterDepthConstraint(0.25));
   rmObjectDefAddConstraint(rockUnderWaterID, rmCreateMaxWaterDepthConstraint(2.85));
   rmObjectDefAddConstraint(rockUnderWaterID, rmCreateTypeDistanceConstraint(cUnitTypeRockUnderwater, 25.0));
   rmObjectDefPlaceAnywhere(rockUnderWaterID, 0, 2 * numPonds);

   // Sand VFX.
   int sandDriftPlainID = rmObjectDefCreate("sand drift plain");
   rmObjectDefAddItem(sandDriftPlainID, cUnitTypeVFXSandDriftPlain, 1);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidAll6);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidWater24);
   rmObjectDefAddConstraint(sandDriftPlainID, rmCreateTypeDistanceConstraint(cUnitTypeVFXSandDriftPlain, 45.0));
   rmObjectDefAddConstraint(sandDriftPlainID, rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 15.0));
   rmObjectDefPlaceAnywhere(sandDriftPlainID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
