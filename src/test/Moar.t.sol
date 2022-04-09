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

contract MoarTest is DSTest {
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

    function testOwnerBalanceIsOne() public {
        assertEq(moar.balanceOf(moar.owner()), 1);
    }

    /**
     * error InvalidSaleOn()
     */
    function testWhiteListMintInvalidSaleOnRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidSaleOn.selector));
        moar.whitelistMint(0, 0, "1");
    }

    /**
     * error NonAdmin()
     */
    function testWhiteListMintNonAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(NonAdmin.selector));
        moar.toggleFlag(uint256(keccak256("SALE")));
    }
}
