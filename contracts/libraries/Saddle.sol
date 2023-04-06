// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

interface ISaddlePool {
    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external;
}

library Saddle {
    function swap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        (uint8 from, uint8 to) = abi.decode(subRoute.data, (uint8, uint8));
        uint256 balanceBefore = IERC20(subRoute.to).balanceOf(address(this));
        IERC20(subRoute.from).approve(subRoute.addr, amountIn);
        ISaddlePool(subRoute.addr).swap(from, to, amountIn, 0, type(uint256).max);
        amountOut = IERC20(subRoute.to).balanceOf(address(this)) - balanceBefore;
        if (receiver != address(this)) {
            IERC20(subRoute.to).transfer(receiver, amountOut);
        }
    }
}
