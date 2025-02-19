// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../precompiles/XCM_v2.sol";
import "../utils/AddressToAccount.sol";

contract AssetTransfer {
    address public constant XCM_ADDRESS =
    0x0000000000000000000000000000000000005004;

    // This function is used to transfer asset id = 1
    // from parachain 2000 to parachain 2007
    function reserve_asset_transfer() external {

        // Destination is parachain 2007
        // as interior is parachain id 2007 prefix with 0x00
        // 0x00 + (2007 as hex = 0x000007d7)
        // Multilocation: { parents: 1, interior: [Parachain: 2007] }
        bytes[] memory interior1 = new bytes[](1);
        interior1[0] = bytes.concat(hex"00", bytes4(uint32(2007)));
        XCM.Multilocation memory destination = XCM.Multilocation({ parents: 1,
            interior: interior1});

        // beneficiary is the caller of the contract
        // first we get the AccountId32 of the H160 (accountId20) caller
        // as interior is accountId32 prefix with 0x01 and suffix with 0x00 (network: any)
        // 0x01 + AccountId32 + 0x00
        // Multilocation: { parents: 0, interior: [AccountId32: { id: *caller AccountId* , network: any }] }
        bytes32 publicKey = AddressToAccount.AddressToSubstrateAccount(
            msg.sender
        );
        bytes[] memory interior = new bytes[](1);
        interior[0] =  bytes.concat(hex"01", publicKey, hex"00");
        XCM.Multilocation memory beneficiary = XCM.Multilocation({ parents: 0,
            interior: interior});


        // This is the precompile address of asset id = 1
        // address = '0xFFFFFFFF...' + DecimalToHex(AssetId)
        address assetAddress = 0xFfFFFFff00000000000000000000000000000001;
        uint256 amount = 100000000000000000000;

        // The contract will be the Origin of the XCM
        // So first approve the contract to spend asset id = 1 on behalf of the caller
        // contract will transfer the asset to itself first
        // and it will be transferred to beneficiary of the XCM
        IERC20 erc20 = IERC20(assetAddress);
        erc20.transferFrom(msg.sender, address(this), amount);

        address[] memory assetId = new address[](1);
        assetId[0] = assetAddress;
        uint256[] memory assetAmount = new uint256[](1);
        assetAmount[0] = amount;

        // Send the XCM via XCM precompile
        require(
            XCM(XCM_ADDRESS).assets_reserve_transfer(
                assetId,
                assetAmount,
                beneficiary,
                destination,
                0
            ),
            "Failed to send xcm"
        );
    }
}
