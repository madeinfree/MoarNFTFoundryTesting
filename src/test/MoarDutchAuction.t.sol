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

contract MoarDutchAuctionTest is DSTest {
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

        uint256[] memory tierIds = new uint256[](2);
        uint256[] memory tierStartTimes = new uint256[](2);
        uint256[] memory tierDurations = new uint256[](2);
        uint256[] memory tierMaxTicketNums = new uint256[](2);
        uint256[] memory tierTicketPrices = new uint256[](2);

        for (uint256 i; i < 2; i++) {
            tierIds[i] = i;
            tierStartTimes[i] = 1649335500 + (62400 * i);
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

        moar.toggleFlag(uint256(keccak256("SALE"))); // default Open SALE

        cheats.stopPrank();

        cheats.warp(1649335500 + 1);
    }

    function testMDAIsSaleOnRevert() public {
        cheats.prank(address(0x00a329c0648769A73afAc7F9381E08FB43dBEA72));
        moar.toggleFlag(uint256(keccak256("SALE"))); // close SALE

        vm.expectRevert(abi.encodeWithSelector(InvalidSaleOn.selector));

        cheats.prank(tx.origin);
        moar.dutchAuctionMint(
            0,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );
    }

    function testMDAInvalidTimeRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidTime.selector));

        cheats.warp(1649335500 - 1);
        cheats.prank(tx.origin);

        moar.dutchAuctionMint(
            0,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );
    }

    function testMDAInvalidSignatureRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));

        cheats.warp(1649335500);
        cheats.prank(tx.origin);

        moar.dutchAuctionMint(
            0,
            bytes(
                hex"973fc6a8ba8adbd0f68225fff765bf12f576c5d9a76157f3d35d018e59fd299015d956c47508d36b8bc68a2ef0b1107dcf51e5f69cc692c942f3bb77590ee26b1c"
            )
        );
    }

    function testMDAExceedAuctionSupplyFromZeroBuyRevert() public {
        vm.expectRevert(abi.encodeWithSelector(ExceedAuctionSupply.selector));

        cheats.warp(1649335500);
        cheats.prank(tx.origin);

        moar.dutchAuctionMint(
            0,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );
    }

    function testMDAExceedAuctionSupplyFromDHDATotalSupplyRevert() public {
        uint256 slot = stdstore
            .target(address(moar))
            .sig("DHDATotalSupply()")
            .find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedDHDATotalSupply = bytes32(abi.encode(4110));
        vm.store(address(moar), loc, mockedDHDATotalSupply);

        vm.expectRevert(abi.encodeWithSelector(ExceedAuctionSupply.selector));

        cheats.warp(1649335500);
        cheats.prank(tx.origin);

        moar.dutchAuctionMint(
            1,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );
    }

    function testMDAInvalidPaymentRevert() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidPayment.selector));

        cheats.warp(1649335500);
        cheats.prank(tx.origin);

        moar.dutchAuctionMint{value: 0 ether}(
            1,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );
    }

    function testMDADutchAuctionPrice() public {
        for (uint256 i = 0; i < 4; i++) {
            cheats.warp(1649335500 + (45 minutes * i));
            uint256 dutchAuctionPrice = moar.dutchAuctionPrice();

            assertEq(dutchAuctionPrice, 0.5 ether - (i * 0.1 ether));
        }
    }

    function testMDAMint() public {
        uint256 dutchAuctionPrice = moar.dutchAuctionPrice();

        cheats.warp(1649335500);
        cheats.prank(tx.origin);

        moar.dutchAuctionMint{value: dutchAuctionPrice}(
            1,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );

        assertEq(moar.balanceOf(address(tx.origin)), 1);
    }

    function testMDAMintNextStep() public {
        cheats.warp(1649335500 + (45 minutes * 1));

        cheats.prank(tx.origin);
        moar.dutchAuctionMint{value: 0.4 ether}(
            1,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );

        assertEq(moar.balanceOf(address(tx.origin)), 1);
    }

    function testMDAMintNextNextStep() public {
        cheats.warp(1649335500 + (45 minutes * 2));

        cheats.prank(tx.origin);
        moar.dutchAuctionMint{value: 0.3 ether}(
            1,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );

        assertEq(moar.balanceOf(address(tx.origin)), 1);
    }

    function testMDAMintEndStep() public {
        cheats.warp(1649335500 + (45 minutes * 4));

        cheats.prank(tx.origin);
        moar.dutchAuctionMint{value: 0.1 ether}(
            1,
            bytes(
                hex"c9de4848636b15740e6261ff43b6549764995f15938b1759a6ea87fedd8a35443061f2b8865ab27ab9e66ec5419616400c19cc039d15d1cf36f636c4c704ece71c"
            )
        );

        assertEq(moar.balanceOf(address(tx.origin)), 1);
    }
}
