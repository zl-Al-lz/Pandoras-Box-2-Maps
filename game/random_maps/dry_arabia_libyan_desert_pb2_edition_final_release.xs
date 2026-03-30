include "lib2/rm_core.xs";

/*
** Dry Arabia
** Author: AL (AoM DE XS CODE)
** Based on "Dry Arabia" by AoE IV Team
** Date: July 13, 2025
** Final revision: March 30, 2026
*/

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate("Libyan Desert Mix");
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.10, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 2.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt3, 1.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 1.8);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirtRocks1, 1.0);

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

   // Biome Assets.
   int mapForestType = cForestEgyptPalmMix;

   // By request, we’ll use only one shared herd for the tournament.
   float mapHerdType = (xsRandBool(0.5) == true) ? cUnitTypeGoat : cUnitTypePig;

   // Make sure that settlements and gold mines share the same type of side.
   int sharedSide = cLocSideOpposite; // No side same here.

   // Map size and terrain init.
   int axisSize = 125;
   int axisTiles = getScaledAxisTiles(axisSize);
   rmSetMapSize(axisTiles);
   rmInitializeMix(baseMixID);

   // Player placement.
   float placementRadius = (cNumberPlayers <= 4) ? xsRandFloat(0.335, 0.34) : xsRandFloat(0.335, 0.355);
   rmSetTeamSpacingModifier(xsRandFloat(0.77, 0.82));
   rmPlacePlayersOnCircle(placementRadius);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetFott11A1);

   // Define Classes.

   // Define Classes Constraints.

   // Define Type Contraints.

   // Define Overrides.
   vDefaultSettlementAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(12), rmZTilesToFraction(12));

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.05, 2, 0.5);
   
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
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 65.0, 80.0, cSettlementDist1v1, cBiasBackward,
                                    cInAreaDefault, sharedSide);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 95.0, cSettlementDist1v1, cBiasAggressive, cInAreaDefault, 
                                    sharedSide);
   }
   else
   {
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 100.0, cFarSettlementDist, cBiasAggressive | allyBias);
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
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(6, 8), 2.0);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(6, 8), 2.0);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt agressive.
   int startingHuntAgressiveID = rmObjectDefCreate("starting hunt agressive ");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntAgressiveID, cUnitTypeElephant, 1);
   }
   else
   {
      rmObjectDefAddItem(startingHuntAgressiveID, cUnitTypeRhinoceros, 2, 2.0);
   }
   rmObjectDefAddConstraint(startingHuntAgressiveID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntAgressiveID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntAgressiveID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntAgressiveID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntAgressiveID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntAgressiveID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7), 2.0);
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
   float avoidForestMeters = 32.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(90), rmTilesToAreaFraction(100));
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
      // Only one nearby mine will be completely mirrored.
      addMirroredObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward, cInAreaDefault, sharedSide);

      // The most distant possible is a semi-mirror with some radial and angular variation.
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 70.0, 80.0, avoidGoldMeters, cBiasForward, cInAreaDefault, sharedSide);
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
   
   // TODO: Consider angular constraints at the rear of the settlement.
   if(gameIs1v1())
   {
      // The bonus gold mines will be placed in a sort of semi-mirror, but with a slightly different angle and radius than 
      // those set by default in simLocs; I don't want it to be too repetitive scenario-like, but also not too unfair.

      float bonusGoldSimLocsRadiusVar = vSimLocDefaultRadiusVar * 1.27;
      float bonusGoldSimLocsAngleVar = vSimLocDefaultAngleVar * 1.37; 
      // I prioritize much more angular variety over radial variation; this is intentional.

      // Generate the locs in mirror.
      int[] locGenBonusGoldLocs = addMirroredLocsPerPlayerPair(3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters, 
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
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElephant, xsRandInt(2, 3));

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
            if(largeMapHuntFloat < 1.0 / 3.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(2, 3));
            }
            else if(largeMapHuntFloat < 2.0 / 3.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 3));
            }
            else
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, 2);
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, 1);
            }
         }
         else
         {
            if(largeMapHuntFloat < 1.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(5, 6));
            }
            else if(largeMapHuntFloat < 2.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(5, 6));
            }
            else if(largeMapHuntFloat < 3.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(4, 5));
            }
            else if(largeMapHuntFloat < 4.0 / 5.0)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 5));
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 5));
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
   rmAreaDefAddConstraint(forestDefID, createPlayerLocDistanceConstraint(45.0)); 
   rmAreaDefAddOriginConstraint(forestDefID, createPlayerLocDistanceConstraint(65.0));

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 9 * getMapAreaSizeFactor());

   // Stragglers
   int numStragglers = xsRandInt(3, 4);
   int stragglerType = 0;
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      vector loc = rmGetPlayerLoc(i, 0);

      for(int j = 0; j < numStragglers; j++)
      {

         // Straggler Rand Type:
         if(xsRandBool(0.5) == true)
         {
            stragglerType = cUnitTypeTreePalm;
         }
         else
         {
            if(xsRandBool(0.5) == true)
            {
               stragglerType = cUnitTypeTreeSavannahOld;
            }
            else
            {
               stragglerType = cUnitTypeTreeSavannah;
            }
            
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
   buildAreaUnderObjectDef(closeBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand10);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants Constraints.
   int avoidRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 2.5);
   int avoidRoad2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad2, 2.5);

   // Grass Avoidance.
   int avoidEgyptGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass1, 1.0);
   int avoidEgyptGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass2, 1.0);
   int avoidEgyptGrassDirt1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt1, 1.0);
   int avoidEgyptGrassDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt2, 1.0);
   int avoidEgyptGrassDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrassDirt3, 1.0);

   // Random trees.
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
   rmObjectDefAddItem(randomTreeSavannahOldID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeSavannahOldID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeSavannahID, vDefaultTreeAvoidImpassableLand);
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
      int plantsDensity= 20;
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

   rmSetProgress(1.0);
}
