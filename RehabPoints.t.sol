// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../src/RehabPoints.sol";

/// @title Testfil för RehabPoints-kontraktet
/// @notice Täcker alla funktioner, felvägar och brancher för att nå hög coverage
contract RehabPointsTest is Test {
    RehabPoints public rehabPoints;

    // Testadresser (simulerade användare)
    address public admin;
    address public doctor;
    address public patient;

    /// @notice Körs innan varje test – sätter upp en ren miljö
    function setUp() public {
        admin = vm.addr(0x1);
        doctor = vm.addr(0x2);
        patient = vm.addr(0x3);

        // Deploya kontraktet som admin
        vm.prank(admin);
        rehabPoints = new RehabPoints();
    }

    /// -----------------------------------------------------------------------
    ///  DEPLOYMENT & INITIAL STATE
    /// -----------------------------------------------------------------------

    function testDeployment() public {
        // Admin ska vara korrekt satt
        assertEq(rehabPoints.admin(), admin);

        // Admin ska automatiskt vara medlem
        assertTrue(rehabPoints.isMember(admin));

        // Inga poäng ska finnas vid start
        assertEq(rehabPoints.totalPoints(), 0);
    }

    /// -----------------------------------------------------------------------
    ///  MEDLEMSKAP
    /// -----------------------------------------------------------------------

    function testJoinAsMember() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        // Kontrollera att patienten nu är medlem
        assertTrue(rehabPoints.isMember(patient));
    }

    function testJoinAsMemberAlreadyMember() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        // Försök gå med igen → ska revert:a med AlreadyMember
        vm.prank(patient);
        vm.expectRevert(RehabPoints.AlreadyMember.selector);
        rehabPoints.joinAsMember();
    }

    /// -----------------------------------------------------------------------
    ///  EARN POINTS
    /// -----------------------------------------------------------------------

    function testEarnPoints() public {
        // Gör patient till medlem
        vm.prank(patient);
        rehabPoints.joinAsMember();

        // Tjäna poäng
        vm.prank(patient);
        rehabPoints.earnPoints(100, "Completed exercise");

        assertEq(rehabPoints.getPoints(patient), 100);
        assertEq(rehabPoints.totalPoints(), 100);
    }

    function testEarnPointsNotMember() public {
        // Ej medlem → ska revert:a
        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotMember.selector);
        rehabPoints.earnPoints(100, "Not a member");
    }

    /// -----------------------------------------------------------------------
    ///  ADMIN GRANT POINTS
    /// -----------------------------------------------------------------------

    function testGrantPoints() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 200, "Doctor visit");

        assertTrue(rehabPoints.isMember(patient));
        assertEq(rehabPoints.getPoints(patient), 200);
        assertEq(rehabPoints.totalPoints(), 200);
    }

    function testGrantPointsNotAdmin() public {
        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotAdmin.selector);
        rehabPoints.grantPoints(doctor, 100, "Unauthorized");
    }

    /// -----------------------------------------------------------------------
    ///  TRANSFER POINTS
    /// -----------------------------------------------------------------------

    function testTransferPoints() public {
        // Gör doctor till medlem
        vm.prank(doctor);
        rehabPoints.joinAsMember();

        // Ge patienten poäng
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 150, "Initial points");

        // Överför poäng
        vm.prank(patient);
        rehabPoints.transferPoints(doctor, 50);

        assertEq(rehabPoints.getPoints(patient), 100);
        assertEq(rehabPoints.getPoints(doctor), 50);
        assertEq(rehabPoints.totalPoints(), 150);
    }

    function testTransferPointsNotMemberReceiver() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Points");

        // doctor är inte medlem → revert
        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotMember.selector);
        rehabPoints.transferPoints(doctor, 50);
    }

    /// -----------------------------------------------------------------------
    ///  REDEEM REWARD
    /// -----------------------------------------------------------------------

    function testRedeemReward() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 2000, "Enough points");

        vm.prank(patient);
        rehabPoints.redeemReward(RehabPoints.RewardType.Tshirt);

        assertEq(rehabPoints.getPoints(patient), 1000);
        assertEq(rehabPoints.totalPoints(), 1000);
    }

    function testRedeemRewardInactive() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 3000, "Points");

        vm.prank(patient);
        vm.expectRevert(RehabPoints.RewardInactive.selector);
        rehabPoints.redeemReward(RehabPoints.RewardType.Other);
    }

    function testRedeemRewardNotEnoughPoints() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 500, "Few points");

        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotEnoughPoints.selector);
        rehabPoints.redeemReward(RehabPoints.RewardType.Tshirt);
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

    /// -----------------------------------------------------------------------
    ///  ZERO CHECKS
    /// -----------------------------------------------------------------------

    function testEarnPointsZeroAmount() public {
        vm.prank(patient);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        vm.expectRevert(RehabPoints.ZeroAmount.selector);
        rehabPoints.earnPoints(0, "Zero points");
    }

    function testGrantPointsZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert(RehabPoints.ZeroAmount.selector);
        rehabPoints.grantPoints(patient, 0, "Zero points");
    }

    function testGrantPointsZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(RehabPoints.ZeroAddress.selector);
        rehabPoints.grantPoints(address(0), 100, "Zero address");
    }

    function testTransferPointsZeroAmount() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Points");

        vm.prank(patient);
        vm.expectRevert(RehabPoints.ZeroAmount.selector);
        rehabPoints.transferPoints(doctor, 0);
    }

    function testTransferPointsZeroAddress() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Points");

        vm.prank(patient);
        vm.expectRevert(RehabPoints.ZeroAddress.selector);
        rehabPoints.transferPoints(address(0), 50);
    }

    function testTransferPointsInsufficientBalance() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 50, "Few points");

        vm.prank(doctor);
        rehabPoints.joinAsMember();

        vm.prank(patient);
        vm.expectRevert(RehabPoints.NotEnoughPoints.selector);
        rehabPoints.transferPoints(doctor, 100);
    }

    /// -----------------------------------------------------------------------
    ///  FALLBACK & RECEIVE
    /// -----------------------------------------------------------------------

    function testReceiveEther() public {
        vm.deal(patient, 1 ether);

        vm.prank(patient);
        (bool success,) = address(rehabPoints).call{value: 1 ether}("");

        assertTrue(success);
        assertEq(address(rehabPoints).balance, 1 ether);
    }

    function testFallback() public {
        vm.prank(patient);
        (bool success,) = address(rehabPoints).call("invalidFunction");

        assertTrue(success);
    }

    /// -----------------------------------------------------------------------
    ///  MULTIPLE ADDITIONS (branch coverage)
    /// -----------------------------------------------------------------------

    function testMultiplePointAdditions() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "First grant");

        vm.prank(admin);
        rehabPoints.grantPoints(patient, 200, "Second grant");

        // Patient is already a member from grantPoints, so no need to joinAsMember
        vm.prank(patient);
        rehabPoints.earnPoints(50, "Earned");

        assertEq(rehabPoints.getPoints(patient), 350);
        assertEq(rehabPoints.totalPoints(), 350);
    }
         // ... (efter dina tidigare tester, t.ex. efter testMultiplePointAdditions)

    /// -----------------------------------------------------------------------
    ///  SISTA STEG FÖR 100% COVERAGE
    /// -----------------------------------------------------------------------

    /// @notice Testar overflow för att trigga assert i _addPoints (Ger Branch Coverage för assert)
    /// @notice Testar att ge poäng till någon som REDAN är medlem (Ger Branch Coverage i grantPoints)
    function testGrantPointsToExistingMember() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "First");
        
        // Nu är patienten redan medlem. Ge poäng igen för att täcka 'else'-logiken
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 100, "Second");
        
        assertEq(rehabPoints.getPoints(patient), 200);
    }

    /// @notice Verifierar att totalPoints faktiskt minskar (Täcker unchecked-logik i redeemReward)
    function testTotalPointsDecreasesOnRedeem() public {
        vm.prank(admin);
        rehabPoints.grantPoints(patient, 2000, "Refill");
        uint128 totalBefore = rehabPoints.totalPoints();

        vm.prank(patient);
        rehabPoints.redeemReward(RehabPoints.RewardType.Tshirt);

        assertEq(rehabPoints.totalPoints(), totalBefore - 1000);
    }

    /// @notice Testar att sätta en belöning till inaktiv (Ger Branch Coverage i setReward)
    function testSetRewardToInactive() public {
        vm.prank(admin);
        rehabPoints.setReward(RehabPoints.RewardType.Tshirt, 1000, false);
        
        RehabPoints.Reward memory reward = rehabPoints.getReward(RehabPoints.RewardType.Tshirt);
        assertFalse(reward.active);
    }

}