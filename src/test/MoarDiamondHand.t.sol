// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "../Moar.sol";

interface CheatCodes {
    function prank(address) external;

    function warp(uint256) external;
}

contract MoarDutchAuctionTest is DSTest {
    using stdStorage for StdStorage;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Vm private vm = Vm(HEVM_ADDRESS);
    Moar private moar;
    StdStorage private stdstore;

    uint256 public constant DIAMOND_HAND_ID =
        uint256(keccak256("DIAMOND_HAND_ID"));

    function setUp() public {
        address _authority = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address _admin = 0x00a329c0648769A73afAc7F9381E08FB43dBEA72;
        address _msgSender = msg.sender;
        moar = new Moar(_authority, _admin, _msgSender);

        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));

        uint256[] memory tierIds = new uint256[](1);
        uint256[] memory tierStartTimes = new uint256[](1);
        uint256[] memory tierDurations = new uint256[](1);
        uint256[] memory tierMaxTicketNums = new uint256[](1);
        uint256[] memory tierTicketPrices = new uint256[](1);

        for (uint256 i; i < 1; i++) {
            tierIds[i] = DIAMOND_HAND_ID;
            tierStartTimes[i] = 1649335500;
            tierDurations[i] = 62400;
            tierMaxTicketNums[i] = 1;
            tierTicketPrices[i] = 0.05 ether;
        }

        moar.configSales(
            tierIds,
            tierStartTimes,
            tierDurations,
            tierMaxTicketNums,
            tierTicketPrices
        );

        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        moar.toggleFlag(uint256(keccak256("SALE")));
    }

    function testDHDAIsSaleOnRevert() public {
        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        moar.toggleFlag(uint256(keccak256("SALE")));

        vm.expectRevert(abi.encodeWithSelector(InvalidSaleOn.selector));

        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );
    }

    function testDHDAInvalidSignatureRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));

        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint(
            1,
            bytes(
                hex"312d9a1d41f007e1ae55dda8a6d093f0bd7af17fb0c96b7d26d60cc259cb6b1e504c90c89301b957227a1d4582c63e9e5cd12f398b9aaa016ef567e9921edb461c"
            )
        );
    }

    function testDHDAContractBidderRevert() public {
        vm.expectRevert(abi.encodeWithSelector(ContractBidder.selector));

        cheats.warp(1649335500);
        moar.diamondHandMint(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );
    }

    function testDHDAInvalidTimeRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTime.selector));

        cheats.prank(tx.origin);
        moar.diamondHandMint(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );
    }

    function testDHDAExceedDiamondHandSupplyRevert() public {
        vm.expectRevert(
            abi.encodeWithSelector(ExceedDiamondHandSupply.selector)
        );

        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint(
            0,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );
    }

    function testDHDAMint() public {
        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint{value: 0.05 ether}(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );
        assertEq(moar.balanceOf(tx.origin), 1);
    }

    function testDHDANonOwnerOrApprovedRevert() public {
        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint{value: 0.05 ether}(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );

        vm.expectRevert(abi.encodeWithSelector(NonOwnerOrApproved.selector));
        moar.safeTransferFrom(tx.origin, address(0x1337), 2);
    }

    function testDHDATransferLockedRevert() public {
        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint{value: 0.05 ether}(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );

        vm.expectRevert(abi.encodeWithSelector(TransferLocked.selector));
        cheats.prank(tx.origin);
        moar.safeTransferFrom(tx.origin, address(0x1337), 2);
    }

    function testDHDALockTransfer() public {
        cheats.warp(1649335500);
        cheats.prank(tx.origin);
        moar.diamondHandMint{value: 0.05 ether}(
            1,
            bytes(
                hex"9dce314f037f0f750cda11662d857bd2c2aa5128e1d59b7fc83832e3633b87125cb03461f35fa09c651e78cbfa3d308ce56ad23452561963128e4e0cdd40c7371b"
            )
        );

        uint256[] memory tokenIds = new uint256[](1);
        bool[] memory locks = new bool[](1);

        for (uint256 i; i < 1; i++) {
            tokenIds[i] = 2;
            locks[i] = false;
        }

        cheats.prank(tx.origin);
        moar.lockTransfers(tokenIds, locks);

        cheats.prank(tx.origin);
        moar.transferFrom(tx.origin, address(0x1337), 2);

        assertEq(moar.balanceOf(address(0x1337)), 1);
        assertEq(moar.balanceOf(tx.origin), 0);
    }
}
