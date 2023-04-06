// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function router() external returns (address);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

library UniswapV2 {
    function swap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        IERC20(subRoute.from).transfer(subRoute.addr, amountIn);
        bool directSwap = IUniswapV2Pair(subRoute.addr).token0() == subRoute.from;
        (uint112 reserveIn, uint112 reserveOut) = getReserves(subRoute.addr, directSwap);
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut, subRoute.fee, subRoute.feeDenominator);
        if (amountOut > 0) {
            IUniswapV2Pair(subRoute.addr).swap(
                directSwap ? 0 : amountOut,
                directSwap ? amountOut : 0,
                receiver,
                new bytes(0)
            );
        }
    }

    function routerSwap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        IUniswapV2Router router = IUniswapV2Router(IUniswapV2Pair(subRoute.addr).router());
        IERC20(subRoute.from).approve(address(router), amountIn);
        address[] memory path = new address[](2);
        path[0] = subRoute.from;
        path[1] = subRoute.to;
        return router.swapExactTokensForTokens(amountIn, 0, path, receiver, type(uint256).max)[1];
    }

    function getReserves(address pair, bool directSwap) private view returns (uint112 reserveIn, uint112 reserveOut) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        return directSwap ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(
        uint256 amountIn,
        uint112 reserveIn,
        uint112 reserveOut,
        uint256 fee,
        uint256 feeDenominator
    ) private pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * (feeDenominator - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * feeDenominator + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
