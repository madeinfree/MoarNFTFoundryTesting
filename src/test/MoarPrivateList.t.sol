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
    }

    function testPrivateMintNonAdminRevert() public {
        vm.expectRevert(abi.encodeWithSelector(NonAdmin.selector));
        cheats.prank(address(0x1337));
        address[] memory ads = new address[](1);
        ads[0] = address(this);
        moar.privateMint(ads);
    }

    function testPrivateMintInvalidSaleOnRevert() public {
        cheats.startPrank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        moar.toggleFlag(uint256(keccak256("SALE")));

        vm.expectRevert(abi.encodeWithSelector(InvalidSaleOn.selector));
        address[] memory ads = new address[](1);
        ads[0] = address(this);
        moar.privateMint(ads);

        cheats.stopPrank();
    }

    function testPrivateMintExceedMaxSupplyRevert() public {
        uint256 slot = stdstore
            .target(address(moar))
            .sig("totalSupply()")
            .find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedMaxSupply = bytes32(abi.encode(5555));
        vm.store(address(moar), loc, mockedMaxSupply);

        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        vm.expectRevert(abi.encodeWithSelector(ExceedMaxSupply.selector));
        address[] memory ads = new address[](1);
        ads[0] = address(1);
        moar.privateMint(ads);
    }

    function testPrivateMint() public {
        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        address[] memory ads = new address[](1);
        ads[0] = address(1);
        moar.privateMint(ads);

        assertEq(moar.balanceOf(address(1)), 1);
    }
}
