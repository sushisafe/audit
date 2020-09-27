pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SusafeToken.sol";


interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SusafeSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SusafeSwap must mint EXACTLY the same amount of SusafeSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

interface ISusafeReferral {
    function setReferrer(address farmer, address referrer) external;
    function getReferrer(address farmer) external view returns (address);
}

// SusafeChef is the master of Susafe. He can make Susafe and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSAFE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SusafeChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSAFEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSusafePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSusafePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSAFEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSAFEs distribution occurs.
        uint256 accSusafePerShare; // Accumulated SUSAFEs per share, times 1e12. See below.
    }

    uint256 public constant REFERRAL_COMMISSION_PERCENT = 1;
    address public rewardReferral;

    // The SUSAFE TOKEN!
    SusafeToken public susafe;
    // SUSAFE tokens created per block.
    uint256 public susafePerBlock;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSAFE mining starts.
    uint256 public startBlock;
    // Block number when each epoch ends.
    uint256[6] public epochEndBlocks;

    // Reward multipler for each of 7 epoches (epochIndex: reward multipler)
    uint256[7] public epochRewardMultiplers = [100, 400, 600, 800, 400, 200, 1];

    uint256 public constant BLOCKS_PER_DAY = 6500;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        SusafeToken _susafe,
        uint256 _susafePerBlock,
        uint256 _startBlock
    ) public {
        susafe = _susafe;
        susafePerBlock = _susafePerBlock;
        startBlock = _startBlock;
        epochEndBlocks[0] = startBlock + BLOCKS_PER_DAY * 3; // 3 days
        epochEndBlocks[1] = epochEndBlocks[0] + BLOCKS_PER_DAY * 7; // 1 week
        epochEndBlocks[2] = epochEndBlocks[1] + BLOCKS_PER_DAY * 7; // 1 week
        epochEndBlocks[3] = epochEndBlocks[2] + BLOCKS_PER_DAY * 14; // 2 weeks
        epochEndBlocks[4] = epochEndBlocks[3] + BLOCKS_PER_DAY * 14; // 2 weeks
        epochEndBlocks[5] = epochEndBlocks[4] + BLOCKS_PER_DAY * 7 * 34 / 10; // 3.4 weeks
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate, uint256 _lastRewardBlock) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        if (_lastRewardBlock == 0) {
            _lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: _lastRewardBlock,
            accSusafePerShare: 0
        }));
    }

    function setSusafePerBlock(uint256 _susafePerBlock) public onlyOwner {
        massUpdatePools();
        susafePerBlock = _susafePerBlock;
    }

    function setEpochEndBlock(uint8 _index, uint256 _epochEndBlock) public onlyOwner {
        require(_index < 6, "_index out of range");
        require(epochEndBlocks[_index] > block.number, "Too late to update");
        epochEndBlocks[_index] = _epochEndBlock;
    }

    function setEpochRewardMultipler(uint8 _index, uint256 _epochRewardMultipler) public onlyOwner {
        require(_index < 7, "Index out of range");
        require(_index == 6 || epochEndBlocks[_index] > block.number, "Too late to update");
        epochRewardMultiplers[_index] = _epochRewardMultipler;
    }

    function setRewardReferral(address _rewardReferral) external onlyOwner {
        rewardReferral = _rewardReferral;
    }

    // Update the given pool's SUSAFE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        for (uint8 epochId = 6; epochId >= 1; --epochId) {
            if (_to >= epochEndBlocks[epochId - 1]) {
                if (_from >= epochEndBlocks[epochId - 1]) return _to.sub(_from).mul(epochRewardMultiplers[epochId]);
                uint256 multiplier = _to.sub(epochEndBlocks[epochId - 1]).mul(epochRewardMultiplers[epochId]);
                if (epochId == 1) return multiplier.add(epochEndBlocks[0].sub(_from).mul(epochRewardMultiplers[0]));
                for (epochId = epochId - 1; epochId >= 1; --epochId) {
                    if (_from >= epochEndBlocks[epochId - 1]) return multiplier.add(epochEndBlocks[epochId].sub(_from).mul(epochRewardMultiplers[epochId]));
                    multiplier = multiplier.add(epochEndBlocks[epochId].sub(epochEndBlocks[epochId - 1]).mul(epochRewardMultiplers[epochId]));
                }
                return multiplier.add(epochEndBlocks[0].sub(_from).mul(epochRewardMultiplers[0]));
            }
        }
        return _to.sub(_from).mul(epochRewardMultiplers[0]);
    }

    // View function to see pending SUSAFEs on frontend.
    function pendingSusafe(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSusafePerShare = pool.accSusafePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 susafeReward = multiplier.mul(susafePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSusafePerShare = accSusafePerShare.add(susafeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSusafePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 susafeReward = multiplier.mul(susafePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        safeSusafeMint(susafeReward);
        pool.accSusafePerShare = pool.accSusafePerShare.add(susafeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to SusafeChef for SUSAFE allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (rewardReferral != address(0) && _referrer != address(0)) {
            ISusafeReferral(rewardReferral).setReferrer(msg.sender, _referrer);
        }
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSusafePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 actualPaid = pending.mul(100 - REFERRAL_COMMISSION_PERCENT).div(100); // 99%
                uint256 commission = pending - actualPaid; // 1%
                safeSusafeTransfer(msg.sender, actualPaid);
                if (rewardReferral != address(0)) {
                    _referrer = ISusafeReferral(rewardReferral).getReferrer(msg.sender);
                }
                if (_referrer != address(0)) { // send commission to referrer
                    safeSusafeTransfer(_referrer, commission);
                } else { // or burn
                    safeSusafeBurn(commission);
                }
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSusafePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from SusafeChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSusafePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            uint256 actualPaid = pending.mul(100 - REFERRAL_COMMISSION_PERCENT).div(100); // 99%
            uint256 commission = pending - actualPaid; // 1%
            safeSusafeTransfer(msg.sender, actualPaid);
            address _referrer = address(0);
            if (rewardReferral != address(0)) {
                _referrer = ISusafeReferral(rewardReferral).getReferrer(msg.sender);
            }
            if (_referrer != address(0)) { // send commission to referrer
                safeSusafeTransfer(_referrer, commission);
            } else { // or burn
                safeSusafeBurn(commission);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSusafePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe susafe mint, ensure it is never over cap and we are the current owner.
    function safeSusafeMint(uint256 _amount) internal {
        if (susafe.owner() == address(this)) {
            uint256 totalSupply = susafe.totalSupply();
            uint256 cap = susafe.cap();
            if (totalSupply.add(_amount) > cap) {
                susafe.mint(address(this), cap.sub(totalSupply));
            } else {
                susafe.mint(address(this), _amount);
            }
        }
    }

    // Safe susafe burn function, just in case if rounding error causes pool to not have enough SUSAFEs.
    function safeSusafeBurn(uint256 _amount) internal {
        uint256 susafeBal = susafe.balanceOf(address(this));
        if (_amount > susafeBal) {
            susafe.burn(susafeBal);
        } else {
            susafe.burn(_amount);
        }
    }

    // Safe susafe transfer function, just in case if rounding error causes pool to not have enough SUSAFEs.
    function safeSusafeTransfer(address _to, uint256 _amount) internal {
        uint256 susafeBal = susafe.balanceOf(address(this));
        if (_amount > susafeBal) {
            susafe.transfer(_to, susafeBal);
        } else {
            susafe.transfer(_to, _amount);
        }
    }

    // Transfer ownership of Susafe (eg. a governance DAO contract)
    function transferSusafeOwnership(address newSusafeOwner) public onlyOwner {
        SusafeToken(susafe).transferOwnership(newSusafeOwner);
    }
}
