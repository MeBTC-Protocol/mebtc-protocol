// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IMiningManager {
    function setPayToken(address token) external;
    function payToken() external view returns (address);
}

interface IMinerNFT {
    function setPayToken(address token) external;
    function payToken() external view returns (address);
}

/*
Env:
  PRIVATE_KEY
  MANAGER_ADDRESS
  MINER_ADDRESS
  PAY_TOKEN_ADDRESS
*/
contract SetPayToken is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address managerAddr = vm.envAddress("MANAGER_ADDRESS");
        address minerAddr = vm.envAddress("MINER_ADDRESS");
        address payToken = vm.envAddress("PAY_TOKEN_ADDRESS");

        require(managerAddr != address(0) && minerAddr != address(0), "addr=0");
        require(payToken != address(0), "token=0");

        vm.startBroadcast(pk);

        IMiningManager manager = IMiningManager(managerAddr);
        IMinerNFT miner = IMinerNFT(minerAddr);

        address oldManagerToken = manager.payToken();
        address oldMinerToken = miner.payToken();

        manager.setPayToken(payToken);
        miner.setPayToken(payToken);

        vm.stopBroadcast();

        console2.log("Manager payToken (old->new):", oldManagerToken, "->", payToken);
        console2.log("Miner payToken (old->new):  ", oldMinerToken, "->", payToken);
    }
}
