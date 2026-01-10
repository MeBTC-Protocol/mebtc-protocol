// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

interface IBonusHook {
    function onBonusChanged(address owner) external;
}

/// BonusNFT – Fuji/Mainnet safe (kein public test-mint)
contract BonusNFT is ERC1155, Ownable {
    uint256 public constant SOLAR_PANEL   = 1; // -20% Stromkosten
    uint256 public constant WIND_TURBINE  = 2; // -15% Stromkosten
    uint256 public constant HYDRO_TURBINE = 3; // -25% Stromkosten
    uint256 public constant ASIC_BOOSTER  = 4; // +10% Hashrate

    IBonusHook public immutable manager;

    constructor(address _manager, address _owner)
        ERC1155("https://api.mebtc.com/bonus/{id}.json")
        Ownable(_owner)
    {
        require(_manager != address(0), "manager=0");
        require(_owner != address(0), "owner=0");
        manager = IBonusHook(_manager);
    }

    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        require(to != address(0), "to=0");
        require(id >= 1 && id <= 4, "bad-id");
        require(amount > 0, "amount=0");
        _mint(to, id, amount, "");
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) 
    internal virtual override 
    {
        super._update(from, to, ids, values);

        if (from != address(0)) {
            try manager.onBonusChanged(from) {} catch {}
        }
        if (to != address(0)) {
            try manager.onBonusChanged(to) {} catch {}
        }
    }
}


