// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

library Curve {
    function swap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        (int128 from, int128 to) = abi.decode(subRoute.data, (int128, int128));
        uint256 balanceBefore = IERC20(subRoute.to).balanceOf(address(this));
        IERC20(subRoute.from).approve(subRoute.addr, amountIn);
        ICurvePool(subRoute.addr).exchange(from, to, amountIn, 0);
        amountOut = IERC20(subRoute.to).balanceOf(address(this)) - balanceBefore;
        if (receiver != address(this)) {
            IERC20(subRoute.to).transfer(receiver, amountOut);
        }
    }
}
