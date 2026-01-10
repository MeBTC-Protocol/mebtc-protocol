// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

interface IManager {
    function onMinerTransfer(address from, address to, uint256 tokenId, uint256 baseHashRate) external;
    function ownerActiveHash(address) external view returns (uint256);
    function totalEffectiveHash() external view returns (uint256);
}
interface IMiner {
    function ownerOf(uint256) external view returns (address);
    function getMinerData(uint256) external view returns (uint256 hr, uint256 pmkwh, uint256 createdAt);
}

contract ResyncMiner is Script {
    function run() external {
        address MANAGER   = vm.envAddress("MANAGER_ADDR");
        address MINER     = vm.envAddress("MINER_ADDR");
        uint256 TOKEN_ID  = vm.envUint("TOKEN_ID");

        IManager M = IManager(MANAGER);
        IMiner   N = IMiner(MINER);

        (uint256 hr,,) = N.getMinerData(TOKEN_ID);
        address owner  = N.ownerOf(TOKEN_ID);

        // so tun als käme der Call vom MinerNFT (weil der Manager das verlangt)
        vm.startBroadcast();
        vm.prank(MINER);
        M.onMinerTransfer(address(0), owner, TOKEN_ID, hr);
        vm.stopBroadcast();
    }
}

