// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/RehabPoints.sol";

contract RehabPointsTest is Test {
    RehabPoints public rehabPoints;

    address public admin;
    address public doctor;
    address public patient;

    function setUp() public {
        admin = vm.addr(0x1);
        doctor = vm.addr(0x2);
        patient = vm.addr(0x3);

        vm.prank(admin);
        rehabPoints = new RehabPoints();
    }

    /// -----------------------------------------------------------------------
    ///  DEPLOYMENT & INITIAL STATE
    /// -----------------------------------------------------------------------

    function testDeployment() public {
        assertEq(rehabPoints.admin(), admin);
        assertTrue(rehabPoints.isMember(admin));
        assertEq(rehabPoints.totalPoints(), 0);
    }

    /// -----------------------------------------------------------------------
    ///  MEMBERSHIP
    /// -----------------------------------------------------------------------

    function testJoinAsMember() public {
        assertFalse(rehabPoints.isMember(patient));

        vm.prank(patient);
        rehabPoints.joinAsMember();

        assertTrue(rehabPoints.isMember(patient));
    }

    function testJoinAsMemberAlreadyMember() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        vm.expectRevert(bytes("Already a member"));
        rehabPoints.joinAsMember();
    }

    /// -----------------------------------------------------------------------
    ///  EARN POINTS
    /// -----------------------------------------------------------------------

    function testEarnPoints() public {
        vm.warp(1);
        vm.prank(doctor);
        rehabPoints.joinAsMember();

        vm.prank(doctor);
        rehabPoints.earnPoints(100, "Completed exercise");

        assertEq(rehabPoints.getPoints(doctor), 100);
    }

    function testEarnPointsNotMember() public {
        assertFalse(rehabPoints.isMember(doctor));

        vm.prank(doctor);
        vm.expectRevert(RehabPoints.NotMember.selector);
        rehabPoints.earnPoints(100, "Not a member");
    }

    function testEarnPointsZeroAmount() public {
        vm.prank(doctor);
        rehabPoints.joinAsMember();

        vm.prank(doctor);
        vm.expectRevert(bytes("Amount must be greater than zero"));
        rehabPoints.earnPoints(0, "Zero points");
    }

    function testEarnPointsCooldown() public {
        vm.warp(1);
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        rehabPoints.earnPoints(100, "first");

        vm.warp(block.timestamp + 1 days);

        vm.prank(patient);
        rehabPoints.earnPoints(100, "second");

        vm.warp(block.timestamp + 1 days);

        vm.prank(patient);
        rehabPoints.earnPoints(100, "third");

        assertEq(rehabPoints.getPoints(patient), 300);
    }

    /// -----------------------------------------------------------------------
    ///  ADMIN GRANT POINTS
    /// -----------------------------------------------------------------------

    function testGrantPoints() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 200, "Doctor visit");

        assertEq(rehabPoints.getPoints(patient), 200);
    }

    function testGrantPointsNotAdmin() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotAdmin.selector);
        rehabPoints.grantPoints(patient, 100, "Unauthorized");
    }

    function testGrantPointsZeroAmount() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        vm.expectRevert(bytes("Amount must be positive"));
        rehabPoints.grantPoints(patient, 0, "Zero points");
    }

    /// -----------------------------------------------------------------------
    ///  TRANSFER POINTS
    /// -----------------------------------------------------------------------

    function testTransferPoints() public {
        vm.prank(doctor);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 150, "Initial points");

        vm.prank(patient);
        rehabPoints.transferPoints(doctor, 50);

        assertEq(rehabPoints.getPoints(patient), 100);
        assertEq(rehabPoints.getPoints(doctor), 50);
    }

    function testTransferPointsNotMemberReceiver() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Points");

        assertFalse(rehabPoints.isMember(doctor));

        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotMember.selector);
        rehabPoints.transferPoints(doctor, 50);
    }

    function testTransferPointsZeroAmount() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Points");

        vm.prank(patient);
        vm.expectRevert(RehabPoints.ZeroAmount.selector);
        rehabPoints.transferPoints(doctor, 0);
    }

    function testTransferPointsZeroAddress() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Points");

        vm.prank(patient);
        vm.expectRevert(RehabPoints.ZeroAddress.selector);
        rehabPoints.transferPoints(address(0), 50);
    }

    function testTransferPointsInsufficientBalance() public {
        vm.prank(doctor);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(doctor, 50, "Few points");

        vm.prank(doctor);
        vm.expectRevert(RehabPoints.NotEnoughPoints.selector);
        rehabPoints.transferPoints(patient, 100);
    }

    /// -----------------------------------------------------------------------
    ///  REDEEM POINTS
    /// -----------------------------------------------------------------------

    function testRedeemPoints() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 200, "Refill");

        vm.prank(patient);
        rehabPoints.redeemPoints(150, "Use points");

        assertEq(rehabPoints.getPoints(patient), 50);
    }

    function testRedeemPointsNotEnoughPoints() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Refill");

        vm.prank(patient);
        vm.expectRevert(bytes("Insufficient points"));
        rehabPoints.redeemPoints(150, "Too much");
    }

    function testRedeemPointsZeroAmount() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Refill");

        vm.prank(patient);
        vm.expectRevert(bytes("Amount must be greater than zero"));
        rehabPoints.redeemPoints(0, "Zero");
    }

    /// -----------------------------------------------------------------------
    ///  REWARD CONFIGURATION
    /// -----------------------------------------------------------------------

    function testSetReward() public {
        vm.prank(admin);
        rehabPoints.setReward(RehabPoints.RewardType.Massage, 1500, true);

        RehabPoints.Reward memory reward = rehabPoints.getReward(RehabPoints.RewardType.Massage);
        assertEq(reward.cost, 1500);
        assertTrue(reward.active);
    }

    function testSetRewardNotAdmin() public {
        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotAdmin.selector);
        rehabPoints.setReward(RehabPoints.RewardType.Massage, 1500, true);
    }

    function testSetRewardActiveWithZeroCost() public {
        vm.prank(admin);
        vm.expectRevert(RehabPoints.ZeroAmount.selector);
        rehabPoints.setReward(RehabPoints.RewardType.Massage, 0, true);
    }

    function testSetRewardToInactive() public {
        vm.prank(admin);
        rehabPoints.setReward(RehabPoints.RewardType.Tshirt, 1000, false);

        RehabPoints.Reward memory reward = rehabPoints.getReward(RehabPoints.RewardType.Tshirt);
        assertFalse(reward.active);
    }

    /// -----------------------------------------------------------------------
    ///  FALLBACK & RECEIVE
    /// -----------------------------------------------------------------------

    function testReceiveEther() public {
        vm.deal(patient, 1 ether);

        vm.prank(patient);
        vm.expectRevert(bytes("ETH not accepted"));
        address(rehabPoints).call{value: 1 ether}("");
    }

    function testFallback() public {
        vm.prank(patient);
        vm.expectRevert(bytes("ETH not accepted"));
        address(rehabPoints).call("invalidFunction");
    }
}