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
        uint256 slotBalance = stdstore
            .target(address(moar))
            .sig(moar.balanceOf.selector)
            .with_key(moar.owner())
            .find();
        uint256 balanceFirstMint = uint256(
            vm.load(address(moar), bytes32(slotBalance))
        );
        assertEq(balanceFirstMint, 1);
    }

    /**
     * error InvalidSaleOn()
     */
    function testFailWhiteListMintNotOnSale() public {
        moar.whitelistMint(0, 0, "1");
    }

    /**
     * error NonAdmin()
     */
    function testFailWhiteListMintNonAdmin() public {
        moar.toggleFlag(uint256(keccak256("SALE")));
        moar.whitelistMint(0, 0, "1");
    }
}
