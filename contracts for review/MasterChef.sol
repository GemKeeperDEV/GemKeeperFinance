// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface Bling {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);


    /**
     * @dev Mint the `amount` to `to` address.
     */
    function mint(address to, uint256 amount) external;

}

// MasterChef is the master of Bling. He can make Bling and he is a fair guy.
contract MasterChef is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 unclaimedReward; // The Bling tokens that are not claimed yet.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of blings
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBlingPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBlingPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Blings to distribute per block.
        uint256 lastRewardBlock; // Last block number that Blings distribution occurs.
        uint256 accBlingPerShare; // Accumulated Blings per share, times 1e12. See below.
    }
    // The BLING TOKEN!
    Bling public bling;
    // Dev address to get the 10% of team Bling share
    address public devaddr; 
    // Block number when bonus BLING period ends.
    uint256 public bonusEndBlock;
    // BLING tokens created per block.
    uint256 public blingPerBlock;
    // BLING tokens public launch time.
    uint256 public tokenLaunchTime;
    // BLING tokens publicly launched.
    bool public tokenLaunched = false;
    // Bonus muliplier for early bling makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BLING mining starts.
    uint256 public startBlock;

uint256[] public timeOfEachPhase = [
1644796800,
1647388800,
1649980800,
1652572800,
1655164800,
1657756800,
1660348800,
1662940800,
1665532800,
1668124800,
1670716800,
1673308800,
1675900800,
1678492800,
1681084800,
1683676800,
1686268800,
1688860800,
1691452800,
1694044800,
1696636800,
1699228800,
1701820800,
1704412800,
1707004800,
1709596800,
1712188800,
1714780800,
1717372800,
1719964800,
1722556800,
1725148800,
1727740800,
1730332800,
1732924800,
1735516800,
1738108800];

uint256[] public blingOfEachPhase = [
11152637748000000000,
9753561328000000000,
9237901733200000000,
8038693373200000000,
7279194745200000000,
6799511401200000000,
6439748893200000000,
6199907221200000000,
5960065549200000000,
5720223877200000000,
5480382205200000000,
5240540533200000000,
5000698861200000000,
4800830801200000000,
4560989129200000000,
4361121069200000000,
4161253009200000000,
4001358561200000000,
3801490501200000000,
3641596053200000000,
3481701605200000000,
3361780769200000000,
3241859933200000000,
3121939097200000000,
3002018261200000000,
2922071037200000000,
2842123813200000000,
2762176589200000000,
2682229365200000000,
2642255753200000000,
2562308529200000000,
2522334917200000000,
2482361305200000000,
2442387693200000000,
2402414081200000000,
2362440469200000000,
2322466857200000000
];

uint256 public currentBlingPhase ;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        Bling _bling,
        address _devaddr,
        uint256 _blingPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _tokenLaunch
    ) public {
        bling = _bling;
        devaddr = _devaddr;
        blingPerBlock = _blingPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        tokenLaunchTime = _tokenLaunch;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken
    ) public onlyOwner {
        massUpdatePools();
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accBlingPerShare: 0
            })
        );
    }

    // Update the given pool's BLING allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending Blings on frontend.
    function pendingBling(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBlingPerShare = pool.accBlingPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 blingReward =
                multiplier.mul(blingPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accBlingPerShare = accBlingPerShare.add(
                blingReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accBlingPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
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
        uint256 blingReward =
            multiplier.mul(blingPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        bling.mint(devaddr, blingReward.mul(100).div(625));
        bling.mint(address(this), blingReward);
        pool.accBlingPerShare = pool.accBlingPerShare.add(
            blingReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BLING allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant() {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accBlingPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (block.timestamp >= tokenLaunchTime || tokenLaunched) {
                pending = pending.add(user.unclaimedReward);
                user.unclaimedReward = 0;
                safeBlingTransfer(msg.sender, pending);
            } else {
                user.unclaimedReward = user.unclaimedReward.add(pending);
            }

        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accBlingPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant() {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accBlingPerShare).div(1e12).sub(
                user.rewardDebt
            );

        if (block.timestamp >= tokenLaunchTime || tokenLaunched) {
            pending = pending.add(user.unclaimedReward);
            user.unclaimedReward = 0;
            safeBlingTransfer(msg.sender, pending);
        } else {
            user.unclaimedReward = user.unclaimedReward.add(pending);
        }

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accBlingPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant() {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe bling transfer function, just in case if rounding error causes pool to not have enough Blings.
    function safeBlingTransfer(address _to, uint256 _amount) internal {
        uint256 blingBal = bling.balanceOf(address(this));
        if (_amount > blingBal) {
            bling.transfer(_to, blingBal);
        } else {
            bling.transfer(_to, _amount);
        }
    }

    // updates Bling per block according to hard-coded phases to adjust emission rate
    function updateBlingPerBlock() public {
        require (currentBlingPhase < timeOfEachPhase.length, "no updates available!");
        require (block.timestamp > timeOfEachPhase[currentBlingPhase + 1], "wait until the next phase");
        massUpdatePools();
        currentBlingPhase ++;
        blingPerBlock = blingOfEachPhase[currentBlingPhase];
    }

    // launch the token
    function launch() public onlyOwner {
        tokenLaunched = true;
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
