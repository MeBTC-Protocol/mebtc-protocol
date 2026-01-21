// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ITwapOracle} from "./ITwapOracle.sol";

/*
    MiningManager (upgrades become active after claim)
    - MinerNFT requestet upgrades (pending)
    - Manager macht claim:
        settle reward + fee mit ALTEN Werten
        zieht USDC
        mintet MeBTC
        setzt lastClaimAt
        ruft applyPendingUpgrades(tokenId) -> erst dann ändern sich aktive stats
*/

interface IMeBTC {
    function totalSupply() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
    function mint(address to, uint256 amount) external;
}

interface IMinerNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function getMinerData(uint256 tokenId) external view returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt);
    function getMinerConfig(uint256 tokenId)
        external
        view
        returns (uint256 baseHashrate, uint256 basePowerWatt, uint16 hashUpgradeBps, uint16 powerUpgradeBps, uint256 createdAt);

    function setLastClaimAt(uint256 tokenId, uint40 ts) external;

    // after claim apply pending -> active (may call manager hook for hash change)
    function applyPendingUpgrades(uint256 tokenId) external;
}

interface IStakeVault {
    function getStakeInfo(address user)
        external
        view
        returns (uint256 balance, uint8 tier, uint64 unlockAt, uint16 hashBonusBps, uint16 powerBonusBps);
}

