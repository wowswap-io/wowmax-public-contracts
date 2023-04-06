// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IWowmaxRouter {
    struct ExchangeSubRoute {
        address from;
        address to;
        uint256 part;
        address addr;
        bytes32 family;
        uint256 fee;
        uint256 feeDenominator;
        bytes data;
    }

    struct ExchangeRoute {
        uint256 amountIn;
        uint256 parts;
        ExchangeSubRoute[][] subRoutes;
    }

    struct ExchangeRequest {
        address from; // from token
        uint256 amountIn;
        address[] to; // to tokens
        ExchangeRoute[] exchangeRoutes;
        uint256[] slippage;
        uint256[] amountOutExpected;
    }

    function exchange(ExchangeRequest calldata request) external payable returns (uint256[] memory amountsOut);
}
