// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

interface IMinerNFT {
    struct MintAuth {
        address to;
        uint256 hashRate;
        uint256 powerMilliKWh;
        uint256 nonce;
        uint256 deadline;
    }

    function nonces(address) external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function mintWithSig(MintAuth calldata p, bytes calldata sig) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract MintMinerOnly is Script {
    // EIP-712 Domain (muss exakt zum Contract passen)
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant NAME_HASH    = keccak256(bytes("MeBTCMiner")); // EIP712("MeBTCMiner","1")
    bytes32 private constant VERSION_HASH = keccak256(bytes("1"));
    // Struct-Hash wie im Contract
    bytes32 private constant TYPEHASH =
        keccak256("MintAuth(address to,uint256 hashRate,uint256 powerMilliKWh,uint256 nonce,uint256 deadline)");

    function run() external {
        // Pflicht-ENVs (bitte vorher exportieren)
        address user      = vm.envAddress("USER_ADDRESS"); // Empfänger
        address minerAddr = vm.envAddress("MINER_ADDR");    // MinerNFT
        uint256 signerPK  = vm.envUint("SIGNER_PK");        // PK des im Contract hinterlegten signer

        // Ebenfalls als ENV setzen (kein Default mehr, damit kein Self-Call nötig ist)
        uint256 hashRate  = vm.envUint("HASH_RATE");        // z.B. 2000
        uint256 powerMKWH = vm.envUint("POWER_MKWH");       // z.B. 600

        IMinerNFT miner = IMinerNFT(minerAddr);

        vm.startBroadcast();

        uint256 nonce    = miner.nonces(user);
        uint256 deadline = block.timestamp + 1 days;

        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                NAME_HASH,
                VERSION_HASH,
                block.chainid,
                minerAddr
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                TYPEHASH,
                user,
                hashRate,
                powerMKWH,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
        bytes memory sig = abi.encodePacked(r, s, v); // 65 bytes

        uint256 beforeNext = miner.nextTokenId();
        IMinerNFT.MintAuth memory p = IMinerNFT.MintAuth({
            to: user,
            hashRate: hashRate,
            powerMilliKWh: powerMKWH,
            nonce: nonce,
            deadline: deadline
        });

        miner.mintWithSig(p, sig);

        uint256 mintedId = beforeNext;

        console2.log("Minted Miner tokenId:", mintedId);
        console2.log("Owner:", miner.ownerOf(mintedId));

        vm.stopBroadcast();
    }
}



