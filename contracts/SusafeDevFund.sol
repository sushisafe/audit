pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
    function burn(uint amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SusafeDevFund is Ownable {
    using SafeMath for uint256;

    IERC20 public susafe;

    uint256 public constant DURATION = 21 weeks;
    uint256 public constant TOTAL_REWARD = 21000 ether;

    uint256 public constant REWARD_RATE = TOTAL_REWARD / DURATION;

    uint256 public totalClaimedRewards = 0;
    uint256 public constant START_TIME = 1600084800; // Monday, September 14, 2020 12:00:00 PM (GMT+0)
    uint256 public constant END_TIME = START_TIME + DURATION;

    address[10] public founders = [
        0xEDCD0Ef9292bd9C9d93D98a05256f86C9A3f2503,
        0xD49536F13922D064426727187f9155c5C912A1fa,
        0xdd81D89FDC31f697FB25B9250C677b91D9f0bd5D,
        0x04CaCc11043c06F575b43D0aaE834222027441a5,
        0xc230c4c8FbB5656cCa7A6eDF2F7711b38DD902A8,
        0x1B2ae29b8A5634bE87C5e417BC3F6e498DEE2056,
        0x6Bc4749414bbE2f8d3B04Cc285c6B6704A96ECbD,
        0x113d00DA8F8D0f30eF8B926489cB030F317fcBfc,
        0xF7a787aF28793A758986E103780cBd5B1549F98d,
        0xF7a787aF28793A758986E103780cBd5B1549F98d];

    address public governance;

    constructor (address _susafe) public {
        governance = msg.sender;
        susafe = IERC20(_susafe);
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setFounder(uint8 index, address _newFounder) public {
        require(msg.sender == governance, "!governance");
        require(index < 10, "index out of length");
        require(_newFounder != address(0x0), "!address(0)");
        founders[index] = _newFounder;
    }

    function totalReleasedRewards() public view returns (uint256) {
        if (block.timestamp <= START_TIME) return 0;
        else if (block.timestamp >= END_TIME) return TOTAL_REWARD;
        return REWARD_RATE.mul(block.timestamp - START_TIME);
    }

    function claimableRewards() public view returns (uint256) {
        return totalReleasedRewards().sub(totalClaimedRewards);
    }

    // anyone can call this to give fund to devs and operation
    function claimRewards() external {
        uint256 reward = claimableRewards();
        require(reward > 0, "There is nothing to claim");
        totalClaimedRewards = totalClaimedRewards.add(reward);
        susafe.mint(address(this), reward);
        for (uint8 i = 0; i < 10; i++) {
            uint256 amount = reward.div(10); // each founder 10%
            susafe.transfer(founders[i], amount);
        }
    }

    function governanceRecoverUnsupported(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == governance, "!governance");
        require(susafe != _asset || block.timestamp >= END_TIME, "only can recue susafe stuck after end of fund release period (21 weeks)");
        balance = _asset.balanceOf(address(this));
        _asset.transfer(governance, balance);
    }
}
