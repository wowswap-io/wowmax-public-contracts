// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../interfaces/IWowmaxRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHashflowRouter {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function tradeSingleHop(RFQTQuote calldata quote) external payable;
}

library Hashflow {
    function swap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        IHashflowRouter.RFQTQuote memory quote = abi.decode(subRoute.data, (IHashflowRouter.RFQTQuote));
        IERC20(subRoute.from).approve(subRoute.addr, amountIn);
        if (amountIn < quote.maxBaseTokenAmount) {
            quote.effectiveBaseTokenAmount = amountIn;
        }

        uint256 balanceBefore = IERC20(subRoute.to).balanceOf(address(this));
        IHashflowRouter(subRoute.addr).tradeSingleHop(quote);
        amountOut = IERC20(subRoute.to).balanceOf(address(this)) - balanceBefore;
        if (receiver != address(this)) {
            IERC20(subRoute.to).transfer(receiver, amountOut);
        }
    }
}
