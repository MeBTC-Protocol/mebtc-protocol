# Slither Security Analysis Report

> Slither – Static Analysis  
> Filter: `test/ | script/ | lib/`  
> Datum: 2025-03-15

INFO:Detectors:
MiningManager._computeEffForOwner(uint256,address) (src/core/MiningManager.sol#198-220) performs a multiplication on the result of a division:
	- effPowerAfter = (basePower * (10_000 - pbps)) / 10_000 (src/core/MiningManager.sol#210)
	- stakePowerBonus = (effPowerAfter * uint256(stakePowerBps)) / 10_000 (src/core/MiningManager.sol#215)
MiningManager._collectFees(address,uint256,uint16) (src/core/MiningManager.sol#400-435) performs a multiplication on the result of a division:
	- mebtcUsdc = (feeUSDC * mebtcShareBps) / 10_000 (src/core/MiningManager.sol#414)
	- mebtcAmount = (mebtcUsdc * MEBTC_UNIT) / price (src/core/MiningManager.sol#417)
MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462) performs a multiplication on the result of a division:
	- intervals = (block.timestamp - last) / CLAIM_INTERVAL (src/core/MiningManager.sol#455)
	- f = debtUSDC[id] + intervals * perIntervalFee (src/core/MiningManager.sol#458)
MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490) performs a multiplication on the result of a division:
	- intervals = (block.timestamp - last) / CLAIM_INTERVAL (src/core/MiningManager.sol#484)
	- debtUSDC[id] += intervals * perIntervalFee (src/core/MiningManager.sol#487)
MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490) performs a multiplication on the result of a division:
	- intervals = (block.timestamp - last) / CLAIM_INTERVAL (src/core/MiningManager.sol#484)
	- lastSettleTime[id] = last + intervals * CLAIM_INTERVAL (src/core/MiningManager.sol#488)
TwapOracleJoeV2.priceMebtcInUsdc() (src/core/TwapOracleJoeV2.sol#73-92) performs a multiplication on the result of a division:
	- priceAverage = (price1Cumulative - price1CumulativeLast) / elapsed (src/core/TwapOracleJoeV2.sol#85)
	- priceUsdc = (priceAverage * 10 ** MEBTC_DECIMALS) / Q112 (src/core/TwapOracleJoeV2.sol#89)
TwapOracleJoeV2.updateIfDue() (src/core/TwapOracleJoeV2.sol#94-123) performs a multiplication on the result of a division:
	- priceAverage = (price1Cumulative - price1CumulativeLast) / elapsed (src/core/TwapOracleJoeV2.sol#108)
	- priceUsdc = (priceAverage * 10 ** MEBTC_DECIMALS) / Q112 (src/core/TwapOracleJoeV2.sol#111)
TwapOracleJoeV2._currentCumulativePrices() (src/core/TwapOracleJoeV2.sol#139-155) performs a multiplication on the result of a division:
	- price0 = (uint256(reserve1) * Q112) / uint256(reserve0) (src/core/TwapOracleJoeV2.sol#150)
	- price0Cumulative += price0 * timeElapsed (src/core/TwapOracleJoeV2.sol#152)
TwapOracleJoeV2._currentCumulativePrices() (src/core/TwapOracleJoeV2.sol#139-155) performs a multiplication on the result of a division:
	- price1 = (uint256(reserve0) * Q112) / uint256(reserve1) (src/core/TwapOracleJoeV2.sol#151)
	- price1Cumulative += price1 * timeElapsed (src/core/TwapOracleJoeV2.sol#153)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) performs a multiplication on the result of a division:
	- mebtcUsdc = (costUSDC * mebtcShareBps) / 10_000 (src/nft/MinerNFT.sol#543)
	- mebtcAmount = (mebtcUsdc * MEBTC_UNIT) / price (src/nft/MinerNFT.sol#546)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
INFO:Detectors:
LiquidityEngine._addLiquidity(address) (src/core/LiquidityEngine.sol#110-124) uses a dangerous strict equality:
	- usdcBal < minUsdc || mebtcBal == 0 (src/core/LiquidityEngine.sol#114)
LiquidityEngine._addLiquidity(address) (src/core/LiquidityEngine.sol#110-124) uses a dangerous strict equality:
	- usdcIn == 0 || mebtcIn == 0 (src/core/LiquidityEngine.sol#117)
LiquidityEngine._autoCompound(address) (src/core/LiquidityEngine.sol#95-108) uses a dangerous strict equality:
	- lpBal == 0 || burnBps == 0 (src/core/LiquidityEngine.sol#97)
LiquidityEngine._autoCompound(address) (src/core/LiquidityEngine.sol#95-108) uses a dangerous strict equality:
	- burnAmount == 0 (src/core/LiquidityEngine.sol#100)
MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490) uses a dangerous strict equality:
	- last == 0 (src/core/MiningManager.sol#482)
TwapOracleJoeV2.getPriceForFees() (src/core/TwapOracleJoeV2.sol#125-132) uses a dangerous strict equality:
	- price == 0 || ts == 0 (src/core/TwapOracleJoeV2.sol#128)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
INFO:Detectors:
Reentrancy in MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398):
	External calls:
	- minerNFT.setLastClaimAt(id_scope_1,nowTs) (src/core/MiningManager.sol#368)
	State variables written after the call(s):
	- _settle(id_scope_1) (src/core/MiningManager.sol#360)
		- debtUSDC[id] += intervals * perIntervalFee (src/core/MiningManager.sol#487)
	MiningManager.debtUSDC (src/core/MiningManager.sol#94) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.debtUSDC (src/core/MiningManager.sol#94)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- debtUSDC[id_scope_1] = 0 (src/core/MiningManager.sol#366)
	MiningManager.debtUSDC (src/core/MiningManager.sol#94) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.debtUSDC (src/core/MiningManager.sol#94)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- _settle(id_scope_1) (src/core/MiningManager.sol#360)
		- lastAccPerHash[id] = accRewardPerEffHash (src/core/MiningManager.sol#478)
	MiningManager.lastAccPerHash (src/core/MiningManager.sol#90) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.lastAccPerHash (src/core/MiningManager.sol#90)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- lastAccPerHash[id_scope_1] = accRewardPerEffHash (src/core/MiningManager.sol#370)
	MiningManager.lastAccPerHash (src/core/MiningManager.sol#90) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.lastAccPerHash (src/core/MiningManager.sol#90)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- lastClaimedBlockIndex[id_scope_1] = blockIndex (src/core/MiningManager.sol#371)
	MiningManager.lastClaimedBlockIndex (src/core/MiningManager.sol#95) can be used in cross function reentrancies:
	- MiningManager.lastClaimedBlockIndex (src/core/MiningManager.sol#95)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- _settle(id_scope_1) (src/core/MiningManager.sol#360)
		- lastSettleTime[id] = last + intervals * CLAIM_INTERVAL (src/core/MiningManager.sol#488)
	MiningManager.lastSettleTime (src/core/MiningManager.sol#93) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.lastSettleTime (src/core/MiningManager.sol#93)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.onStakeChange(address) (src/core/MiningManager.sol#174-196)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- lastSettleTime[id_scope_1] = nowTs (src/core/MiningManager.sol#369)
	MiningManager.lastSettleTime (src/core/MiningManager.sol#93) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.lastSettleTime (src/core/MiningManager.sol#93)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.onStakeChange(address) (src/core/MiningManager.sol#174-196)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- _settle(id_scope_1) (src/core/MiningManager.sol#360)
		- pendingReward[id] += scaled / 1e12 (src/core/MiningManager.sol#476)
	MiningManager.pendingReward (src/core/MiningManager.sol#91) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.pendingReward (src/core/MiningManager.sol#91)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- pendingReward[id_scope_1] = 0 (src/core/MiningManager.sol#365)
	MiningManager.pendingReward (src/core/MiningManager.sol#91) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.pendingReward (src/core/MiningManager.sol#91)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
	- _settle(id_scope_1) (src/core/MiningManager.sol#360)
		- pendingRewardRemainder[id] = scaled % 1e12 (src/core/MiningManager.sol#477)
	MiningManager.pendingRewardRemainder (src/core/MiningManager.sol#92) can be used in cross function reentrancies:
	- MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490)
	- MiningManager.onMinerTransfer(address,address,uint256,uint256) (src/core/MiningManager.sol#239-281)
	- MiningManager.pendingRewardRemainder (src/core/MiningManager.sol#92)
	- MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462)
Reentrancy in LiquidityEngine._ensurePair() (src/core/LiquidityEngine.sol#83-93):
	External calls:
	- lp = IJoeFactory(factory).createPair(usdc,mebtc) (src/core/LiquidityEngine.sol#89)
	State variables written after the call(s):
	- pair = lp (src/core/LiquidityEngine.sol#91)
	LiquidityEngine.pair (src/core/LiquidityEngine.sol#39) can be used in cross function reentrancies:
	- LiquidityEngine._ensurePair() (src/core/LiquidityEngine.sol#83-93)
	- LiquidityEngine.pair (src/core/LiquidityEngine.sol#39)
Reentrancy in MinerNFT._requestUpgradeHash(uint256,uint16) (src/nft/MinerNFT.sol#462-485):
	External calls:
	- _collectUpgradeFee(cost,mebtcShareBps) (src/nft/MinerNFT.sol#479)
		- twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
	State variables written after the call(s):
	- s.pendingHashUpgradeBps += HASH_STEP_BPS (src/nft/MinerNFT.sol#481)
	MinerNFT.minerState (src/nft/MinerNFT.sol#104) can be used in cross function reentrancies:
	- MinerNFT._update(address,uint256,address) (src/nft/MinerNFT.sol#565-580)
	- MinerNFT.applyPendingUpgrades(uint256) (src/nft/MinerNFT.sol#498-525)
	- MinerNFT.getMinerConfig(uint256) (src/nft/MinerNFT.sol#287-301)
	- MinerNFT.getMinerData(uint256) (src/nft/MinerNFT.sol#265-280)
	- MinerNFT.getMinerState(uint256) (src/nft/MinerNFT.sol#282-285)
	- MinerNFT.setLastClaimAt(uint256,uint40) (src/nft/MinerNFT.sol#493-496)
	- MinerNFT.tokenURI(uint256) (src/nft/MinerNFT.sol#257-262)
Reentrancy in MinerNFT._requestUpgradePower(uint256,uint16) (src/nft/MinerNFT.sol#437-460):
	External calls:
	- _collectUpgradeFee(cost,mebtcShareBps) (src/nft/MinerNFT.sol#454)
		- twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
	State variables written after the call(s):
	- s.pendingPowerUpgradeBps += POWER_STEP_BPS (src/nft/MinerNFT.sol#456)
	MinerNFT.minerState (src/nft/MinerNFT.sol#104) can be used in cross function reentrancies:
	- MinerNFT._update(address,uint256,address) (src/nft/MinerNFT.sol#565-580)
	- MinerNFT.applyPendingUpgrades(uint256) (src/nft/MinerNFT.sol#498-525)
	- MinerNFT.getMinerConfig(uint256) (src/nft/MinerNFT.sol#287-301)
	- MinerNFT.getMinerData(uint256) (src/nft/MinerNFT.sol#265-280)
	- MinerNFT.getMinerState(uint256) (src/nft/MinerNFT.sol#282-285)
	- MinerNFT.setLastClaimAt(uint256,uint40) (src/nft/MinerNFT.sol#493-496)
	- MinerNFT.tokenURI(uint256) (src/nft/MinerNFT.sol#257-262)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
INFO:Detectors:
MiningManager.resyncMiner(uint256).owner (src/core/MiningManager.sol#304) is a local variable never initialized
MiningManager._update().intervals (src/core/MiningManager.sol#502) is a local variable never initialized
MiningManager._claim(uint256[],uint16).outR (src/core/MiningManager.sol#346) is a local variable never initialized
MiningManager.resyncMiner(uint256).expectedPower (src/core/MiningManager.sol#312) is a local variable never initialized
MiningManager._claim(uint256[],uint16).outF (src/core/MiningManager.sol#347) is a local variable never initialized
MiningManager.resyncMiner(uint256).expectedHash (src/core/MiningManager.sol#311) is a local variable never initialized
MiningManager._update().minted (src/core/MiningManager.sol#501) is a local variable never initialized
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#uninitialized-local-variables
INFO:Detectors:
MiningManager._computeEffForOwner(uint256,address) (src/core/MiningManager.sol#198-220) ignores return value by (None,None,None,stakeHashBps,stakePowerBps) = stakeVault.getStakeInfo(owner) (src/core/MiningManager.sol#212)
MiningManager._collectFees(address,uint256,uint16) (src/core/MiningManager.sol#400-435) ignores return value by twapOracle.updateIfDue() (src/core/MiningManager.sol#401)
TwapOracleJoeV2.constructor(address,address,address,uint256,uint32) (src/core/TwapOracleJoeV2.sol#35-58) ignores return value by (None,None,ts) = pair.getReserves() (src/core/TwapOracleJoeV2.sol#56)
TwapOracleJoeV2.isReady() (src/core/TwapOracleJoeV2.sol#64-71) ignores return value by (reserve0,reserve1,None) = pair.getReserves() (src/core/TwapOracleJoeV2.sol#65)
TwapOracleJoeV2.priceMebtcInUsdc() (src/core/TwapOracleJoeV2.sol#73-92) ignores return value by (reserve0,reserve1,None) = pair.getReserves() (src/core/TwapOracleJoeV2.sol#74)
TwapOracleJoeV2.updateIfDue() (src/core/TwapOracleJoeV2.sol#94-123) ignores return value by (reserve0,reserve1,None) = pair.getReserves() (src/core/TwapOracleJoeV2.sol#101)
TwapOracleJoeV2.usdcLiquidity() (src/core/TwapOracleJoeV2.sol#134-137) ignores return value by (reserve0,reserve1,None) = pair.getReserves() (src/core/TwapOracleJoeV2.sol#135)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) ignores return value by twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
INFO:Detectors:
MiningManager._computeEffForOwner(uint256,address) (src/core/MiningManager.sol#198-220) has external calls inside a loop: (baseHash,basePower,hashBps,powerBps,created) = minerNFT.getMinerConfig(tokenId) (src/core/MiningManager.sol#203-204)
	Calls stack containing the loop:
		MiningManager.onStakeChange(address)
MiningManager._computeEffForOwner(uint256,address) (src/core/MiningManager.sol#198-220) has external calls inside a loop: (None,None,None,stakeHashBps,stakePowerBps) = stakeVault.getStakeInfo(owner) (src/core/MiningManager.sol#212)
	Calls stack containing the loop:
		MiningManager.onStakeChange(address)
MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398) has external calls inside a loop: require(bool,string)(minerNFT.ownerOf(id) == msg.sender,!owner) (src/core/MiningManager.sol#353)
	Calls stack containing the loop:
		MiningManager.claim(uint256[])
MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398) has external calls inside a loop: minerNFT.setLastClaimAt(id_scope_1,nowTs) (src/core/MiningManager.sol#368)
	Calls stack containing the loop:
		MiningManager.claim(uint256[])
MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398) has external calls inside a loop: minerNFT.applyPendingUpgrades(id_scope_3) (src/core/MiningManager.sol#394)
	Calls stack containing the loop:
		MiningManager.claim(uint256[])
MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398) has external calls inside a loop: require(bool,string)(minerNFT.ownerOf(id) == msg.sender,!owner) (src/core/MiningManager.sol#353)
	Calls stack containing the loop:
		MiningManager.claimWithMebtc(uint256[],uint16)
MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398) has external calls inside a loop: minerNFT.setLastClaimAt(id_scope_1,nowTs) (src/core/MiningManager.sol#368)
	Calls stack containing the loop:
		MiningManager.claimWithMebtc(uint256[],uint16)
MiningManager._claim(uint256[],uint16) (src/core/MiningManager.sol#343-398) has external calls inside a loop: minerNFT.applyPendingUpgrades(id_scope_3) (src/core/MiningManager.sol#394)
	Calls stack containing the loop:
		MiningManager.claimWithMebtc(uint256[],uint16)
MinerNFT._update(address,uint256,address) (src/nft/MinerNFT.sol#565-580) has external calls inside a loop: manager.onMinerTransfer(from,to,tokenId,0) (src/nft/MinerNFT.sol#575)
	Calls stack containing the loop:
		MinerNFT.buyFromModel(uint16,uint256)
		ERC721._safeMint(address,uint256)
		ERC721._safeMint(address,uint256,bytes)
		ERC721._mint(address,uint256)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatch(uint256[])
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: (price,fresh) = twapOracle.getPriceForFees() (src/nft/MinerNFT.sol#536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatch(uint256[])
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount (src/nft/MinerNFT.sol#548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatch(uint256[])
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: (price,fresh) = twapOracle.getPriceForFees() (src/nft/MinerNFT.sol#536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount (src/nft/MinerNFT.sol#548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatch(uint256[])
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: (price,fresh) = twapOracle.getPriceForFees() (src/nft/MinerNFT.sol#536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatch(uint256[])
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount (src/nft/MinerNFT.sol#548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatch(uint256[])
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: twapOracle.updateIfDue() (src/nft/MinerNFT.sol#529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: (price,fresh) = twapOracle.getPriceForFees() (src/nft/MinerNFT.sol#536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)
MinerNFT._collectUpgradeFee(uint256,uint16) (src/nft/MinerNFT.sol#527-562) has external calls inside a loop: mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount (src/nft/MinerNFT.sol#548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation/#calls-inside-a-loop
INFO:Detectors:
Reentrancy in LiquidityEngine._addLiquidity(address) (src/core/LiquidityEngine.sol#110-124):
	External calls:
	- demandVault.transferTo(lp,usdcIn) (src/core/LiquidityEngine.sol#119)
	- feeVaultMeBTC.transferTo(lp,mebtcIn) (src/core/LiquidityEngine.sol#120)
	- minted = IJoePair(lp).mint(address(this)) (src/core/LiquidityEngine.sol#122)
	Event emitted after the call(s):
	- EpochExecuted(lastEpoch,usdcIn,mebtcIn,minted) (src/core/LiquidityEngine.sol#123)
Reentrancy in LiquidityEngine._autoCompound(address) (src/core/LiquidityEngine.sol#95-108):
	External calls:
	- require(bool,string)(IJoePair(lp).transfer(lp,burnAmount),lp transfer) (src/core/LiquidityEngine.sol#102)
	- (amount0,amount1) = IJoePair(lp).burn(address(this)) (src/core/LiquidityEngine.sol#103)
	- minted = _mintLiquidity(lp,usdcAmt,mebtcAmt) (src/core/LiquidityEngine.sol#106)
		- minted = IJoePair(lp).mint(address(this)) (src/core/LiquidityEngine.sol#151)
	Event emitted after the call(s):
	- AutoCompounded(burnAmount,usdcAmt,mebtcAmt,minted) (src/core/LiquidityEngine.sol#107)
Reentrancy in LiquidityEngine._ensurePair() (src/core/LiquidityEngine.sol#83-93):
	External calls:
	- lp = IJoeFactory(factory).createPair(usdc,mebtc) (src/core/LiquidityEngine.sol#89)
	Event emitted after the call(s):
	- PairCreated(lp) (src/core/LiquidityEngine.sol#92)
Reentrancy in LiquidityEngine.executeEpoch() (src/core/LiquidityEngine.sol#73-81):
	External calls:
	- lp = _ensurePair() (src/core/LiquidityEngine.sol#78)
		- lp = IJoeFactory(factory).createPair(usdc,mebtc) (src/core/LiquidityEngine.sol#89)
	- _autoCompound(lp) (src/core/LiquidityEngine.sol#79)
		- minted = IJoePair(lp).mint(address(this)) (src/core/LiquidityEngine.sol#151)
		- require(bool,string)(IJoePair(lp).transfer(lp,burnAmount),lp transfer) (src/core/LiquidityEngine.sol#102)
		- (amount0,amount1) = IJoePair(lp).burn(address(this)) (src/core/LiquidityEngine.sol#103)
	Event emitted after the call(s):
	- AutoCompounded(burnAmount,usdcAmt,mebtcAmt,minted) (src/core/LiquidityEngine.sol#107)
		- _autoCompound(lp) (src/core/LiquidityEngine.sol#79)
Reentrancy in LiquidityEngine.executeEpoch() (src/core/LiquidityEngine.sol#73-81):
	External calls:
	- lp = _ensurePair() (src/core/LiquidityEngine.sol#78)
		- lp = IJoeFactory(factory).createPair(usdc,mebtc) (src/core/LiquidityEngine.sol#89)
	- _autoCompound(lp) (src/core/LiquidityEngine.sol#79)
		- minted = IJoePair(lp).mint(address(this)) (src/core/LiquidityEngine.sol#151)
		- require(bool,string)(IJoePair(lp).transfer(lp,burnAmount),lp transfer) (src/core/LiquidityEngine.sol#102)
		- (amount0,amount1) = IJoePair(lp).burn(address(this)) (src/core/LiquidityEngine.sol#103)
	- _addLiquidity(lp) (src/core/LiquidityEngine.sol#80)
		- demandVault.transferTo(lp,usdcIn) (src/core/LiquidityEngine.sol#119)
		- feeVaultMeBTC.transferTo(lp,mebtcIn) (src/core/LiquidityEngine.sol#120)
		- minted = IJoePair(lp).mint(address(this)) (src/core/LiquidityEngine.sol#122)
	Event emitted after the call(s):
	- EpochExecuted(lastEpoch,usdcIn,mebtcIn,minted) (src/core/LiquidityEngine.sol#123)
		- _addLiquidity(lp) (src/core/LiquidityEngine.sol#80)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
INFO:Detectors:
LiquidityEngine.executeEpoch() (src/core/LiquidityEngine.sol#73-81) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(block.timestamp >= nextEpoch,epoch) (src/core/LiquidityEngine.sol#75)
MiningManager.preview(uint256,address) (src/core/MiningManager.sol#443-462) uses timestamp for comparisons
	Dangerous comparisons:
	- last == 0 (src/core/MiningManager.sol#453)
	- intervals > 0 (src/core/MiningManager.sol#456)
MiningManager._settleWithEff(uint256,uint256,uint256) (src/core/MiningManager.sol#472-490) uses timestamp for comparisons
	Dangerous comparisons:
	- last == 0 (src/core/MiningManager.sol#482)
	- intervals > 0 (src/core/MiningManager.sol#485)
MiningManager._update() (src/core/MiningManager.sol#492-531) uses timestamp for comparisons
	Dangerous comparisons:
	- ts <= lastUpdate (src/core/MiningManager.sol#495)
	- ts >= _last + CLAIM_INTERVAL && slotsProcessed < MAX_SLOTS_PER_UPDATE (src/core/MiningManager.sol#510)
MiningManager._simulateUpdate() (src/core/MiningManager.sol#533-562) uses timestamp for comparisons
	Dangerous comparisons:
	- ts <= _lastUpdate (src/core/MiningManager.sol#546)
	- ts >= _lastUpdate + CLAIM_INTERVAL && slotsProcessed < MAX_SLOTS_PER_UPDATE (src/core/MiningManager.sol#549)
StakeVault.stake(uint256) (src/core/StakeVault.sol#45-65) uses timestamp for comparisons
	Dangerous comparisons:
	- newUnlock > unlockTime[msg.sender] (src/core/StakeVault.sol#58)
StakeVault.unstake(uint256) (src/core/StakeVault.sol#67-82) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(block.timestamp >= unlockTime[msg.sender],locked) (src/core/StakeVault.sol#69)
TwapOracleJoeV2.isReady() (src/core/TwapOracleJoeV2.sol#64-71) uses timestamp for comparisons
	Dangerous comparisons:
	- elapsed >= window (src/core/TwapOracleJoeV2.sol#70)
TwapOracleJoeV2.priceMebtcInUsdc() (src/core/TwapOracleJoeV2.sol#73-92) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(elapsed >= window,window) (src/core/TwapOracleJoeV2.sol#79)
	- require(bool,string)(priceUsdc > 0,price) (src/core/TwapOracleJoeV2.sol#90)
TwapOracleJoeV2.updateIfDue() (src/core/TwapOracleJoeV2.sol#94-123) uses timestamp for comparisons
	Dangerous comparisons:
	- blockTimestamp <= lastTimestamp (src/core/TwapOracleJoeV2.sol#96)
	- elapsed < updateInterval (src/core/TwapOracleJoeV2.sol#99)
	- priceUsdc > 0 (src/core/TwapOracleJoeV2.sol#112)
TwapOracleJoeV2.getPriceForFees() (src/core/TwapOracleJoeV2.sol#125-132) uses timestamp for comparisons
	Dangerous comparisons:
	- price == 0 || ts == 0 (src/core/TwapOracleJoeV2.sol#128)
	- block.timestamp < ts (src/core/TwapOracleJoeV2.sol#129)
	- isFresh = age <= maxPriceAge (src/core/TwapOracleJoeV2.sol#131)
TwapOracleJoeV2._currentCumulativePrices() (src/core/TwapOracleJoeV2.sol#139-155) uses timestamp for comparisons
	Dangerous comparisons:
	- blockTimestampLast != blockTimestamp && reserve0 > 0 && reserve1 > 0 (src/core/TwapOracleJoeV2.sol#148)
MinerNFT.getMinerData(uint256) (src/nft/MinerNFT.sol#265-280) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(s.modelId != 0,model!) (src/nft/MinerNFT.sol#267)
MinerNFT.getMinerState(uint256) (src/nft/MinerNFT.sol#282-285) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(minerState[tokenId].modelId != 0,model!) (src/nft/MinerNFT.sol#283)
MinerNFT.getMinerConfig(uint256) (src/nft/MinerNFT.sol#287-301) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(s.modelId != 0,model!) (src/nft/MinerNFT.sol#293)
MinerNFT._requestUpgradePower(uint256,uint16) (src/nft/MinerNFT.sol#437-460) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(s.modelId != 0,model!) (src/nft/MinerNFT.sol#441)
MinerNFT._requestUpgradeHash(uint256,uint16) (src/nft/MinerNFT.sol#462-485) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(s.modelId != 0,model!) (src/nft/MinerNFT.sol#466)
MinerNFT.setLastClaimAt(uint256,uint40) (src/nft/MinerNFT.sol#493-496) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(minerState[tokenId].modelId != 0,model!) (src/nft/MinerNFT.sol#494)
MinerNFT.applyPendingUpgrades(uint256) (src/nft/MinerNFT.sol#498-525) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(s.modelId != 0,model!) (src/nft/MinerNFT.sol#500)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp
INFO:Detectors:
MiningManager.onStakeChange(address) (src/core/MiningManager.sol#174-196) has costly operations inside a loop:
	- totalEffectiveHash += (effHash - oldEffHash) (src/core/MiningManager.sol#188)
MiningManager.onStakeChange(address) (src/core/MiningManager.sol#174-196) has costly operations inside a loop:
	- totalEffectiveHash -= (oldEffHash - effHash) (src/core/MiningManager.sol#190)
MinerNFT.buyFromModel(uint16,uint256) (src/nft/MinerNFT.sol#304-354) has costly operations inside a loop:
	- tokenId = nextTokenId ++ (src/nft/MinerNFT.sol#335)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#costly-operations-inside-a-loop
INFO:Detectors:
MiningManager (src/core/MiningManager.sol#55-563) should inherit from IStakeChangeHook (src/core/StakeVault.sol#8-10)
MiningManager (src/core/MiningManager.sol#55-563) should inherit from IMiningManagerHook (src/nft/MinerNFT.sol#30-33)
StakeVault (src/core/StakeVault.sol#12-115) should inherit from IStakeVault (src/core/MiningManager.sol#48-53)
TwapOracleJoeV2 (src/core/TwapOracleJoeV2.sol#14-161) should inherit from ILiquidityOracle (src/nft/MinerNFT.sol#35-37)
MinerNFT (src/nft/MinerNFT.sol#39-586) should inherit from IMinerNFT (src/core/MiningManager.sol#33-46)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-inheritance
INFO:Detectors:
Function IMeBTC.MAX_SUPPLY() (src/core/MiningManager.sol#29) is not in mixedCase
Parameter MiningManager.setPayToken(address)._payToken (src/core/MiningManager.sol#127) is not in mixedCase
Parameter MiningManager.init(address,address,address,address,address,address)._mebtc (src/core/MiningManager.sol#136) is not in mixedCase
Parameter MiningManager.init(address,address,address,address,address,address)._miner (src/core/MiningManager.sol#137) is not in mixedCase
Parameter MiningManager.init(address,address,address,address,address,address)._stakeVault (src/core/MiningManager.sol#138) is not in mixedCase
Parameter MiningManager.init(address,address,address,address,address,address)._demandVault (src/core/MiningManager.sol#139) is not in mixedCase
Parameter MiningManager.init(address,address,address,address,address,address)._feeVaultMeBTC (src/core/MiningManager.sol#140) is not in mixedCase
Parameter MiningManager.init(address,address,address,address,address,address)._twapOracle (src/core/MiningManager.sol#141) is not in mixedCase
Parameter TokenVault.init(address)._engine (src/core/TokenVault.sol#20) is not in mixedCase
Parameter MinerNFT.setManager(address)._manager (src/nft/MinerNFT.sol#158) is not in mixedCase
Parameter MinerNFT.setPayToken(address)._payToken (src/nft/MinerNFT.sol#164) is not in mixedCase
Parameter MinerNFT.setLiquidityOracle(address)._oracle (src/nft/MinerNFT.sol#202) is not in mixedCase
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#conformance-to-solidity-naming-conventions
**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [divide-before-multiply](#divide-before-multiply) (10 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (6 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (4 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (7 results) (Medium)
 - [unused-return](#unused-return) (8 results) (Medium)
 - [calls-loop](#calls-loop) (21 results) (Low)
 - [reentrancy-events](#reentrancy-events) (5 results) (Low)
 - [timestamp](#timestamp) (19 results) (Low)
 - [costly-loop](#costly-loop) (3 results) (Informational)
 - [missing-inheritance](#missing-inheritance) (5 results) (Informational)
 - [naming-convention](#naming-convention) (12 results) (Informational)
## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-0
[TwapOracleJoeV2.updateIfDue()](src/core/TwapOracleJoeV2.sol#L94-L123) performs a multiplication on the result of a division:
	- [priceAverage = (price1Cumulative - price1CumulativeLast) / elapsed](src/core/TwapOracleJoeV2.sol#L108)
	- [priceUsdc = (priceAverage * 10 ** MEBTC_DECIMALS) / Q112](src/core/TwapOracleJoeV2.sol#L111)

src/core/TwapOracleJoeV2.sol#L94-L123


 - [ ] ID-1
[TwapOracleJoeV2._currentCumulativePrices()](src/core/TwapOracleJoeV2.sol#L139-L155) performs a multiplication on the result of a division:
	- [price1 = (uint256(reserve0) * Q112) / uint256(reserve1)](src/core/TwapOracleJoeV2.sol#L151)
	- [price1Cumulative += price1 * timeElapsed](src/core/TwapOracleJoeV2.sol#L153)

src/core/TwapOracleJoeV2.sol#L139-L155


 - [ ] ID-2
[MiningManager._computeEffForOwner(uint256,address)](src/core/MiningManager.sol#L198-L220) performs a multiplication on the result of a division:
	- [effPowerAfter = (basePower * (10_000 - pbps)) / 10_000](src/core/MiningManager.sol#L210)
	- [stakePowerBonus = (effPowerAfter * uint256(stakePowerBps)) / 10_000](src/core/MiningManager.sol#L215)

src/core/MiningManager.sol#L198-L220


 - [ ] ID-3
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) performs a multiplication on the result of a division:
	- [mebtcUsdc = (costUSDC * mebtcShareBps) / 10_000](src/nft/MinerNFT.sol#L543)
	- [mebtcAmount = (mebtcUsdc * MEBTC_UNIT) / price](src/nft/MinerNFT.sol#L546)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-4
[MiningManager._collectFees(address,uint256,uint16)](src/core/MiningManager.sol#L400-L435) performs a multiplication on the result of a division:
	- [mebtcUsdc = (feeUSDC * mebtcShareBps) / 10_000](src/core/MiningManager.sol#L414)
	- [mebtcAmount = (mebtcUsdc * MEBTC_UNIT) / price](src/core/MiningManager.sol#L417)

src/core/MiningManager.sol#L400-L435


 - [ ] ID-5
[MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462) performs a multiplication on the result of a division:
	- [intervals = (block.timestamp - last) / CLAIM_INTERVAL](src/core/MiningManager.sol#L455)
	- [f = debtUSDC[id] + intervals * perIntervalFee](src/core/MiningManager.sol#L458)

src/core/MiningManager.sol#L443-L462


 - [ ] ID-6
[MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490) performs a multiplication on the result of a division:
	- [intervals = (block.timestamp - last) / CLAIM_INTERVAL](src/core/MiningManager.sol#L484)
	- [debtUSDC[id] += intervals * perIntervalFee](src/core/MiningManager.sol#L487)

src/core/MiningManager.sol#L472-L490


 - [ ] ID-7
[MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490) performs a multiplication on the result of a division:
	- [intervals = (block.timestamp - last) / CLAIM_INTERVAL](src/core/MiningManager.sol#L484)
	- [lastSettleTime[id] = last + intervals * CLAIM_INTERVAL](src/core/MiningManager.sol#L488)

src/core/MiningManager.sol#L472-L490


 - [ ] ID-8
[TwapOracleJoeV2._currentCumulativePrices()](src/core/TwapOracleJoeV2.sol#L139-L155) performs a multiplication on the result of a division:
	- [price0 = (uint256(reserve1) * Q112) / uint256(reserve0)](src/core/TwapOracleJoeV2.sol#L150)
	- [price0Cumulative += price0 * timeElapsed](src/core/TwapOracleJoeV2.sol#L152)

src/core/TwapOracleJoeV2.sol#L139-L155


 - [ ] ID-9
[TwapOracleJoeV2.priceMebtcInUsdc()](src/core/TwapOracleJoeV2.sol#L73-L92) performs a multiplication on the result of a division:
	- [priceAverage = (price1Cumulative - price1CumulativeLast) / elapsed](src/core/TwapOracleJoeV2.sol#L85)
	- [priceUsdc = (priceAverage * 10 ** MEBTC_DECIMALS) / Q112](src/core/TwapOracleJoeV2.sol#L89)

src/core/TwapOracleJoeV2.sol#L73-L92


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-10
[LiquidityEngine._addLiquidity(address)](src/core/LiquidityEngine.sol#L110-L124) uses a dangerous strict equality:
	- [usdcIn == 0 || mebtcIn == 0](src/core/LiquidityEngine.sol#L117)

src/core/LiquidityEngine.sol#L110-L124


 - [ ] ID-11
[MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490) uses a dangerous strict equality:
	- [last == 0](src/core/MiningManager.sol#L482)

src/core/MiningManager.sol#L472-L490


 - [ ] ID-12
[LiquidityEngine._autoCompound(address)](src/core/LiquidityEngine.sol#L95-L108) uses a dangerous strict equality:
	- [lpBal == 0 || burnBps == 0](src/core/LiquidityEngine.sol#L97)

src/core/LiquidityEngine.sol#L95-L108


 - [ ] ID-13
[TwapOracleJoeV2.getPriceForFees()](src/core/TwapOracleJoeV2.sol#L125-L132) uses a dangerous strict equality:
	- [price == 0 || ts == 0](src/core/TwapOracleJoeV2.sol#L128)

src/core/TwapOracleJoeV2.sol#L125-L132


 - [ ] ID-14
[LiquidityEngine._addLiquidity(address)](src/core/LiquidityEngine.sol#L110-L124) uses a dangerous strict equality:
	- [usdcBal < minUsdc || mebtcBal == 0](src/core/LiquidityEngine.sol#L114)

src/core/LiquidityEngine.sol#L110-L124


 - [ ] ID-15
[LiquidityEngine._autoCompound(address)](src/core/LiquidityEngine.sol#L95-L108) uses a dangerous strict equality:
	- [burnAmount == 0](src/core/LiquidityEngine.sol#L100)

src/core/LiquidityEngine.sol#L95-L108


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-16
Reentrancy in [LiquidityEngine._ensurePair()](src/core/LiquidityEngine.sol#L83-L93):
	External calls:
	- [lp = IJoeFactory(factory).createPair(usdc,mebtc)](src/core/LiquidityEngine.sol#L89)
	State variables written after the call(s):
	- [pair = lp](src/core/LiquidityEngine.sol#L91)
	[LiquidityEngine.pair](src/core/LiquidityEngine.sol#L39) can be used in cross function reentrancies:
	- [LiquidityEngine._ensurePair()](src/core/LiquidityEngine.sol#L83-L93)
	- [LiquidityEngine.pair](src/core/LiquidityEngine.sol#L39)

src/core/LiquidityEngine.sol#L83-L93


 - [ ] ID-17
Reentrancy in [MinerNFT._requestUpgradeHash(uint256,uint16)](src/nft/MinerNFT.sol#L462-L485):
	External calls:
	- [_collectUpgradeFee(cost,mebtcShareBps)](src/nft/MinerNFT.sol#L479)
		- [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)
	State variables written after the call(s):
	- [s.pendingHashUpgradeBps += HASH_STEP_BPS](src/nft/MinerNFT.sol#L481)
	[MinerNFT.minerState](src/nft/MinerNFT.sol#L104) can be used in cross function reentrancies:
	- [MinerNFT._update(address,uint256,address)](src/nft/MinerNFT.sol#L565-L580)
	- [MinerNFT.applyPendingUpgrades(uint256)](src/nft/MinerNFT.sol#L498-L525)
	- [MinerNFT.getMinerConfig(uint256)](src/nft/MinerNFT.sol#L287-L301)
	- [MinerNFT.getMinerData(uint256)](src/nft/MinerNFT.sol#L265-L280)
	- [MinerNFT.getMinerState(uint256)](src/nft/MinerNFT.sol#L282-L285)
	- [MinerNFT.setLastClaimAt(uint256,uint40)](src/nft/MinerNFT.sol#L493-L496)
	- [MinerNFT.tokenURI(uint256)](src/nft/MinerNFT.sol#L257-L262)

src/nft/MinerNFT.sol#L462-L485


 - [ ] ID-18
Reentrancy in [MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398):
	External calls:
	- [minerNFT.setLastClaimAt(id_scope_1,nowTs)](src/core/MiningManager.sol#L368)
	State variables written after the call(s):
	- [_settle(id_scope_1)](src/core/MiningManager.sol#L360)
		- [debtUSDC[id] += intervals * perIntervalFee](src/core/MiningManager.sol#L487)
	[MiningManager.debtUSDC](src/core/MiningManager.sol#L94) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.debtUSDC](src/core/MiningManager.sol#L94)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [debtUSDC[id_scope_1] = 0](src/core/MiningManager.sol#L366)
	[MiningManager.debtUSDC](src/core/MiningManager.sol#L94) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.debtUSDC](src/core/MiningManager.sol#L94)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [_settle(id_scope_1)](src/core/MiningManager.sol#L360)
		- [lastAccPerHash[id] = accRewardPerEffHash](src/core/MiningManager.sol#L478)
	[MiningManager.lastAccPerHash](src/core/MiningManager.sol#L90) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.lastAccPerHash](src/core/MiningManager.sol#L90)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [lastAccPerHash[id_scope_1] = accRewardPerEffHash](src/core/MiningManager.sol#L370)
	[MiningManager.lastAccPerHash](src/core/MiningManager.sol#L90) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.lastAccPerHash](src/core/MiningManager.sol#L90)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [lastClaimedBlockIndex[id_scope_1] = blockIndex](src/core/MiningManager.sol#L371)
	[MiningManager.lastClaimedBlockIndex](src/core/MiningManager.sol#L95) can be used in cross function reentrancies:
	- [MiningManager.lastClaimedBlockIndex](src/core/MiningManager.sol#L95)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [_settle(id_scope_1)](src/core/MiningManager.sol#L360)
		- [lastSettleTime[id] = last + intervals * CLAIM_INTERVAL](src/core/MiningManager.sol#L488)
	[MiningManager.lastSettleTime](src/core/MiningManager.sol#L93) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.lastSettleTime](src/core/MiningManager.sol#L93)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.onStakeChange(address)](src/core/MiningManager.sol#L174-L196)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [lastSettleTime[id_scope_1] = nowTs](src/core/MiningManager.sol#L369)
	[MiningManager.lastSettleTime](src/core/MiningManager.sol#L93) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.lastSettleTime](src/core/MiningManager.sol#L93)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.onStakeChange(address)](src/core/MiningManager.sol#L174-L196)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [_settle(id_scope_1)](src/core/MiningManager.sol#L360)
		- [pendingReward[id] += scaled / 1e12](src/core/MiningManager.sol#L476)
	[MiningManager.pendingReward](src/core/MiningManager.sol#L91) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.pendingReward](src/core/MiningManager.sol#L91)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [pendingReward[id_scope_1] = 0](src/core/MiningManager.sol#L365)
	[MiningManager.pendingReward](src/core/MiningManager.sol#L91) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.pendingReward](src/core/MiningManager.sol#L91)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)
	- [_settle(id_scope_1)](src/core/MiningManager.sol#L360)
		- [pendingRewardRemainder[id] = scaled % 1e12](src/core/MiningManager.sol#L477)
	[MiningManager.pendingRewardRemainder](src/core/MiningManager.sol#L92) can be used in cross function reentrancies:
	- [MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490)
	- [MiningManager.onMinerTransfer(address,address,uint256,uint256)](src/core/MiningManager.sol#L239-L281)
	- [MiningManager.pendingRewardRemainder](src/core/MiningManager.sol#L92)
	- [MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462)

src/core/MiningManager.sol#L343-L398


 - [ ] ID-19
Reentrancy in [MinerNFT._requestUpgradePower(uint256,uint16)](src/nft/MinerNFT.sol#L437-L460):
	External calls:
	- [_collectUpgradeFee(cost,mebtcShareBps)](src/nft/MinerNFT.sol#L454)
		- [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)
	State variables written after the call(s):
	- [s.pendingPowerUpgradeBps += POWER_STEP_BPS](src/nft/MinerNFT.sol#L456)
	[MinerNFT.minerState](src/nft/MinerNFT.sol#L104) can be used in cross function reentrancies:
	- [MinerNFT._update(address,uint256,address)](src/nft/MinerNFT.sol#L565-L580)
	- [MinerNFT.applyPendingUpgrades(uint256)](src/nft/MinerNFT.sol#L498-L525)
	- [MinerNFT.getMinerConfig(uint256)](src/nft/MinerNFT.sol#L287-L301)
	- [MinerNFT.getMinerData(uint256)](src/nft/MinerNFT.sol#L265-L280)
	- [MinerNFT.getMinerState(uint256)](src/nft/MinerNFT.sol#L282-L285)
	- [MinerNFT.setLastClaimAt(uint256,uint40)](src/nft/MinerNFT.sol#L493-L496)
	- [MinerNFT.tokenURI(uint256)](src/nft/MinerNFT.sol#L257-L262)

src/nft/MinerNFT.sol#L437-L460


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-20
[MiningManager._update().intervals](src/core/MiningManager.sol#L502) is a local variable never initialized

src/core/MiningManager.sol#L502


 - [ ] ID-21
[MiningManager._claim(uint256[],uint16).outF](src/core/MiningManager.sol#L347) is a local variable never initialized

src/core/MiningManager.sol#L347


 - [ ] ID-22
[MiningManager.resyncMiner(uint256).expectedHash](src/core/MiningManager.sol#L311) is a local variable never initialized

src/core/MiningManager.sol#L311


 - [ ] ID-23
[MiningManager._claim(uint256[],uint16).outR](src/core/MiningManager.sol#L346) is a local variable never initialized

src/core/MiningManager.sol#L346


 - [ ] ID-24
[MiningManager.resyncMiner(uint256).expectedPower](src/core/MiningManager.sol#L312) is a local variable never initialized

src/core/MiningManager.sol#L312


 - [ ] ID-25
[MiningManager._update().minted](src/core/MiningManager.sol#L501) is a local variable never initialized

src/core/MiningManager.sol#L501


 - [ ] ID-26
[MiningManager.resyncMiner(uint256).owner](src/core/MiningManager.sol#L304) is a local variable never initialized

src/core/MiningManager.sol#L304


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-27
[TwapOracleJoeV2.priceMebtcInUsdc()](src/core/TwapOracleJoeV2.sol#L73-L92) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](src/core/TwapOracleJoeV2.sol#L74)

src/core/TwapOracleJoeV2.sol#L73-L92


 - [ ] ID-28
[MiningManager._computeEffForOwner(uint256,address)](src/core/MiningManager.sol#L198-L220) ignores return value by [(None,None,None,stakeHashBps,stakePowerBps) = stakeVault.getStakeInfo(owner)](src/core/MiningManager.sol#L212)

src/core/MiningManager.sol#L198-L220


 - [ ] ID-29
[TwapOracleJoeV2.usdcLiquidity()](src/core/TwapOracleJoeV2.sol#L134-L137) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](src/core/TwapOracleJoeV2.sol#L135)

src/core/TwapOracleJoeV2.sol#L134-L137


 - [ ] ID-30
[TwapOracleJoeV2.constructor(address,address,address,uint256,uint32)](src/core/TwapOracleJoeV2.sol#L35-L58) ignores return value by [(None,None,ts) = pair.getReserves()](src/core/TwapOracleJoeV2.sol#L56)

src/core/TwapOracleJoeV2.sol#L35-L58


 - [ ] ID-31
[TwapOracleJoeV2.isReady()](src/core/TwapOracleJoeV2.sol#L64-L71) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](src/core/TwapOracleJoeV2.sol#L65)

src/core/TwapOracleJoeV2.sol#L64-L71


 - [ ] ID-32
[MiningManager._collectFees(address,uint256,uint16)](src/core/MiningManager.sol#L400-L435) ignores return value by [twapOracle.updateIfDue()](src/core/MiningManager.sol#L401)

src/core/MiningManager.sol#L400-L435


 - [ ] ID-33
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) ignores return value by [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-34
[TwapOracleJoeV2.updateIfDue()](src/core/TwapOracleJoeV2.sol#L94-L123) ignores return value by [(reserve0,reserve1,None) = pair.getReserves()](src/core/TwapOracleJoeV2.sol#L101)

src/core/TwapOracleJoeV2.sol#L94-L123


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-35
[MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398) has external calls inside a loop: [minerNFT.applyPendingUpgrades(id_scope_3)](src/core/MiningManager.sol#L394)
	Calls stack containing the loop:
		MiningManager.claim(uint256[])

src/core/MiningManager.sol#L343-L398


 - [ ] ID-36
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-37
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount](src/nft/MinerNFT.sol#L548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatch(uint256[])
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-38
[MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398) has external calls inside a loop: [minerNFT.applyPendingUpgrades(id_scope_3)](src/core/MiningManager.sol#L394)
	Calls stack containing the loop:
		MiningManager.claimWithMebtc(uint256[],uint16)

src/core/MiningManager.sol#L343-L398


 - [ ] ID-39
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount](src/nft/MinerNFT.sol#L548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-40
[MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398) has external calls inside a loop: [require(bool,string)(minerNFT.ownerOf(id) == msg.sender,!owner)](src/core/MiningManager.sol#L353)
	Calls stack containing the loop:
		MiningManager.claimWithMebtc(uint256[],uint16)

src/core/MiningManager.sol#L343-L398


 - [ ] ID-41
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [(price,fresh) = twapOracle.getPriceForFees()](src/nft/MinerNFT.sol#L536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatch(uint256[])
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-42
[MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398) has external calls inside a loop: [minerNFT.setLastClaimAt(id_scope_1,nowTs)](src/core/MiningManager.sol#L368)
	Calls stack containing the loop:
		MiningManager.claimWithMebtc(uint256[],uint16)

src/core/MiningManager.sol#L343-L398


 - [ ] ID-43
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatch(uint256[])
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-44
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatch(uint256[])
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-45
[MiningManager._computeEffForOwner(uint256,address)](src/core/MiningManager.sol#L198-L220) has external calls inside a loop: [(None,None,None,stakeHashBps,stakePowerBps) = stakeVault.getStakeInfo(owner)](src/core/MiningManager.sol#L212)
	Calls stack containing the loop:
		MiningManager.onStakeChange(address)

src/core/MiningManager.sol#L198-L220


 - [ ] ID-46
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount](src/nft/MinerNFT.sol#L548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-47
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [(price,fresh) = twapOracle.getPriceForFees()](src/nft/MinerNFT.sol#L536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-48
[MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398) has external calls inside a loop: [minerNFT.setLastClaimAt(id_scope_1,nowTs)](src/core/MiningManager.sol#L368)
	Calls stack containing the loop:
		MiningManager.claim(uint256[])

src/core/MiningManager.sol#L343-L398


 - [ ] ID-49
[MinerNFT._update(address,uint256,address)](src/nft/MinerNFT.sol#L565-L580) has external calls inside a loop: [manager.onMinerTransfer(from,to,tokenId,0)](src/nft/MinerNFT.sol#L575)
	Calls stack containing the loop:
		MinerNFT.buyFromModel(uint16,uint256)
		ERC721._safeMint(address,uint256)
		ERC721._safeMint(address,uint256,bytes)
		ERC721._mint(address,uint256)

src/nft/MinerNFT.sol#L565-L580


 - [ ] ID-50
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [mebtcToken.allowance(msg.sender,address(this)) < mebtcAmount || mebtcToken.balanceOf(msg.sender) < mebtcAmount](src/nft/MinerNFT.sol#L548)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatch(uint256[])
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-51
[MiningManager._claim(uint256[],uint16)](src/core/MiningManager.sol#L343-L398) has external calls inside a loop: [require(bool,string)(minerNFT.ownerOf(id) == msg.sender,!owner)](src/core/MiningManager.sol#L353)
	Calls stack containing the loop:
		MiningManager.claim(uint256[])

src/core/MiningManager.sol#L343-L398


 - [ ] ID-52
[MiningManager._computeEffForOwner(uint256,address)](src/core/MiningManager.sol#L198-L220) has external calls inside a loop: [(baseHash,basePower,hashBps,powerBps,created) = minerNFT.getMinerConfig(tokenId)](src/core/MiningManager.sol#L203-L204)
	Calls stack containing the loop:
		MiningManager.onStakeChange(address)

src/core/MiningManager.sol#L198-L220


 - [ ] ID-53
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [(price,fresh) = twapOracle.getPriceForFees()](src/nft/MinerNFT.sol#L536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatch(uint256[])
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-54
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [twapOracle.updateIfDue()](src/nft/MinerNFT.sol#L529)
	Calls stack containing the loop:
		MinerNFT.requestUpgradeHashBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradeHashBatch(uint256[],uint16)
		MinerNFT._requestUpgradeHash(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


 - [ ] ID-55
[MinerNFT._collectUpgradeFee(uint256,uint16)](src/nft/MinerNFT.sol#L527-L562) has external calls inside a loop: [(price,fresh) = twapOracle.getPriceForFees()](src/nft/MinerNFT.sol#L536)
	Calls stack containing the loop:
		MinerNFT.requestUpgradePowerBatchWithMebtc(uint256[],uint16)
		MinerNFT._requestUpgradePowerBatch(uint256[],uint16)
		MinerNFT._requestUpgradePower(uint256,uint16)

src/nft/MinerNFT.sol#L527-L562


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-56
Reentrancy in [LiquidityEngine.executeEpoch()](src/core/LiquidityEngine.sol#L73-L81):
	External calls:
	- [lp = _ensurePair()](src/core/LiquidityEngine.sol#L78)
		- [lp = IJoeFactory(factory).createPair(usdc,mebtc)](src/core/LiquidityEngine.sol#L89)
	- [_autoCompound(lp)](src/core/LiquidityEngine.sol#L79)
		- [minted = IJoePair(lp).mint(address(this))](src/core/LiquidityEngine.sol#L151)
		- [require(bool,string)(IJoePair(lp).transfer(lp,burnAmount),lp transfer)](src/core/LiquidityEngine.sol#L102)
		- [(amount0,amount1) = IJoePair(lp).burn(address(this))](src/core/LiquidityEngine.sol#L103)
	- [_addLiquidity(lp)](src/core/LiquidityEngine.sol#L80)
		- [demandVault.transferTo(lp,usdcIn)](src/core/LiquidityEngine.sol#L119)
		- [feeVaultMeBTC.transferTo(lp,mebtcIn)](src/core/LiquidityEngine.sol#L120)
		- [minted = IJoePair(lp).mint(address(this))](src/core/LiquidityEngine.sol#L122)
	Event emitted after the call(s):
	- [EpochExecuted(lastEpoch,usdcIn,mebtcIn,minted)](src/core/LiquidityEngine.sol#L123)
		- [_addLiquidity(lp)](src/core/LiquidityEngine.sol#L80)

src/core/LiquidityEngine.sol#L73-L81


 - [ ] ID-57
Reentrancy in [LiquidityEngine._ensurePair()](src/core/LiquidityEngine.sol#L83-L93):
	External calls:
	- [lp = IJoeFactory(factory).createPair(usdc,mebtc)](src/core/LiquidityEngine.sol#L89)
	Event emitted after the call(s):
	- [PairCreated(lp)](src/core/LiquidityEngine.sol#L92)

src/core/LiquidityEngine.sol#L83-L93


 - [ ] ID-58
Reentrancy in [LiquidityEngine.executeEpoch()](src/core/LiquidityEngine.sol#L73-L81):
	External calls:
	- [lp = _ensurePair()](src/core/LiquidityEngine.sol#L78)
		- [lp = IJoeFactory(factory).createPair(usdc,mebtc)](src/core/LiquidityEngine.sol#L89)
	- [_autoCompound(lp)](src/core/LiquidityEngine.sol#L79)
		- [minted = IJoePair(lp).mint(address(this))](src/core/LiquidityEngine.sol#L151)
		- [require(bool,string)(IJoePair(lp).transfer(lp,burnAmount),lp transfer)](src/core/LiquidityEngine.sol#L102)
		- [(amount0,amount1) = IJoePair(lp).burn(address(this))](src/core/LiquidityEngine.sol#L103)
	Event emitted after the call(s):
	- [AutoCompounded(burnAmount,usdcAmt,mebtcAmt,minted)](src/core/LiquidityEngine.sol#L107)
		- [_autoCompound(lp)](src/core/LiquidityEngine.sol#L79)

src/core/LiquidityEngine.sol#L73-L81


 - [ ] ID-59
Reentrancy in [LiquidityEngine._autoCompound(address)](src/core/LiquidityEngine.sol#L95-L108):
	External calls:
	- [require(bool,string)(IJoePair(lp).transfer(lp,burnAmount),lp transfer)](src/core/LiquidityEngine.sol#L102)
	- [(amount0,amount1) = IJoePair(lp).burn(address(this))](src/core/LiquidityEngine.sol#L103)
	- [minted = _mintLiquidity(lp,usdcAmt,mebtcAmt)](src/core/LiquidityEngine.sol#L106)
		- [minted = IJoePair(lp).mint(address(this))](src/core/LiquidityEngine.sol#L151)
	Event emitted after the call(s):
	- [AutoCompounded(burnAmount,usdcAmt,mebtcAmt,minted)](src/core/LiquidityEngine.sol#L107)

src/core/LiquidityEngine.sol#L95-L108


 - [ ] ID-60
Reentrancy in [LiquidityEngine._addLiquidity(address)](src/core/LiquidityEngine.sol#L110-L124):
	External calls:
	- [demandVault.transferTo(lp,usdcIn)](src/core/LiquidityEngine.sol#L119)
	- [feeVaultMeBTC.transferTo(lp,mebtcIn)](src/core/LiquidityEngine.sol#L120)
	- [minted = IJoePair(lp).mint(address(this))](src/core/LiquidityEngine.sol#L122)
	Event emitted after the call(s):
	- [EpochExecuted(lastEpoch,usdcIn,mebtcIn,minted)](src/core/LiquidityEngine.sol#L123)

src/core/LiquidityEngine.sol#L110-L124


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-61
[MinerNFT.getMinerConfig(uint256)](src/nft/MinerNFT.sol#L287-L301) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(s.modelId != 0,model!)](src/nft/MinerNFT.sol#L293)

src/nft/MinerNFT.sol#L287-L301


 - [ ] ID-62
[MinerNFT.getMinerData(uint256)](src/nft/MinerNFT.sol#L265-L280) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(s.modelId != 0,model!)](src/nft/MinerNFT.sol#L267)

src/nft/MinerNFT.sol#L265-L280


 - [ ] ID-63
[TwapOracleJoeV2.updateIfDue()](src/core/TwapOracleJoeV2.sol#L94-L123) uses timestamp for comparisons
	Dangerous comparisons:
	- [blockTimestamp <= lastTimestamp](src/core/TwapOracleJoeV2.sol#L96)
	- [elapsed < updateInterval](src/core/TwapOracleJoeV2.sol#L99)
	- [priceUsdc > 0](src/core/TwapOracleJoeV2.sol#L112)

src/core/TwapOracleJoeV2.sol#L94-L123


 - [ ] ID-64
[MiningManager._simulateUpdate()](src/core/MiningManager.sol#L533-L562) uses timestamp for comparisons
	Dangerous comparisons:
	- [ts <= _lastUpdate](src/core/MiningManager.sol#L546)
	- [ts >= _lastUpdate + CLAIM_INTERVAL && slotsProcessed < MAX_SLOTS_PER_UPDATE](src/core/MiningManager.sol#L549)

src/core/MiningManager.sol#L533-L562


 - [ ] ID-65
[TwapOracleJoeV2.priceMebtcInUsdc()](src/core/TwapOracleJoeV2.sol#L73-L92) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(elapsed >= window,window)](src/core/TwapOracleJoeV2.sol#L79)
	- [require(bool,string)(priceUsdc > 0,price)](src/core/TwapOracleJoeV2.sol#L90)

src/core/TwapOracleJoeV2.sol#L73-L92


 - [ ] ID-66
[MiningManager._settleWithEff(uint256,uint256,uint256)](src/core/MiningManager.sol#L472-L490) uses timestamp for comparisons
	Dangerous comparisons:
	- [last == 0](src/core/MiningManager.sol#L482)
	- [intervals > 0](src/core/MiningManager.sol#L485)

src/core/MiningManager.sol#L472-L490


 - [ ] ID-67
[StakeVault.unstake(uint256)](src/core/StakeVault.sol#L67-L82) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp >= unlockTime[msg.sender],locked)](src/core/StakeVault.sol#L69)

src/core/StakeVault.sol#L67-L82


 - [ ] ID-68
[MinerNFT.setLastClaimAt(uint256,uint40)](src/nft/MinerNFT.sol#L493-L496) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(minerState[tokenId].modelId != 0,model!)](src/nft/MinerNFT.sol#L494)

src/nft/MinerNFT.sol#L493-L496


 - [ ] ID-69
[TwapOracleJoeV2.getPriceForFees()](src/core/TwapOracleJoeV2.sol#L125-L132) uses timestamp for comparisons
	Dangerous comparisons:
	- [price == 0 || ts == 0](src/core/TwapOracleJoeV2.sol#L128)
	- [block.timestamp < ts](src/core/TwapOracleJoeV2.sol#L129)
	- [isFresh = age <= maxPriceAge](src/core/TwapOracleJoeV2.sol#L131)

src/core/TwapOracleJoeV2.sol#L125-L132


 - [ ] ID-70
[TwapOracleJoeV2._currentCumulativePrices()](src/core/TwapOracleJoeV2.sol#L139-L155) uses timestamp for comparisons
	Dangerous comparisons:
	- [blockTimestampLast != blockTimestamp && reserve0 > 0 && reserve1 > 0](src/core/TwapOracleJoeV2.sol#L148)

src/core/TwapOracleJoeV2.sol#L139-L155


 - [ ] ID-71
[MiningManager._update()](src/core/MiningManager.sol#L492-L531) uses timestamp for comparisons
	Dangerous comparisons:
	- [ts <= lastUpdate](src/core/MiningManager.sol#L495)
	- [ts >= _last + CLAIM_INTERVAL && slotsProcessed < MAX_SLOTS_PER_UPDATE](src/core/MiningManager.sol#L510)

src/core/MiningManager.sol#L492-L531


 - [ ] ID-72
[MinerNFT.applyPendingUpgrades(uint256)](src/nft/MinerNFT.sol#L498-L525) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(s.modelId != 0,model!)](src/nft/MinerNFT.sol#L500)

src/nft/MinerNFT.sol#L498-L525


 - [ ] ID-73
[MinerNFT._requestUpgradePower(uint256,uint16)](src/nft/MinerNFT.sol#L437-L460) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(s.modelId != 0,model!)](src/nft/MinerNFT.sol#L441)

src/nft/MinerNFT.sol#L437-L460


 - [ ] ID-74
[MinerNFT.getMinerState(uint256)](src/nft/MinerNFT.sol#L282-L285) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(minerState[tokenId].modelId != 0,model!)](src/nft/MinerNFT.sol#L283)

src/nft/MinerNFT.sol#L282-L285


 - [ ] ID-75
[MinerNFT._requestUpgradeHash(uint256,uint16)](src/nft/MinerNFT.sol#L462-L485) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(s.modelId != 0,model!)](src/nft/MinerNFT.sol#L466)

src/nft/MinerNFT.sol#L462-L485


 - [ ] ID-76
[StakeVault.stake(uint256)](src/core/StakeVault.sol#L45-L65) uses timestamp for comparisons
	Dangerous comparisons:
	- [newUnlock > unlockTime[msg.sender]](src/core/StakeVault.sol#L58)

src/core/StakeVault.sol#L45-L65


 - [ ] ID-77
[TwapOracleJoeV2.isReady()](src/core/TwapOracleJoeV2.sol#L64-L71) uses timestamp for comparisons
	Dangerous comparisons:
	- [elapsed >= window](src/core/TwapOracleJoeV2.sol#L70)

src/core/TwapOracleJoeV2.sol#L64-L71


 - [ ] ID-78
[LiquidityEngine.executeEpoch()](src/core/LiquidityEngine.sol#L73-L81) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp >= nextEpoch,epoch)](src/core/LiquidityEngine.sol#L75)

src/core/LiquidityEngine.sol#L73-L81


 - [ ] ID-79
[MiningManager.preview(uint256,address)](src/core/MiningManager.sol#L443-L462) uses timestamp for comparisons
	Dangerous comparisons:
	- [last == 0](src/core/MiningManager.sol#L453)
	- [intervals > 0](src/core/MiningManager.sol#L456)

src/core/MiningManager.sol#L443-L462


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-80
[MiningManager.onStakeChange(address)](src/core/MiningManager.sol#L174-L196) has costly operations inside a loop:
	- [totalEffectiveHash += (effHash - oldEffHash)](src/core/MiningManager.sol#L188)

src/core/MiningManager.sol#L174-L196


 - [ ] ID-81
[MiningManager.onStakeChange(address)](src/core/MiningManager.sol#L174-L196) has costly operations inside a loop:
	- [totalEffectiveHash -= (oldEffHash - effHash)](src/core/MiningManager.sol#L190)

src/core/MiningManager.sol#L174-L196


 - [ ] ID-82
[MinerNFT.buyFromModel(uint16,uint256)](src/nft/MinerNFT.sol#L304-L354) has costly operations inside a loop:
	- [tokenId = nextTokenId ++](src/nft/MinerNFT.sol#L335)

src/nft/MinerNFT.sol#L304-L354


## missing-inheritance
Impact: Informational
Confidence: High
 - [ ] ID-83
[TwapOracleJoeV2](src/core/TwapOracleJoeV2.sol#L14-L161) should inherit from [ILiquidityOracle](src/nft/MinerNFT.sol#L35-L37)

src/core/TwapOracleJoeV2.sol#L14-L161


 - [ ] ID-84
[MiningManager](src/core/MiningManager.sol#L55-L563) should inherit from [IMiningManagerHook](src/nft/MinerNFT.sol#L30-L33)

src/core/MiningManager.sol#L55-L563


 - [ ] ID-85
[StakeVault](src/core/StakeVault.sol#L12-L115) should inherit from [IStakeVault](src/core/MiningManager.sol#L48-L53)

src/core/StakeVault.sol#L12-L115


 - [ ] ID-86
[MiningManager](src/core/MiningManager.sol#L55-L563) should inherit from [IStakeChangeHook](src/core/StakeVault.sol#L8-L10)

src/core/MiningManager.sol#L55-L563


 - [ ] ID-87
[MinerNFT](src/nft/MinerNFT.sol#L39-L586) should inherit from [IMinerNFT](src/core/MiningManager.sol#L33-L46)

src/nft/MinerNFT.sol#L39-L586


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-88
Parameter [MiningManager.setPayToken(address)._payToken](src/core/MiningManager.sol#L127) is not in mixedCase

src/core/MiningManager.sol#L127


 - [ ] ID-89
Parameter [MinerNFT.setLiquidityOracle(address)._oracle](src/nft/MinerNFT.sol#L202) is not in mixedCase

src/nft/MinerNFT.sol#L202


 - [ ] ID-90
Parameter [MiningManager.init(address,address,address,address,address,address)._feeVaultMeBTC](src/core/MiningManager.sol#L140) is not in mixedCase

src/core/MiningManager.sol#L140


 - [ ] ID-91
Parameter [MiningManager.init(address,address,address,address,address,address)._demandVault](src/core/MiningManager.sol#L139) is not in mixedCase

src/core/MiningManager.sol#L139


 - [ ] ID-92
Parameter [MinerNFT.setPayToken(address)._payToken](src/nft/MinerNFT.sol#L164) is not in mixedCase

src/nft/MinerNFT.sol#L164


 - [ ] ID-93
Parameter [TokenVault.init(address)._engine](src/core/TokenVault.sol#L20) is not in mixedCase

src/core/TokenVault.sol#L20


 - [ ] ID-94
Function [IMeBTC.MAX_SUPPLY()](src/core/MiningManager.sol#L29) is not in mixedCase

src/core/MiningManager.sol#L29


 - [ ] ID-95
Parameter [MiningManager.init(address,address,address,address,address,address)._mebtc](src/core/MiningManager.sol#L136) is not in mixedCase

src/core/MiningManager.sol#L136


 - [ ] ID-96
Parameter [MiningManager.init(address,address,address,address,address,address)._twapOracle](src/core/MiningManager.sol#L141) is not in mixedCase

src/core/MiningManager.sol#L141


 - [ ] ID-97
Parameter [MiningManager.init(address,address,address,address,address,address)._miner](src/core/MiningManager.sol#L137) is not in mixedCase

src/core/MiningManager.sol#L137


 - [ ] ID-98
Parameter [MiningManager.init(address,address,address,address,address,address)._stakeVault](src/core/MiningManager.sol#L138) is not in mixedCase

src/core/MiningManager.sol#L138


 - [ ] ID-99
Parameter [MinerNFT.setManager(address)._manager](src/nft/MinerNFT.sol#L158) is not in mixedCase

src/nft/MinerNFT.sol#L158


