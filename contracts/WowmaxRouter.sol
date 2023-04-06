// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./interfaces/IWowmaxRouter.sol";
import "./interfaces/IWETH.sol";

import "./libraries/UniswapV2.sol";
import "./libraries/Curve.sol";
import "./libraries/PancakeSwapStable.sol";
import "./libraries/DODOV2.sol";
import "./libraries/Hashflow.sol";
import "./libraries/Saddle.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract WowmaxRouter is IWowmaxRouter, Ownable, ReentrancyGuard {
    IWETH public WETH;
    address public treasury;

    bytes32 constant UNISWAP_V2 = "UNISWAP_V2";
    bytes32 constant UNISWAP_V2_ROUTER = "UNISWAP_V2_ROUTER";
    bytes32 constant CURVE = "CURVE";
    bytes32 constant DODO_V2 = "DODO_V2";
    bytes32 constant HASHFLOW = "HASHFLOW";
    bytes32 constant PANCAKESWAP_STABLE = "PANCAKESWAP_STABLE";
    bytes32 constant SADDLE = "SADDLE";

    constructor(address _weth, address _treasury) {
        require(_weth != address(0), "Wrong WETH address");
        require(_treasury != address(0), "Wrong treasury address");

        WETH = IWETH(_weth);
        treasury = _treasury;
    }

    receive() external payable {
        require(_msgSender() == payable(address(WETH)), "Forbidden token transfer");
        // only accept chain tokens via fallback from the wrapper contract
    }

    function exchange(
        ExchangeRequest calldata request
    ) external payable override nonReentrant returns (uint256[] memory amountsOut) {
        receiveTokens(request);
        for (uint256 i = 0; i < request.exchangeRoutes.length; i++) {
            exchange(request.exchangeRoutes[i]);
        }
        return transferTokens(request);
    }

    function receiveTokens(ExchangeRequest calldata request) private {
        if (msg.value > 0 && request.from == address(0) && request.amountIn == 0) {
            WETH.deposit{ value: msg.value }();
        } else {
            if (request.amountIn > 0) {
                IERC20(request.from).transferFrom(msg.sender, address(this), request.amountIn);
            }
        }
    }

    function transferTokens(ExchangeRequest calldata request) private returns (uint256[] memory amountsOut) {
        amountsOut = new uint256[](request.to.length);
        uint256 amountOut;
        IERC20 token;
        for (uint256 i = 0; i < request.to.length; i++) {
            token = IERC20(request.to[i]);
            amountOut = token.balanceOf(address(this));

            uint256 amountExtra;
            if (amountOut > request.amountOutExpected[i]) {
                amountExtra = amountOut - request.amountOutExpected[i];
                amountsOut[i] = request.amountOutExpected[i];
            } else {
                require(
                    amountOut >= (request.amountOutExpected[i] * (10000 - request.slippage[i])) / 10000,
                    "Insufficient output amount"
                );
                amountsOut[i] = amountOut;
            }

            if (address(token) == address(WETH)) {
                WETH.withdraw(amountOut);
            }

            transfer(token, treasury, amountExtra);
            transfer(token, msg.sender, amountsOut[i]);
        }
    }

    function transfer(IERC20 token, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        if (address(token) == address(WETH)) {
            payable(to).transfer(amount);
        } else {
            token.transfer(to, amount);
        }
    }

    function exchange(ExchangeRoute calldata exchangeRoute) private {
        uint256 amountIn = exchangeRoute.amountIn;
        for (uint256 i = 0; i < exchangeRoute.subRoutes.length; i++) {
            amountIn = exchange(amountIn, exchangeRoute.parts, exchangeRoute.subRoutes[i]);
        }
    }

    function exchange(
        uint256 amountIn,
        uint256 parts,
        ExchangeSubRoute[] calldata subRoutes
    ) private returns (uint256 amountOut) {
        for (uint256 i = 0; i < subRoutes.length; i++) {
            amountOut += swap((amountIn * subRoutes[i].part) / parts, subRoutes[i], address(this));
        }
    }

    function swap(
        uint256 amountIn,
        ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal virtual returns (uint256) {
        if (subRoute.family == UNISWAP_V2) {
            return UniswapV2.swap(amountIn, subRoute, receiver);
        } else if (subRoute.family == UNISWAP_V2_ROUTER) {
            return UniswapV2.routerSwap(amountIn, subRoute, receiver);
        } else if (subRoute.family == CURVE) {
            return Curve.swap(amountIn, subRoute, receiver);
        } else if (subRoute.family == PANCAKESWAP_STABLE) {
            return PancakeSwapStable.swap(amountIn, subRoute, receiver);
        } else if (subRoute.family == DODO_V2) {
            return DODOV2.swap(amountIn, subRoute, receiver);
        } else if (subRoute.family == HASHFLOW) {
            return Hashflow.swap(amountIn, subRoute, receiver);
        } else if (subRoute.family == SADDLE) {
            return Saddle.swap(amountIn, subRoute, receiver);
        } else {
            revert("Not implemented exchange family");
        }
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(treasury, amount);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        (bool success, ) = payable(treasury).call{ value: amount }(new bytes(0));
        require(success, "ETH transfer failed");
    }
}
