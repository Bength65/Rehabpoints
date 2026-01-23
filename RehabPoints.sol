// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title RehabPoints – Medlemsbaserat poäng- och belöningssystem
/// @author Bengt Hafström
/// @notice Detta kontrakt hanterar medlemmar, poäng, belöningar och inlösen.
/// @dev Innehåller gasoptimeringar, säkerhetsåtgärder.

contract RehabPoints {

    // -------------------------------------------------------------------------
    //  ENUMS & STRUCTS
    // -------------------------------------------------------------------------

    /// @notice Typer av belöningar som kan lösas in av medlemmar.
    enum RewardType {
        Tshirt,
        Massage,
        Vardmote,
        Vip,
        Other
    }

    /// @notice Representerar en belöningstyp med kostnad och aktiv status.
    struct Reward {
        uint96 cost;     // Poängkostnad (uint96 för gasoptimering)
        bool active;     // Om belöningen är tillgänglig
    }

    // -------------------------------------------------------------------------
    //  CUSTOM ERRORS (gasoptimerade)
    // -------------------------------------------------------------------------

    error NotMember();
    error AlreadyMember();
    error NotAdmin();
    error RewardInactive();
    error NotEnoughPoints();
    error ZeroAddress();
    error ZeroAmount();

    // -------------------------------------------------------------------------
    //  STATE VARIABLES
    // -------------------------------------------------------------------------

    /// @notice Administratören av kontraktet (immutable för gasoptimering).
    address public immutable admin;

    /// @notice Poängsaldo per medlem.
    mapping(address => uint96) private _points;

    /// @notice Registrerade medlemmar.
    mapping(address => bool) private _isMember;

    /// @notice Belöningskonfiguration per RewardType.
    mapping(RewardType => Reward) private _rewards;

    /// @notice Totala poäng i systemet.
    uint128 public totalPoints;

    // -------------------------------------------------------------------------
    //  EVENTS
    // -------------------------------------------------------------------------

    event MemberJoined(address indexed member);
    event PointsEarned(address indexed member, uint96 amount, string reason);
    event PointsTransferred(address indexed from, address indexed to, uint96 amount);
    event PointsRedeemed(address indexed member, RewardType indexed rewardType, uint96 cost);
    event RewardUpdated(RewardType indexed rewardType, uint96 cost, bool active);
    event AdminPointsGranted(address indexed to, uint96 amount, string reason);
    event EtherReceived(address indexed from, uint256 amount);
    event FallbackCalled(address indexed from, uint256 amount, bytes data);

    // -------------------------------------------------------------------------
    //  MODIFIERS
    // -------------------------------------------------------------------------

    /// @notice Begränsar funktioner till administratören.
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// @notice Begränsar funktioner till registrerade medlemmar.
    modifier onlyMember() {
        if (!_isMember[msg.sender]) revert NotMember();
        _;
    }

    // -------------------------------------------------------------------------
    //  CONSTRUCTOR
    // -------------------------------------------------------------------------

    /// @notice Initierar kontraktet och sätter standardbelöningar.
    constructor() {
        admin = msg.sender;

        _rewards[RewardType.Tshirt] = Reward({cost: 1000, active: true});
        _rewards[RewardType.Massage] = Reward({cost: 1500, active: true});
        _rewards[RewardType.Vardmote] = Reward({cost: 2500, active: true});
        _rewards[RewardType.Vip] = Reward({cost: 5000, active: true});
        _rewards[RewardType.Other] = Reward({cost: 2000, active: false});

        _isMember[msg.sender] = true;
        emit MemberJoined(msg.sender);
    }

    // -------------------------------------------------------------------------
    //  RECEIVE & FALLBACK
    // -------------------------------------------------------------------------

    /// @notice Tar emot ETH (donationer).
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @notice Fångar anrop som inte matchar någon funktion.
    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }

    // -------------------------------------------------------------------------
    //  MEMBERSHIP LOGIC
    // -------------------------------------------------------------------------

    /// @notice Låter vem som helst bli medlem.
    function joinAsMember() external {
        if (_isMember[msg.sender]) revert AlreadyMember();
        _isMember[msg.sender] = true;
        emit MemberJoined(msg.sender);
    }

    /// @notice Kontrollerar om en adress är medlem.
    function isMember(address account) external view returns (bool) {
        return _isMember[account];
    }

    // -------------------------------------------------------------------------
    //  POINT MANAGEMENT
    // -------------------------------------------------------------------------

    /// @notice Medlem tjänar poäng genom egen aktivitet.
    function earnPoints(uint96 amount, string calldata reason) external onlyMember {
        if (amount == 0) revert ZeroAmount();
        _addPoints(msg.sender, amount);
        emit PointsEarned(msg.sender, amount, reason);
    }

    /// @notice Admin tilldelar poäng till valfri medlem.
    function grantPoints(address to, uint96 amount, string calldata reason) external onlyAdmin {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        if (!_isMember[to]) {
            _isMember[to] = true;
            emit MemberJoined(to);
        }

        _addPoints(to, amount);
        emit AdminPointsGranted(to, amount, reason);
    }

    /// @notice Överför poäng mellan medlemmar.
    function transferPoints(address to, uint96 amount) external onlyMember {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (!_isMember[to]) revert NotMember();

        uint96 senderBalance = _points[msg.sender];
        if (senderBalance < amount) revert NotEnoughPoints();

        unchecked {
            _points[msg.sender] = senderBalance - amount;
        }

        _points[to] += amount;

        emit PointsTransferred(msg.sender, to, amount);
    }

    /// @notice Hämtar poängsaldo för en adress.
    function getPoints(address account) external view returns (uint96) {
        return _points[account];
    }

    // -------------------------------------------------------------------------
    //  REWARD LOGIC
    // -------------------------------------------------------------------------

    /// @notice Admin uppdaterar en belöning.
    function setReward(RewardType rewardType, uint96 cost, bool active) external onlyAdmin {
        if (active && cost == 0) revert ZeroAmount();
        _rewards[rewardType] = Reward({cost: cost, active: active});
        emit RewardUpdated(rewardType, cost, active);
    }

    /// @notice Hämtar info om en belöning.
    function getReward(RewardType rewardType) external view returns (Reward memory) {
        return _rewards[rewardType];
    }

    /// @notice Medlem löser in en belöning.
    function redeemReward(RewardType rewardType) external onlyMember {
        Reward memory reward = _rewards[rewardType];
        if (!reward.active) revert RewardInactive();
        if (reward.cost == 0) revert ZeroAmount();

        uint96 balance = _points[msg.sender];
        if (balance < reward.cost) revert NotEnoughPoints();

        unchecked {
            _points[msg.sender] = balance - reward.cost;
            totalPoints -= uint128(reward.cost);
        }

        emit PointsRedeemed(msg.sender, rewardType, reward.cost);
    }

    // -------------------------------------------------------------------------
    //  INTERNAL LOGIC
    // -------------------------------------------------------------------------

    function _addPoints(address to, uint96 amount) internal {
        _points[to] += amount;

        unchecked {
            totalPoints += uint128(amount);
        }
    }
    
}