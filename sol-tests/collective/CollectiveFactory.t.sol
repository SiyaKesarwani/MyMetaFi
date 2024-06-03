// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "../../contracts/collective/CollectiveFactory.sol";
import "../../contracts/collective/Collective.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/utils/LibSafeCast.sol"; 
import "../TestUtils.sol";

contract CollectiveFactoryTest is Test, TestUtils {
    using LibSafeCast for uint256;

    event CollectiveCreated(
        ICollective indexed collective,
        ICollective.GovernanceOpts opts,
        IERC721 preciousToken,
        uint256 preciousTokenId
    );

    Globals globals = new Globals(address(this));
    Collective collectiveImpl = new Collective(globals);
    CollectiveFactory factory = new CollectiveFactory(globals);
    address recipient = 0xe5ba98010c85e1386F5C06b9E947DFFF92553796;
    uint256 bps = 250;
    Collective.CollectiveInitData initData;

    constructor() {
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_FACTORY, address(factory));
        globals.setAddress(LibGlobals.GLOBAL_COLLECTIVE_IMPL, address(collectiveImpl));
        globals.setAddress(LibGlobals.GLOBAL_FEE_RECIPIENT, recipient);
        globals.setUint256(LibGlobals.GLOBAL_FEE_BPS, bps);
    }

    function _hashPreciousNFT(
        IERC721 preciousToken,
        uint256 preciousTokenId
    ) internal pure returns (bytes32 h) {
            h = keccak256(abi.encodePacked(preciousToken, preciousTokenId));
    }

    function testCreateCollective(
        uint96 randomUint96,
        uint40 randomUint40,
        uint16 randomBps
    ) external {
        ICollective.GovernanceOpts memory opts = ICollective.GovernanceOpts({
            voteDuration: randomUint40,
            vetoDuration: randomUint40,
            passThresholdBps: randomBps
        });

        IERC721 preciousToken = IERC721(_randomAddress());
        uint256 preciousTokenId = _randomUint256();
        uint96 totalVotingPower = randomUint96;
        uint256 nonceOfFactory = vm.getNonce(address(factory));
        address payable nextCollectiveAddress = payable(StdUtils.computeCreateAddress(address(factory), nonceOfFactory));

        vm.expectEmit(true, false, false, true);
        emit CollectiveCreated(
            ICollective(nextCollectiveAddress),
            opts,
            preciousToken,
            preciousTokenId
        );
        ICollective collective = factory.createCollective(
            opts,
            totalVotingPower,
            preciousToken,
            preciousTokenId,
            _randomAddress()
        );

        ICollective.GovernanceOpts memory values = collective.getGovernanceValues();
        assertEq(values.voteDuration, opts.voteDuration);
        assertEq(values.vetoDuration, opts.vetoDuration);
        assertEq(values.passThresholdBps, opts.passThresholdBps);
        assertEq(collective.preciousNFTHash(), _hashPreciousNFT(preciousToken, preciousTokenId));
    }

    function test_CannotReinitializeCollective() external {
        ICollective collective = ICollective(
            payable(address(new Proxy(collectiveImpl, abi.encodeCall(ICollective.initialize, initData))))
        );
        vm.expectRevert(abi.encodeWithSelector(Implementation.OnlyConstructorError.selector));
        collective.initialize(initData);
    }
}