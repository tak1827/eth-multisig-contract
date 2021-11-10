// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./MockERC721.sol";

/**
 * @dev N of M Multisig Contract
 * - N and M are fixed at the deploy moment
 * - The access controlled contract is instantiated at the deploy moment
 *   the controlled extend `Ownable`, so that controlled only via this multisig
 *
 * Inspired by BitGo's WalletSimple.sol
 *  https://github.com/BitGo/eth-multisig-v2/blob/master/contracts/WalletSimple.sol
 */
contract Multisig is Context, EIP712 {
    using Address for address;
    using ECDSA for bytes32;

    /* the addresses allowed to sign */
    address[] public signers;
    /* required singner number */
    uint8 public threshold;
    /* the minimum threshold */
    uint8 public MIN_THRESHOLD = 2;
    /* the adress of access controlled contract */
    address public controlled;
    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // event ControlledDeployed(address indexed controlled);

    /**
     * Modifier that will execute internal code block only if the sender is an authorized signer on this wallet
     */
    modifier onlySigner() {
        if (!isSigner(_msgSender())) {
            revert("unauthorized msg sender");
        }
        _;
    }

    constructor(
        string memory _name,
        address[] memory _signers,
        uint8 _threshold
    ) EIP712(_name, version()) {
        require(_threshold >= MIN_THRESHOLD, "threshold is too low");
        require(
            _signers.length >= _threshold,
            "signers length must be bigger than threshold"
        );

        threshold = _threshold;
        signers = _signers;
        controlled = address(new MockERC721());
    }

    function version() public view virtual returns (string memory) {
        return "1";
    }

    /**
     * @dev Determine if an address is a signer on this wallet
     * @param signer address to check
     * returns boolean indicating whether address is signer or not
     */
    function isSigner(address signer) public view returns (bool) {
        // Iterate through all signers on the wallet and
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev verify singer signatures
     * @param hash The hash of calldata
     * @param signatures The signatures
     */
    function _verifySigs(bytes32 hash, bytes[] memory signatures) internal {
        for (uint256 i = 0; i < signatures.length; i++) {
            address recoverd = hash.recover(signatures[i]);

            if (!isSigner(recoverd)) {
                revert("recoverd address is not signer");
            }

            if (approvedHashes[recoverd][hash] > 1) {
                revert("already approved signature");
            }

            approvedHashes[recoverd][hash] = 1;
        }
    }

    /**
     * @dev call controlled contract with value
     * @param signatures required more than threshold signatures
     * @param data the calldata
     */
    function callControlled(bytes[] memory signatures, bytes calldata data)
        public
        payable
        virtual
        onlySigner
        returns (bytes memory returndata)
    {
        require(signatures.length + 1 >= threshold, "insufficient signatures");
        _verifySigs(_hashTypedDataV4(keccak256(abi.encode(data))), signatures);

        return
            controlled.functionCallWithValue(
                data,
                msg.value,
                "faild to call controlled"
            );
    }
}
