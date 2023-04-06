// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

interface IPancakeStablePool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;

    function coins(uint256 i) external view returns (address);
}

library PancakeSwapStable {
    function swap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        (int128 from, int128 to) = abi.decode(subRoute.data, (int128, int128));
        uint256 balanceBefore = IERC20(subRoute.to).balanceOf(address(this));
        IERC20(subRoute.from).approve(subRoute.addr, amountIn);
        IPancakeStablePool(subRoute.addr).exchange(uint256(uint128(from)), uint256(uint128(to)), amountIn, 0);
        amountOut = IERC20(subRoute.to).balanceOf(address(this)) - balanceBefore;
        if (receiver != address(this)) {
            IERC20(subRoute.to).transfer(receiver, amountOut);
        }
    }
}
