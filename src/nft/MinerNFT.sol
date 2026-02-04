// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {ITwapOracle} from "../core/ITwapOracle.sol";

/*
    MinerNFT (Model B)
    - permissionless buyFromModel() gegen USDC (6 decimals)
    - 95% vom Primärverkauf -> DemandVault
      5% -> PROJECT
    - Royalties 100% -> ROYALTY_WALLET (ERC2981)
    - Upgrades:
        * requestUpgradeHash / requestUpgradePower ziehen USDC -> POOL
        * Upgrades werden als pending gespeichert
        * MiningManager ruft nach claim applyPendingUpgrades() auf
        * applyPendingUpgrades() ruft Manager.onMinerUpgradeHashChange() (Totals korrigieren)

    Bugfix:
    - minerState wird VOR _safeMint gesetzt, damit _update (Hook) nie modelId=0 sieht
    - kein extra manager.onMinerTransfer im buy loop (sonst doppelt + "model!" revert)
*/

interface IMiningManagerHook {
    function onMinerTransfer(address from, address to, uint256 tokenId, uint256 baseHashRate) external;
    function onMinerUpgradeHashChange(address owner, uint256 tokenId, uint256 oldEffHash, uint256 newEffHash) external;
}

contract MinerNFT is ERC721, ERC2981, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // --------- constants ----------
    uint16 public constant MAX_STEPS = 4;

    // Hash upgrade: +2.5% pro step (250 bps)
    uint16 public constant HASH_STEP_BPS = 250;

    // Power upgrade: -5% pro step (500 bps)
    uint16 public constant POWER_STEP_BPS = 500;

    uint8 public constant MEBTC_DECIMALS = 8;
    uint256 private constant MEBTC_UNIT = 1e8;

    uint16 public constant PRIMARY_POOL_BPS = 9000; // 90%
    uint16 public constant PRIMARY_PROJECT_BPS = 1000; // 10%
    uint16 public constant MAX_MEBTC_SHARE_BPS = 3000; // 30%

    // --------- config ----------
    IERC20 public payToken;
    IERC20 public immutable mebtcToken;
    ITwapOracle public immutable twapOracle;
    address public immutable demandVault;
    address public immutable feeVaultMeBTC;
    address public immutable projectWallet;

    IMiningManagerHook public manager;

    // --------- ids ----------
    uint256 public nextTokenId = 1;
    uint16 public nextModelId = 1;

    // --------- models ----------
    struct Model {
        uint32 baseHashrate;     // in "Ghash" units as you defined (e.g. 500)
        uint32 basePowerWatt;    // watt
        uint32 maxSupply;
        uint32 minted;
        uint256 priceUSDC;       // 6 decimals (1 USDC = 1_000_000)
        bool finalized;
        uint256[4] powerStepCost; // USDC costs for POWER upgrades (step0..3)
        uint256[4] hashStepCost;  // USDC costs for HASH upgrades  (step0..3)
        string uri;               // metadata uri (same for all tokens of the model)
    }

    mapping(uint16 => Model) internal models;

    // --------- miner state ----------
    struct MinerState {
        uint16 modelId;

        uint16 powerUpgradeBps;        // active
        uint16 hashUpgradeBps;         // active

        uint16 pendingPowerUpgradeBps; // pending (becomes active after claim)
        uint16 pendingHashUpgradeBps;  // pending (becomes active after claim)

        uint40 createdAt;
        uint40 lastClaimAt;
    }

    mapping(uint256 => MinerState) internal minerState;

    // --------- events ----------
    event ManagerSet(address manager);
    event ModelAdded(
        uint16 indexed modelId,
        uint32 baseHashrate,
        uint32 basePowerWatt,
        uint32 maxSupply,
        uint256 priceUSDC,
        string uri
    );
    event ModelFinalized(uint16 indexed modelId);

    event MinerPurchased(uint256 indexed tokenId, address indexed buyer, uint16 indexed modelId, uint256 priceUSDC);

    event UpgradeRequestedPower(uint256 indexed tokenId, uint16 newPendingPowerBps, uint256 costUSDC);
    event UpgradeRequestedHash(uint256 indexed tokenId, uint16 newPendingHashBps, uint256 costUSDC);

    // --------- constructor ----------
    constructor(
        address _payToken,
        address _demandVault,
        address _feeVaultMeBTC,
        address _projectWallet,
        address _royaltyWallet,
        uint96 _royaltyBps,
        address _mebtcToken,
        address _twapOracle
    ) ERC721("MeBTC Miner", "MBTCMINER") Ownable(msg.sender) {
        require(_payToken != address(0), "token=0");
        require(_demandVault != address(0), "demand=0");
        require(_feeVaultMeBTC != address(0), "mebtcVault=0");
        require(_projectWallet != address(0), "project=0");
        require(_royaltyWallet != address(0), "royalty=0");
        require(_mebtcToken != address(0), "mebtc=0");
        require(_twapOracle != address(0), "twap=0");
        require(_royaltyBps <= 10_000, "royalty>100%");

        require(IERC20Metadata(_payToken).decimals() == 6, "decimals");
        payToken = IERC20(_payToken);
        mebtcToken = IERC20(_mebtcToken);
        twapOracle = ITwapOracle(_twapOracle);
        demandVault = _demandVault;
        feeVaultMeBTC = _feeVaultMeBTC;
        projectWallet = _projectWallet;

        _setDefaultRoyalty(_royaltyWallet, _royaltyBps);
    }

    // --------- admin ----------
    function setManager(address _manager) external onlyOwner {
        manager = IMiningManagerHook(_manager);
        emit ManagerSet(_manager);
    }

    function setPayToken(address _payToken) external onlyOwner {
        require(_payToken != address(0), "token=0");
        require(IERC20Metadata(_payToken).decimals() == 6, "decimals");
        payToken = IERC20(_payToken);
    }

    function addModel(
        uint32 baseHashrate,
        uint32 basePowerWatt,
        uint32 maxSupply,
        uint256 priceUSDC,
        string calldata uri,
        uint256[4] calldata powerStepCost,
        uint256[4] calldata hashStepCost
    ) external onlyOwner returns (uint16 modelId) {
        require(maxSupply > 0, "supply=0");
        require(priceUSDC > 0, "price=0");

        modelId = nextModelId++;
        Model storage m = models[modelId];

        m.baseHashrate = baseHashrate;
        m.basePowerWatt = basePowerWatt;
        m.maxSupply = maxSupply;
        m.priceUSDC = priceUSDC;
        m.uri = uri;

        // copy arrays
        for (uint256 i = 0; i < 4; i++) {
            m.powerStepCost[i] = powerStepCost[i];
            m.hashStepCost[i] = hashStepCost[i];
        }

        emit ModelAdded(modelId, baseHashrate, basePowerWatt, maxSupply, priceUSDC, uri);
    }

    function finalizeModel(uint16 modelId) external onlyOwner {
        Model storage m = models[modelId];
        require(m.maxSupply > 0, "model!");
        require(!m.finalized, "finalized");
        m.finalized = true;
        emit ModelFinalized(modelId);
    }

    // --------- views ----------
    function getModel(uint16 modelId)
        external
        view
        returns (
            uint32 baseHashrate,
            uint32 basePowerWatt,
            uint32 maxSupply,
            uint32 minted,
            uint256 priceUSDC,
            bool finalized,
            uint256[4] memory powerStepCost,
            uint256[4] memory hashStepCost,
            string memory uri
        )
    {
        Model storage m = models[modelId];
        require(m.maxSupply > 0, "model!");

        baseHashrate = m.baseHashrate;
        basePowerWatt = m.basePowerWatt;
        maxSupply = m.maxSupply;
        minted = m.minted;
        priceUSDC = m.priceUSDC;
        finalized = m.finalized;
        powerStepCost = m.powerStepCost;
        hashStepCost = m.hashStepCost;
        uri = m.uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "token!");
        uint16 modelId = minerState[tokenId].modelId;
        require(modelId != 0, "model!");
        return models[modelId].uri;
    }

    // active effective values (used by MiningManager)
    function getMinerData(uint256 tokenId) external view returns (uint256 effHash, uint256 effPowerWatt, uint256 createdAt) {
        MinerState storage s = minerState[tokenId];
        require(s.modelId != 0, "model!");
        Model storage m = models[s.modelId];

        // effHash = base * (10000 + hashUpgradeBps) / 10000
        effHash = (uint256(m.baseHashrate) * (10_000 + uint256(s.hashUpgradeBps))) / 10_000;

        // effPower = base * (10000 - powerUpgradeBps) / 10000
        // clamp to avoid underflow if someone misconfigures
        uint256 pbps = uint256(s.powerUpgradeBps);
        if (pbps > 10_000) pbps = 10_000;
        effPowerWatt = (uint256(m.basePowerWatt) * (10_000 - pbps)) / 10_000;

        createdAt = uint256(s.createdAt);
    }

    function getMinerState(uint256 tokenId) external view returns (MinerState memory) {
        require(minerState[tokenId].modelId != 0, "model!");
        return minerState[tokenId];
    }

    function getMinerConfig(uint256 tokenId)
        external
        view
        returns (uint256 baseHashrate, uint256 basePowerWatt, uint16 hashUpgradeBps, uint16 powerUpgradeBps, uint256 createdAt)
    {
        MinerState storage s = minerState[tokenId];
        require(s.modelId != 0, "model!");
        Model storage m = models[s.modelId];

        baseHashrate = m.baseHashrate;
        basePowerWatt = m.basePowerWatt;
        hashUpgradeBps = s.hashUpgradeBps;
        powerUpgradeBps = s.powerUpgradeBps;
        createdAt = uint256(s.createdAt);
    }

    // --------- buying ----------
    function buyFromModel(uint16 modelId, uint256 quantity) external nonReentrant returns (uint256 firstTokenId) {
        require(quantity > 0, "qty=0");
        Model storage m = models[modelId];
        require(m.maxSupply > 0, "model!");
        require(m.finalized, "not live");
        require(uint256(m.minted) + quantity <= uint256(m.maxSupply), "sold out");

        uint256 total = m.priceUSDC * quantity;

        // split 95/5
        uint256 toPool = (total * PRIMARY_POOL_BPS) / 10_000;
        uint256 toProject = total - toPool;

        // pull USDC from buyer
        payToken.safeTransferFrom(msg.sender, demandVault, toPool);
        if (toProject > 0) {
            payToken.safeTransferFrom(msg.sender, projectWallet, toProject);
        }

        uint40 nowTs = uint40(block.timestamp);

        firstTokenId = nextTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = nextTokenId++;

            // bugfix: state BEFORE _safeMint, so _update hook sees modelId != 0
            minerState[tokenId] = MinerState({
                modelId: modelId,
                powerUpgradeBps: 0,
                hashUpgradeBps: 0,
                pendingPowerUpgradeBps: 0,
                pendingHashUpgradeBps: 0,
                createdAt: nowTs,
                lastClaimAt: nowTs
            });

            _safeMint(msg.sender, tokenId);

            emit MinerPurchased(tokenId, msg.sender, modelId, m.priceUSDC);

            m.minted += 1;
        }
    }

    // --------- upgrades (pending until claim) ----------
    function requestUpgradePower(uint256 tokenId) external nonReentrant returns (uint16 newPendingPowerBps) {
        return _requestUpgradePower(tokenId, 0);
    }

    function requestUpgradePowerWithMebtc(uint256 tokenId, uint16 mebtcShareBps)
        external
        nonReentrant
        returns (uint16 newPendingPowerBps)
    {
        return _requestUpgradePower(tokenId, mebtcShareBps);
    }

    function requestUpgradePowerBatch(uint256[] calldata tokenIds)
        external
        nonReentrant
        returns (uint16[] memory newPendingPowerBps)
    {
        return _requestUpgradePowerBatch(tokenIds, 0);
    }

    function requestUpgradePowerBatchWithMebtc(uint256[] calldata tokenIds, uint16 mebtcShareBps)
        external
        nonReentrant
        returns (uint16[] memory newPendingPowerBps)
    {
        return _requestUpgradePowerBatch(tokenIds, mebtcShareBps);
    }

    function requestUpgradeHash(uint256 tokenId) external nonReentrant returns (uint16 newPendingHashBps) {
        return _requestUpgradeHash(tokenId, 0);
    }

    function requestUpgradeHashWithMebtc(uint256 tokenId, uint16 mebtcShareBps)
        external
        nonReentrant
        returns (uint16 newPendingHashBps)
    {
        return _requestUpgradeHash(tokenId, mebtcShareBps);
    }

    function requestUpgradeHashBatch(uint256[] calldata tokenIds)
        external
        nonReentrant
        returns (uint16[] memory newPendingHashBps)
    {
        return _requestUpgradeHashBatch(tokenIds, 0);
    }

    function requestUpgradeHashBatchWithMebtc(uint256[] calldata tokenIds, uint16 mebtcShareBps)
        external
        nonReentrant
        returns (uint16[] memory newPendingHashBps)
    {
        return _requestUpgradeHashBatch(tokenIds, mebtcShareBps);
    }

    function _requestUpgradePowerBatch(uint256[] calldata tokenIds, uint16 mebtcShareBps)
        internal
        returns (uint16[] memory newPendingPowerBps)
    {
        require(tokenIds.length > 0, "ids=0");
        newPendingPowerBps = new uint16[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            newPendingPowerBps[i] = _requestUpgradePower(tokenIds[i], mebtcShareBps);
        }
    }

    function _requestUpgradeHashBatch(uint256[] calldata tokenIds, uint16 mebtcShareBps)
        internal
        returns (uint16[] memory newPendingHashBps)
    {
        require(tokenIds.length > 0, "ids=0");
        newPendingHashBps = new uint16[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            newPendingHashBps[i] = _requestUpgradeHash(tokenIds[i], mebtcShareBps);
        }
    }

    function _requestUpgradePower(uint256 tokenId, uint16 mebtcShareBps) internal returns (uint16 newPendingPowerBps) {
        require(ownerOf(tokenId) == msg.sender, "!owner");
        MinerState storage s = minerState[tokenId];
        require(s.modelId != 0, "model!");

        Model storage m = models[s.modelId];

        uint16 activeSteps = s.powerUpgradeBps / POWER_STEP_BPS;
        uint16 pendingSteps = s.pendingPowerUpgradeBps / POWER_STEP_BPS;
        uint16 stepIndex = activeSteps + pendingSteps;

        require(stepIndex < MAX_STEPS, "max steps");

        uint256 cost = m.powerStepCost[stepIndex];
        require(cost > 0, "cost=0");

        _collectUpgradeFee(cost, mebtcShareBps);

        s.pendingPowerUpgradeBps += POWER_STEP_BPS;
        newPendingPowerBps = s.pendingPowerUpgradeBps;

        emit UpgradeRequestedPower(tokenId, newPendingPowerBps, cost);
    }

    function _requestUpgradeHash(uint256 tokenId, uint16 mebtcShareBps) internal returns (uint16 newPendingHashBps) {
        require(ownerOf(tokenId) == msg.sender, "!owner");
        MinerState storage s = minerState[tokenId];
        require(s.modelId != 0, "model!");

        Model storage m = models[s.modelId];

        uint16 activeSteps = s.hashUpgradeBps / HASH_STEP_BPS;
        uint16 pendingSteps = s.pendingHashUpgradeBps / HASH_STEP_BPS;
        uint16 stepIndex = activeSteps + pendingSteps;

        require(stepIndex < MAX_STEPS, "max steps");

        uint256 cost = m.hashStepCost[stepIndex];
        require(cost > 0, "cost=0");

        _collectUpgradeFee(cost, mebtcShareBps);

        s.pendingHashUpgradeBps += HASH_STEP_BPS;
        newPendingHashBps = s.pendingHashUpgradeBps;

        emit UpgradeRequestedHash(tokenId, newPendingHashBps, cost);
    }

    // --------- manager-only hooks ----------
    modifier onlyManager() {
        require(address(manager) != address(0) && msg.sender == address(manager), "!manager");
        _;
    }

    function setLastClaimAt(uint256 tokenId, uint40 ts) external onlyManager {
        require(minerState[tokenId].modelId != 0, "model!");
        minerState[tokenId].lastClaimAt = ts;
    }

    function applyPendingUpgrades(uint256 tokenId) external onlyManager {
        MinerState storage s = minerState[tokenId];
        require(s.modelId != 0, "model!");

        // compute old/new effHash for manager totals
        Model storage m = models[s.modelId];

        uint256 oldEffHash = (uint256(m.baseHashrate) * (10_000 + uint256(s.hashUpgradeBps))) / 10_000;

        // apply pending -> active
        if (s.pendingPowerUpgradeBps > 0) {
            s.powerUpgradeBps += s.pendingPowerUpgradeBps;
            s.pendingPowerUpgradeBps = 0;
        }

        if (s.pendingHashUpgradeBps > 0) {
            s.hashUpgradeBps += s.pendingHashUpgradeBps;
            s.pendingHashUpgradeBps = 0;
        }

        uint256 newEffHash = (uint256(m.baseHashrate) * (10_000 + uint256(s.hashUpgradeBps))) / 10_000;

        // notify manager if hash changed (owner must exist)
        address owner = _ownerOf(tokenId);
        if (owner != address(0) && newEffHash != oldEffHash) {
            manager.onMinerUpgradeHashChange(owner, tokenId, oldEffHash, newEffHash);
        }
    }

    function _collectUpgradeFee(uint256 costUSDC, uint16 mebtcShareBps) internal {
        require(mebtcShareBps <= MAX_MEBTC_SHARE_BPS, "mebtc%");

        if (mebtcShareBps == 0) {
            payToken.safeTransferFrom(msg.sender, demandVault, costUSDC);
            return;
        }

        require(twapOracle.isReady(), "twap");
        uint256 price = twapOracle.priceMebtcInUsdc();
        require(price > 0, "price");

        uint256 mebtcUsdc = (costUSDC * mebtcShareBps) / 10_000;
        uint256 usdcPart = costUSDC - mebtcUsdc;

        if (usdcPart > 0) {
            payToken.safeTransferFrom(msg.sender, demandVault, usdcPart);
        }

        uint256 mebtcAmount = (mebtcUsdc * MEBTC_UNIT) / price;
        if (mebtcAmount > 0) {
            mebtcToken.safeTransferFrom(msg.sender, feeVaultMeBTC, mebtcAmount);
        }
    }

    // --------- ERC721 hook ----------
    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        from = super._update(to, tokenId, auth);

        // notify manager on mint/transfer/burn
        if (address(manager) != address(0)) {
            uint16 modelId = minerState[tokenId].modelId;

            // guard: during mint, state is now set BEFORE _safeMint, so modelId != 0
            // during burn, modelId might still be set, but to==0 is fine
            if (modelId != 0) {
                manager.onMinerTransfer(from, to, tokenId, 0);
            }
        }

        return from;
    }

    // --------- supportsInterface ----------
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
