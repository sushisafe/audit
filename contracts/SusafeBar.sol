pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract SusafeBar is ERC20("SusafeBar", "xSUSAFE") {
    using SafeMath for uint256;
    IERC20 public susafe;

    constructor(IERC20 _susafe) public {
        susafe = _susafe;
    }

    // Enter the bar. Pay some SUSAFEs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalSusafe = susafe.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalSusafe == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalSusafe);
            _mint(msg.sender, what);
        }
        susafe.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSAFEs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(susafe.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        susafe.transfer(msg.sender, what);
    }
}