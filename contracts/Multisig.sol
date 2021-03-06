// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./MockERC721.sol";

/**
 * @dev N of M Multisig Contract
 * - M of N is fixed at the deploy moment
 * - The access controlled contract is instantiated at the deploy moment
 *   the controlled extend `Ownable`, so that controlled only via this multisig
 * - the length of signers CANNOT be changed once they are set
 *
 * Inspired by BitGo's WalletSimple.sol
 *  https://github.com/BitGo/eth-multisig-v2/blob/master/contracts/WalletSimple.sol
 */
contract Multisig is Context {
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

    event Called(address caller, bytes data, bytes returndata);
    event SignerReplaced(address indexed oldSinger, address indexed newSinger);

    /**
     * Modifier that will execute internal code block only if the sender is an authorized signer on this wallet
     */
    modifier onlySigner() {
        (bool ok, ) = isSigner(_msgSender());
        if (!ok) {
            revert("unauthorized msg sender");
        }
        _;
    }

    constructor(address[] memory _signers, uint8 _threshold) {
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
     * returns
     *  - boolean indicating whether address is signer or not,
     *  - the index of target address
     */
    function isSigner(address signer) public view returns (bool, uint256) {
        // Iterate through all signers on the wallet and
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @dev verify singer signatures
     * @param hash The hash of calldata
     * @param signatures The signatures
     */
    function _verifySigs(bytes32 hash, bytes[] memory signatures) internal {
        for (uint256 i = 0; i < signatures.length; i++) {
            address recoverd = hash.recover(signatures[i]);

            (bool ok, ) = isSigner(recoverd);
            if (!ok) {
                revert("recoverd address is not signer");
            }

            if (recoverd == _msgSender()) {
                revert("msg.sender should not be signer");
            }

            if (approvedHashes[recoverd][hash] >= 1) {
                revert("already approved signature");
            }

            approvedHashes[recoverd][hash] = 1;
        }
    }

    /**
     * @dev call controlled contract without value
     * @param signatures required more than threshold signatures
     * @param data the calldata
     */
    function callControlled(bytes[] memory signatures, bytes calldata data)
        public
        payable
        virtual
        onlySigner
        returns (bytes memory)
    {
        require(signatures.length + 1 >= threshold, "insufficient signatures");
        _verifySigs(ECDSA.toEthSignedMessageHash(keccak256(data)), signatures);

        bytes memory returndata = controlled.functionCall(
            data,
            "faild to call controlled"
        );

        emit Called(_msgSender(), data, returndata);

        return returndata;
    }

    /**
     * @dev replace signer, only authorized by signer
     * @param newSinger the new signer address
     */
    function replaceSinger(address newSinger) public {
        (bool ok, uint256 i) = isSigner(_msgSender());
        if (!ok) {
            revert("unauthorized msg sender");
        }
        signers[i] = newSinger;
        emit SignerReplaced(_msgSender(), newSinger);
    }
}
