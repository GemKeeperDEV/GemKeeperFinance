// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Bling is ERC20, Ownable, ERC20Permit {
    uint256 public totalCap;
    uint256 public INVESTORS_SHARE = 10;
    uint256 public TREASURY_SHARE = 10; // Treasury for future projects
    uint256 public ECOSYSTEM_SHARE = 5; // Ecosystem Collabration
    constructor(string memory name, string memory symbol, uint256 _totalCap) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, _totalCap * INVESTORS_SHARE / 100);
        _mint(msg.sender, _totalCap * TREASURY_SHARE / 100);
        _mint(msg.sender, _totalCap * ECOSYSTEM_SHARE / 100);
        totalCap = _totalCap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount < totalCap, "total supply exceeds total cap");
        _mint(to, amount);
    }
}
