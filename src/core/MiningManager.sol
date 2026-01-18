// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

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

    // active effective values
    function getMinerData(uint256 tokenId) external view returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt);

    function setLastClaimAt(uint256 tokenId, uint40 ts) external;

    // after claim apply pending -> active (may call manager hook for hash change)
    function applyPendingUpgrades(uint256 tokenId) external;
}

contract MiningManager is ReentrancyGuard, Ownable {
    uint256 public constant CLAIM_INTERVAL = 600;       // 10 Minuten
    uint256 public constant HALVING_BLOCKS = 210_000;   // Slots bis Halving
    uint256 public constant INITIAL_REWARD = 50e18;     // MBTC pro Slot (Netzwerk)

    uint256 public constant FEE_PER_KWH = 150_000;      // 0.15 USDC (6 dec)
    uint256 private constant KWH_DENOM = 3_600_000;     // 1000*3600

    IERC20  public payToken;
    address public immutable pool;

    IMeBTC    public meBTC;
    IMinerNFT public minerNFT;

    address private initializer;

    uint256 public lastUpdate;
    uint256 public blockIndex;
    uint256 public currentReward;

    uint256 public accRewardPerEffHash; // 1e12 scale
    uint256 public totalEffectiveHash;

    mapping(uint256 => uint256) public lastAccPerHash;
    mapping(uint256 => uint256) public pendingReward;
    mapping(uint256 => uint256) public lastSettleTime;
    mapping(uint256 => uint256) public debtUSDC;
    mapping(uint256 => uint256) public lastClaimedBlockIndex;
    mapping(uint256 => uint256) public currentEffHash;
    mapping(uint256 => uint256) public activationTime;
    mapping(uint256 => uint256) public pendingEffHash;
    mapping(uint256 => uint256) public pendingHashByTime;
    mapping(uint256 => uint256[]) private pendingTokensByTime;

    event Updated(uint256 slots, uint256 minted, uint256 acc);
    event RewardsClaimed(address indexed user, uint256 reward, uint256 fee);
    event MinerMoved(address indexed from, address indexed to, uint256 indexed tokenId, uint256 effHashAdded);
    event MinerUpgraded(address indexed owner, uint256 indexed tokenId, uint256 oldEffHash, uint256 newEffHash);
    event Initialized(address mebtc, address miner);
    event PayTokenUpdated(address indexed oldToken, address indexed newToken);
    event MinerResynced(uint256 indexed tokenId, uint256 oldEffHash, uint256 newEffHash);

    modifier onlyInit() {
        require(msg.sender == initializer, "!init");
        _;
    }

    constructor(address _payToken, address _pool) Ownable(msg.sender) {
        require(_payToken != address(0) && _pool != address(0), "arg=0");
        require(IERC20Metadata(_payToken).decimals() == 6, "decimals");
        payToken = IERC20(_payToken);
        pool = _pool;

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

    function init(address _mebtc, address _miner) external onlyInit {
        require(address(meBTC) == address(0) && address(minerNFT) == address(0), "inited");
        require(_mebtc != address(0) && _miner != address(0), "0");

        meBTC = IMeBTC(_mebtc);
        minerNFT = IMinerNFT(_miner);

        initializer = address(0);
        emit Initialized(_mebtc, _miner);
    }

    // called by MinerNFT on mint/transfer
    function onMinerTransfer(address from, address to, uint256 tokenId, uint256 /*baseHashRate*/) external {
        require(msg.sender == address(minerNFT), "!miner");
        _update();

        (uint256 effHash,,) = minerNFT.getMinerData(tokenId);

        if (from != address(0)) {
            if (activationTime[tokenId] == 0) {
                _settle(tokenId);
                if (totalEffectiveHash >= effHash) totalEffectiveHash -= effHash;
            }
        }

        if (to != address(0)) {
            if (from == address(0) && totalEffectiveHash == 0) {
                // start emission clock when first miner becomes active
                lastUpdate = block.timestamp;
            }
            if (from == address(0)) {
                uint256 actTime = lastUpdate + CLAIM_INTERVAL;
                activationTime[tokenId] = actTime;
                pendingEffHash[tokenId] = effHash;
                pendingHashByTime[actTime] += effHash;
                pendingTokensByTime[actTime].push(tokenId);
                lastAccPerHash[tokenId] = accRewardPerEffHash;
                lastSettleTime[tokenId] = 0;
                lastClaimedBlockIndex[tokenId] = blockIndex;
            } else {
                if (activationTime[tokenId] == 0) {
                    lastAccPerHash[tokenId] = accRewardPerEffHash;
                    lastSettleTime[tokenId] = block.timestamp;
                    totalEffectiveHash += effHash;
                    currentEffHash[tokenId] = effHash;
                }
            }
        }
        if (to == address(0)) {
            uint256 act = activationTime[tokenId];
            if (act != 0) {
                uint256 pending = pendingEffHash[tokenId];
                if (pending > 0) {
                    if (pendingHashByTime[act] >= pending) {
                        pendingHashByTime[act] -= pending;
                    } else {
                        pendingHashByTime[act] = 0;
                    }
                }
                pendingEffHash[tokenId] = 0;
                activationTime[tokenId] = 0;
            }
            currentEffHash[tokenId] = 0;
        }

        emit MinerMoved(from, to, tokenId, effHash);
    }

    // called by MinerNFT ONLY when pending upgrades are applied (after claim)
    function onMinerUpgradeHashChange(address owner, uint256 tokenId, uint256 oldEffHash, uint256 newEffHash) external {
        require(msg.sender == address(minerNFT), "!miner");
        require(owner != address(0), "owner=0");

        // nach claim wurde bereits settled und lastAccPerHash korrekt gesetzt,
        // jetzt nur totals anpassen
        if (newEffHash > oldEffHash) {
            totalEffectiveHash += (newEffHash - oldEffHash);
        } else if (oldEffHash > newEffHash) {
            totalEffectiveHash -= (oldEffHash - newEffHash);
        }

        currentEffHash[tokenId] = newEffHash;
        emit MinerUpgraded(owner, tokenId, oldEffHash, newEffHash);
    }

    function resyncMiner(uint256 tokenId) external {
        address owner;
        try minerNFT.ownerOf(tokenId) returns (address o) {
            owner = o;
        } catch {
            owner = address(0);
        }

        uint256 expectedHash;
        if (owner != address(0)) {
            (uint256 effHash,,) = minerNFT.getMinerData(tokenId);
            uint256 actTime = activationTime[tokenId];
            if (actTime == 0 || block.timestamp >= actTime) {
                expectedHash = effHash;
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
        emit MinerResynced(tokenId, current, expectedHash);
    }

    function claim(uint256[] calldata ids) external nonReentrant {
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
            require(payToken.allowance(msg.sender, address(this)) >= outF, "allowance");
            require(payToken.balanceOf(msg.sender) >= outF, "balance");
            require(payToken.transferFrom(msg.sender, pool, outF), "paytoken");
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

    function preview(uint256 id, address owner) external view returns (uint256 r, uint256 f) {
        uint256 actTime = activationTime[id];
        if (actTime != 0 && block.timestamp < actTime) {
            return (pendingReward[id], debtUSDC[id]);
        }
        (uint256 areh,,,) = _simulateUpdate();

        uint256 delta = areh - lastAccPerHash[id];
        (uint256 effHash, uint256 effPowerWatt,) = minerNFT.getMinerData(id);

        r = pendingReward[id] + (effHash * delta) / 1e12;

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

        owner;
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
            if (effHash == 0) {
                activationTime[id] = 0;
                continue;
            }
            lastAccPerHash[id] = accRewardPerEffHash;
            lastSettleTime[id] = actTime;
            currentEffHash[id] = effHash;
            activationTime[id] = 0;
            pendingEffHash[id] = 0;
        }

        delete pendingTokensByTime[actTime];
    }

    function _settle(uint256 id) internal {
        uint256 actTime = activationTime[id];
        if (actTime != 0 && block.timestamp < actTime) return;
        uint256 delta = accRewardPerEffHash - lastAccPerHash[id];
        if (delta > 0) {
            (uint256 effHash,,) = minerNFT.getMinerData(id);
            pendingReward[id] += (effHash * delta) / 1e12;
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
            (, uint256 effPowerWatt,) = minerNFT.getMinerData(id);
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
            accRewardPerEffHash += (rw * 1e12) / totalEffectiveHash;
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
            _areh += (_rw * 1e12) / _total;
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