contract MiningManager is ReentrancyGuard, Ownable {
    uint256 public constant CLAIM_INTERVAL = 600;       // 10 Minuten
    uint256 public constant HALVING_BLOCKS = 210_000;   // Slots bis Halving
    uint8 public constant MEBTC_DECIMALS = 8;
    uint256 private constant MEBTC_UNIT = 1e8;
    uint256 public constant INITIAL_REWARD = 50 * MEBTC_UNIT; // MBTC pro Slot (Netzwerk)

    uint256 public constant FEE_PER_KWH = 150_000;      // 0.15 USDC (6 dec)
    uint256 private constant KWH_DENOM = 3_600_000;     // 1000*3600

    uint16 public constant MAX_MEBTC_SHARE_BPS = 3000; // 30%

    IERC20 public payToken;
    address public demandVault;
    address public feeVaultMeBTC;
    ITwapOracle public twapOracle;

    IMeBTC      public meBTC;
    IMinerNFT   public minerNFT;
    IStakeVault public stakeVault;

    address private initializer;

    uint256 public lastUpdate;
    uint256 public blockIndex;
    uint256 public currentReward;

    uint256 public accRewardPerEffHash; // 1e12 scale
    uint256 public accRewardRemainder;  // reward*1e12 remainder carried across slots
    uint256 public totalEffectiveHash;

    mapping(uint256 => uint256) public lastAccPerHash;
    mapping(uint256 => uint256) public pendingReward;
    mapping(uint256 => uint256) public pendingRewardRemainder; // per-miner remainder (scaled by 1e12)
    mapping(uint256 => uint256) public lastSettleTime;
    mapping(uint256 => uint256) public debtUSDC;
    mapping(uint256 => uint256) public lastClaimedBlockIndex;
    mapping(uint256 => uint256) public currentEffHash;
    mapping(uint256 => uint256) public currentEffPower;
    mapping(uint256 => uint256) public activationTime;
    mapping(uint256 => uint256) public pendingEffHash;
    mapping(uint256 => uint256) public pendingEffPower;
    mapping(uint256 => uint256) public pendingHashByTime;
    mapping(uint256 => uint256[]) private pendingTokensByTime;
    mapping(address => uint256[]) private ownerTokens;
    mapping(uint256 => uint256) private ownerTokenIndex;

    event Updated(uint256 slots, uint256 minted, uint256 acc);
    event RewardsClaimed(address indexed user, uint256 reward, uint256 fee);
    event MinerMoved(address indexed from, address indexed to, uint256 indexed tokenId, uint256 effHashAdded);
    event MinerUpgraded(address indexed owner, uint256 indexed tokenId, uint256 oldEffHash, uint256 newEffHash);
    event Initialized(address mebtc, address miner, address stakeVault, address demandVault, address feeVaultMeBTC, address twapOracle);
    event PayTokenUpdated(address indexed oldToken, address indexed newToken);
    event MinerResynced(uint256 indexed tokenId, uint256 oldEffHash, uint256 newEffHash);

    modifier onlyInit() {
        require(msg.sender == initializer, "!init");
        _;
    }

    constructor(address _payToken) Ownable(msg.sender) {
        require(_payToken != address(0), "arg=0");
        require(IERC20Metadata(_payToken).decimals() == 6, "decimals");
        payToken = IERC20(_payToken);

        initializer = msg.sender;
        lastUpdate = block.timestamp;
        currentReward = INITIAL_REWARD;
    }

    function setPayToken(address _payToken) external onlyOwner {
        require(_payToken != address(0), "token=0");
        require(IERC20Metadata(_payToken).decimals() == 6, "decimals");
        address oldToken = address(payToken);
        payToken = IERC20(_payToken);
        emit PayTokenUpdated(oldToken, _payToken);
    }

    function init(
        address _mebtc,
        address _miner,
        address _stakeVault,
        address _demandVault,
        address _feeVaultMeBTC,
        address _twapOracle
    ) external onlyInit {
        require(
            address(meBTC) == address(0) &&
                address(minerNFT) == address(0) &&
                address(stakeVault) == address(0) &&
                demandVault == address(0) &&
                feeVaultMeBTC == address(0) &&
                address(twapOracle) == address(0),
            "inited"
        );
        require(
            _mebtc != address(0) &&
                _miner != address(0) &&
                _stakeVault != address(0) &&
                _demandVault != address(0) &&
                _feeVaultMeBTC != address(0) &&
                _twapOracle != address(0),
            "0"
        );

        meBTC = IMeBTC(_mebtc);
        minerNFT = IMinerNFT(_miner);
        stakeVault = IStakeVault(_stakeVault);

        demandVault = _demandVault;
        feeVaultMeBTC = _feeVaultMeBTC;
        twapOracle = ITwapOracle(_twapOracle);

        initializer = address(0);
        emit Initialized(_mebtc, _miner, _stakeVault, _demandVault, _feeVaultMeBTC, _twapOracle);
    }

    function onStakeChange(address owner) external {
        require(msg.sender == address(stakeVault), "!stake");
        _update();

        uint256[] storage ids = ownerTokens[owner];
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 actTime = activationTime[id];
            if (actTime != 0) {
                (uint256 newEffHash, uint256 newEffPower,) = _computeEffForOwner(id, owner);
                uint256 oldPending = pendingEffHash[id];
                if (oldPending > 0) {
                    if (pendingHashByTime[actTime] >= oldPending) {
                        pendingHashByTime[actTime] -= oldPending;
                    } else {
                        pendingHashByTime[actTime] = 0;
                    }
                }
                pendingEffHash[id] = newEffHash;
                pendingEffPower[id] = newEffPower;
                pendingHashByTime[actTime] += newEffHash;
                continue;
            }

            uint256 oldEffHash = currentEffHash[id];
            uint256 oldEffPower = currentEffPower[id];
            _settleWithEff(id, oldEffHash, oldEffPower);
            lastSettleTime[id] = block.timestamp;

            (uint256 effHash, uint256 effPower,) = _computeEffForOwner(id, owner);
            if (effHash > oldEffHash) {
                totalEffectiveHash += (effHash - oldEffHash);
            } else if (oldEffHash > effHash) {
                totalEffectiveHash -= (oldEffHash - effHash);
            }

            currentEffHash[id] = effHash;
            currentEffPower[id] = effPower;
        }
    }

    function _computeEffForOwner(uint256 tokenId, address owner)
        internal
        view
        returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt)
    {
        (uint256 baseHash, uint256 basePower, uint16 hashBps, uint16 powerBps, uint256 created) =
            minerNFT.getMinerConfig(tokenId);

        uint256 effHashAfter = (baseHash * (10_000 + uint256(hashBps))) / 10_000;

        uint256 pbps = uint256(powerBps);
        if (pbps > 10_000) pbps = 10_000;
        uint256 effPowerAfter = (basePower * (10_000 - pbps)) / 10_000;

        (, , , uint16 stakeHashBps, uint16 stakePowerBps) = stakeVault.getStakeInfo(owner);

        uint256 stakeHashBonus = (baseHash * uint256(stakeHashBps)) / 10_000;
        uint256 stakePowerBonus = (effPowerAfter * uint256(stakePowerBps)) / 10_000;

        effHash = effHashAfter + stakeHashBonus;
        effPowerWatt = effPowerAfter - stakePowerBonus;
        createdAt = created;
    }

    function _addOwnerToken(address owner, uint256 tokenId) internal {
        ownerTokenIndex[tokenId] = ownerTokens[owner].length;
        ownerTokens[owner].push(tokenId);
    }

    function _removeOwnerToken(address owner, uint256 tokenId) internal {
        uint256 idx = ownerTokenIndex[tokenId];
        uint256 lastIdx = ownerTokens[owner].length - 1;
        if (idx != lastIdx) {
            uint256 lastId = ownerTokens[owner][lastIdx];
            ownerTokens[owner][idx] = lastId;
            ownerTokenIndex[lastId] = idx;
        }
        ownerTokens[owner].pop();
    }

    // called by MinerNFT on mint/transfer
    function onMinerTransfer(address from, address to, uint256 tokenId, uint256 /*baseHashRate*/) external {
        require(msg.sender == address(minerNFT), "!miner");
        _update();
        uint256 actTime = activationTime[tokenId];
        bool wasPending = actTime != 0;

        if (from != address(0)) {
            _removeOwnerToken(from, tokenId);

            if (!wasPending) {
                _settleWithEff(tokenId, currentEffHash[tokenId], currentEffPower[tokenId]);
                if (totalEffectiveHash >= currentEffHash[tokenId]) totalEffectiveHash -= currentEffHash[tokenId];
            } else {
                uint256 oldPending = pendingEffHash[tokenId];
                if (oldPending > 0) {
                    if (pendingHashByTime[actTime] >= oldPending) {
                        pendingHashByTime[actTime] -= oldPending;
                    } else {
                        pendingHashByTime[actTime] = 0;
                    }
                }
            }

            if (to == address(0)) {
                activationTime[tokenId] = 0;
                pendingEffHash[tokenId] = 0;
                pendingEffPower[tokenId] = 0;
            }

            currentEffHash[tokenId] = 0;
            currentEffPower[tokenId] = 0;
        }

        if (to != address(0)) {
            _addOwnerToken(to, tokenId);
            (uint256 effHash, uint256 effPower,) = _computeEffForOwner(tokenId, to);

            if (from == address(0) && totalEffectiveHash == 0) {
                // start emission clock when first miner becomes active
                lastUpdate = block.timestamp;
            }
            if (from == address(0)) {
                uint256 newActTime = lastUpdate + CLAIM_INTERVAL;
                activationTime[tokenId] = newActTime;
                pendingEffHash[tokenId] = effHash;
                pendingEffPower[tokenId] = effPower;
                pendingHashByTime[newActTime] += effHash;
                pendingTokensByTime[newActTime].push(tokenId);
                lastAccPerHash[tokenId] = accRewardPerEffHash;
                lastSettleTime[tokenId] = 0;
                lastClaimedBlockIndex[tokenId] = blockIndex;
            } else if (wasPending) {
                pendingEffHash[tokenId] = effHash;
                pendingEffPower[tokenId] = effPower;
                pendingHashByTime[actTime] += effHash;
            } else {
                lastAccPerHash[tokenId] = accRewardPerEffHash;
                lastSettleTime[tokenId] = block.timestamp;
                totalEffectiveHash += effHash;
                currentEffHash[tokenId] = effHash;
                currentEffPower[tokenId] = effPower;
            }
        }

        emit MinerMoved(from, to, tokenId, currentEffHash[tokenId]);
    }

    // called by MinerNFT ONLY when pending upgrades are applied (after claim)
    function onMinerUpgradeHashChange(address owner, uint256 tokenId, uint256 oldEffHash, uint256 newEffHash) external {
        require(msg.sender == address(minerNFT), "!miner");
        require(owner != address(0), "owner=0");

        oldEffHash;
        newEffHash;

        (uint256 effHash, uint256 effPower,) = _computeEffForOwner(tokenId, owner);
        uint256 prevEffHash = currentEffHash[tokenId];

        if (effHash > prevEffHash) {
            totalEffectiveHash += (effHash - prevEffHash);
        } else if (prevEffHash > effHash) {
            totalEffectiveHash -= (prevEffHash - effHash);
        }

        currentEffHash[tokenId] = effHash;
        currentEffPower[tokenId] = effPower;
        emit MinerUpgraded(owner, tokenId, prevEffHash, effHash);
    }

    function resyncMiner(uint256 tokenId) external {
        address owner;
        try minerNFT.ownerOf(tokenId) returns (address o) {
            owner = o;
        } catch {
            owner = address(0);
        }

        uint256 expectedHash;
        uint256 expectedPower;
        if (owner != address(0)) {
            (uint256 effHash, uint256 effPower,) = _computeEffForOwner(tokenId, owner);
            uint256 actTime = activationTime[tokenId];
            if (actTime == 0 || block.timestamp >= actTime) {
                expectedHash = effHash;
                expectedPower = effPower;
            }
        }

        uint256 current = currentEffHash[tokenId];
        if (current == expectedHash) return;

        if (expectedHash > current) {
            totalEffectiveHash += (expectedHash - current);
        } else {
            uint256 diff = current - expectedHash;
            require(totalEffectiveHash >= diff, "total");
            totalEffectiveHash -= diff;
        }

        currentEffHash[tokenId] = expectedHash;
        currentEffPower[tokenId] = expectedPower;
        emit MinerResynced(tokenId, current, expectedHash);
    }

    function claim(uint256[] calldata ids) external nonReentrant {
        _claim(ids, 0);
    }

    function claimWithMebtc(uint256[] calldata ids, uint16 mebtcShareBps) external nonReentrant {
        _claim(ids, mebtcShareBps);
    }

    function _claim(uint256[] calldata ids, uint16 mebtcShareBps) internal {
        _update();

        uint256 outR;
        uint256 outF;
        uint40 nowTs = uint40(block.timestamp);

        // 1) check eligibility for all IDs (must have a completed global slot)
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            require(minerNFT.ownerOf(id) == msg.sender, "!owner");
            require(blockIndex > lastClaimedBlockIndex[id], "slot");
        }

        // 2) settle alle IDs (alte stats)
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            _settle(id);

            outR += pendingReward[id];
            outF += debtUSDC[id];

            pendingReward[id] = 0;
            debtUSDC[id] = 0;

            minerNFT.setLastClaimAt(id, nowTs);
            lastSettleTime[id] = nowTs;
            lastAccPerHash[id] = accRewardPerEffHash;
            lastClaimedBlockIndex[id] = blockIndex;
        }

        // 3) collect fee
        if (outF > 0) {
            require(mebtcShareBps <= MAX_MEBTC_SHARE_BPS, "mebtc%");
            _collectFees(msg.sender, outF, mebtcShareBps);
        }

        // 4) mint reward
        if (outR > 0) {
            uint256 remain = meBTC.MAX_SUPPLY() - meBTC.totalSupply();
            if (outR > remain) outR = remain;
            if (outR > 0) meBTC.mint(msg.sender, outR);
        }

        // 5) jetzt erst upgrades aktivieren (wirkt ab jetzt)
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            // applyPendingUpgrades kann manager hook onMinerUpgradeHashChange auslösen
            minerNFT.applyPendingUpgrades(id);
        }

        emit RewardsClaimed(msg.sender, outR, outF);
    }

    function _collectFees(address payer, uint256 feeUSDC, uint16 mebtcShareBps) internal {
        if (mebtcShareBps == 0) {
            require(payToken.allowance(payer, address(this)) >= feeUSDC, "allowance");
            require(payToken.balanceOf(payer) >= feeUSDC, "balance");
            require(payToken.transferFrom(payer, demandVault, feeUSDC), "paytoken");
            return;
        }

        require(twapOracle.isReady(), "twap");
        uint256 price = twapOracle.priceMebtcInUsdc();
        require(price > 0, "price");

        uint256 mebtcUsdc = (feeUSDC * mebtcShareBps) / 10_000;
        uint256 usdcPart = feeUSDC - mebtcUsdc;

        if (usdcPart > 0) {
            require(payToken.allowance(payer, address(this)) >= usdcPart, "allowance");
            require(payToken.balanceOf(payer) >= usdcPart, "balance");
            require(payToken.transferFrom(payer, demandVault, usdcPart), "paytoken");
        }

        uint256 mebtcAmount = (mebtcUsdc * MEBTC_UNIT) / price;
        if (mebtcAmount > 0) {
            IERC20 mebtcErc20 = IERC20(address(meBTC));
            require(mebtcErc20.allowance(payer, address(this)) >= mebtcAmount, "mebtc allowance");
            require(mebtcErc20.balanceOf(payer) >= mebtcAmount, "mebtc balance");
            require(mebtcErc20.transferFrom(payer, feeVaultMeBTC, mebtcAmount), "mebtc");
        }
    }

    function preview(uint256 id, address owner) external view returns (uint256 r, uint256 f) {
        uint256 actTime = activationTime[id];
        if (actTime != 0 && block.timestamp < actTime) {
            return (pendingReward[id], debtUSDC[id]);
        }
        (uint256 areh,,,) = _simulateUpdate();

        uint256 delta = areh - lastAccPerHash[id];
        (uint256 effHash, uint256 effPowerWatt,) = _computeEffForOwner(id, owner);

        uint256 scaled = (effHash * delta) + pendingRewardRemainder[id];
        r = pendingReward[id] + (scaled / 1e12);

        uint256 last = lastSettleTime[id];
        if (last == 0) {
            if (actTime != 0 && block.timestamp >= actTime) {
                last = actTime;
            } else {
                last = block.timestamp;
            }
        }

        uint256 intervals = (block.timestamp - last) / CLAIM_INTERVAL;
        if (intervals > 0) {
            uint256 perIntervalFee = _feeForInterval(effPowerWatt);
            f = debtUSDC[id] + intervals * perIntervalFee;
        } else {
            f = debtUSDC[id];
        }
    }

    function _feeForInterval(uint256 powerWatt) internal pure returns (uint256) {
        return (powerWatt * CLAIM_INTERVAL * FEE_PER_KWH) / KWH_DENOM;
    }

    function _activateAtTime(uint256 actTime) internal {
        uint256 added = pendingHashByTime[actTime];
        if (added == 0) return;

        totalEffectiveHash += added;
        pendingHashByTime[actTime] = 0;

        uint256[] storage ids = pendingTokensByTime[actTime];
        for (uint256 i; i < ids.length; i++) {
            uint256 id = ids[i];
            if (activationTime[id] != actTime) continue;
            uint256 effHash = pendingEffHash[id];
            uint256 effPower = pendingEffPower[id];
            if (effHash == 0) {
                activationTime[id] = 0;
                continue;
            }
            lastAccPerHash[id] = accRewardPerEffHash;
            lastSettleTime[id] = actTime;
            currentEffHash[id] = effHash;
            currentEffPower[id] = effPower;
            activationTime[id] = 0;
            pendingEffHash[id] = 0;
            pendingEffPower[id] = 0;
        }

        delete pendingTokensByTime[actTime];
    }

    function _settle(uint256 id) internal {
        uint256 actTime = activationTime[id];
        if (actTime != 0 && block.timestamp < actTime) return;
        _settleWithEff(id, currentEffHash[id], currentEffPower[id]);
    }

    function _settleWithEff(uint256 id, uint256 effHash, uint256 effPowerWatt) internal {
        uint256 delta = accRewardPerEffHash - lastAccPerHash[id];
        if (delta > 0) {
            uint256 scaled = (effHash * delta) + pendingRewardRemainder[id];
            pendingReward[id] += scaled / 1e12;
            pendingRewardRemainder[id] = scaled % 1e12;
            lastAccPerHash[id] = accRewardPerEffHash;
        }

        uint256 last = lastSettleTime[id];
        if (last == 0) {
            uint256 activeAt = activationTime[id];
            if (activeAt != 0 && block.timestamp >= activeAt) {
                last = activeAt;
            } else {
                last = block.timestamp;
            }
        }

        uint256 intervals = (block.timestamp - last) / CLAIM_INTERVAL;
        if (intervals > 0) {
            uint256 perIntervalFee = _feeForInterval(effPowerWatt);
            debtUSDC[id] += intervals * perIntervalFee;
            lastSettleTime[id] = last + intervals * CLAIM_INTERVAL;
        }
    }

    function _update() internal {
        uint256 ts = block.timestamp;

        if (totalEffectiveHash == 0) {
            if (ts < lastUpdate + CLAIM_INTERVAL) return;
            lastUpdate += CLAIM_INTERVAL;
            _activateAtTime(lastUpdate);
            if (totalEffectiveHash == 0) return;
        }

        if (ts < lastUpdate + CLAIM_INTERVAL) return;

        uint256 minted;
        uint256 intervals;
        uint256 rw = currentReward;

        while (ts >= lastUpdate + CLAIM_INTERVAL) {
            minted += rw;
            uint256 numerator = (rw * 1e12) + accRewardRemainder;
            accRewardPerEffHash += numerator / totalEffectiveHash;
            accRewardRemainder = numerator % totalEffectiveHash;
            lastUpdate += CLAIM_INTERVAL;
            blockIndex += 1;
            intervals += 1;
            if (blockIndex % HALVING_BLOCKS == 0) {
                rw = rw / 2;
            }
            _activateAtTime(lastUpdate);
            if (totalEffectiveHash == 0) break;
        }

        currentReward = rw;
        emit Updated(intervals, minted, accRewardPerEffHash);
    }

    function _simulateUpdate()
        internal
        view
        returns (uint256 areh, uint256 li, uint256 rw, uint256 last)
    {
        uint256 ts = block.timestamp;
        uint256 _lastUpdate = lastUpdate;
        uint256 _li = blockIndex;
        uint256 _rw = currentReward;
        uint256 _total = totalEffectiveHash;
        uint256 _areh = accRewardPerEffHash;
        uint256 _rem = accRewardRemainder;
        uint256 intervals;
        uint256 minted;

        if (_total == 0) {
            if (ts < _lastUpdate + CLAIM_INTERVAL) {
                return (_areh, _li, _rw, _lastUpdate);
            }
            _lastUpdate += CLAIM_INTERVAL;
            uint256 pending = pendingHashByTime[_lastUpdate];
            if (pending > 0) {
                _total += pending;
            }
            if (_total == 0) {
                return (_areh, _li, _rw, _lastUpdate);
            }
        }

        while (ts >= _lastUpdate + CLAIM_INTERVAL) {
            minted += _rw;
            uint256 numerator = (_rw * 1e12) + _rem;
            _areh += numerator / _total;
            _rem = numerator % _total;
            _lastUpdate += CLAIM_INTERVAL;
            _li += 1;
            intervals += 1;
            if (_li % HALVING_BLOCKS == 0) {
                _rw = _rw / 2;
            }
            uint256 pending = pendingHashByTime[_lastUpdate];
            if (pending > 0) {
                _total += pending;
            }
            if (_total == 0) break;
        }

        return (_areh, _li, _rw, _lastUpdate);
    }
}
