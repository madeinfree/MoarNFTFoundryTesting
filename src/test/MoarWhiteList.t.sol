// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "../Moar.sol";

interface CheatCodes {
    function prank(address) external;

    function startPrank(address) external;

    function stopPrank() external;

    function warp(uint256) external;
}

contract MoarWhiteListTest is DSTest {
    using stdStorage for StdStorage;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Vm private vm = Vm(HEVM_ADDRESS);
    Moar private moar;
    StdStorage private stdstore;

    function setUp() public {
        address _authority = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address _admin = 0x00a329c0648769A73afAc7F9381E08FB43dBEA72;
        address _msgSender = msg.sender;
        moar = new Moar(_authority, _admin, _msgSender);

        cheats.startPrank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));

        uint256[] memory tierIds = new uint256[](1);
        uint256[] memory tierStartTimes = new uint256[](1);
        uint256[] memory tierDurations = new uint256[](1);
        uint256[] memory tierMaxTicketNums = new uint256[](1);
        uint256[] memory tierTicketPrices = new uint256[](1);

        for (uint256 i; i < 1; i++) {
            tierIds[i] = 0;
            tierStartTimes[i] = 5; // start at 5 seconds
            tierDurations[i] = 62400;
            tierMaxTicketNums[i] = 1;
            tierTicketPrices[i] = 0.5 ether;
        }

        moar.configSales(
            tierIds,
            tierStartTimes,
            tierDurations,
            tierMaxTicketNums,
            tierTicketPrices
        );

        cheats.warp(6); // next 6 seconds
        moar.toggleFlag(uint256(keccak256("SALE")));

        cheats.stopPrank();
    }

    function testWhiteListMintInvalidTimeRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTime.selector));
        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        cheats.warp(3); // back to 3 seconds
        moar.whitelistMint(0, 0, "1");
    }

    function testWhiteListMintInvalidSignature() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        moar.whitelistMint{value: 0.5 ether}(
            0,
            1,
            bytes(
                hex"762da19c850bde2275d4c3402e8d4c06b8229377c43308d6aa31fbab21baa689102c26dc9086ad45ab9960c73655acdf3f566722b263526a14472eefe6747bd81c"
            )
        );
    }

    function testWhiteListMintInvalidPayment() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidPayment.selector));
        moar.whitelistMint{value: 0 ether}(
            0,
            1,
            bytes(
                hex"762da19c850bde2275d4c3402e8d4c06b8229377c43308d6aa31fbab21baa689102c26dc9086ad45ab9960c73655acdf3f566722b263526a14472eefe6747bd81b"
            )
        );
    }

    function testWhiteListMint() public {
        moar.whitelistMint{value: 0.5 ether}(
            0,
            1,
            bytes(
                hex"762da19c850bde2275d4c3402e8d4c06b8229377c43308d6aa31fbab21baa689102c26dc9086ad45ab9960c73655acdf3f566722b263526a14472eefe6747bd81b"
            )
        );

        uint256 balance = moar.balanceOf(
            address(0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84)
        );

        assertEq(balance, 2);
    }
}
