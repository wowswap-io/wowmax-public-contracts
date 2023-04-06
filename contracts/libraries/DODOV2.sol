// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWowmaxRouter.sol";

interface DODOV2Pool {
    function sellBase(address to) external returns (uint256);

    function sellQuote(address to) external returns (uint256);

    function getPMMStateForCall()
        external
        view
        returns (uint256 i, uint256 K, uint256 B, uint256 Q, uint256 B0, uint256 Q0, uint256 R);

    function getUserFeeRate(address user) external view returns (uint256 lpFeeRate, uint256 mtFeeRate);
}

library DODOV2 {
    uint8 constant BASE_TO_QUOTE = 0;
    uint8 constant QUOTE_TO_BASE = 1;

    function swap(
        uint256 amountIn,
        IWowmaxRouter.ExchangeSubRoute calldata subRoute,
        address receiver
    ) internal returns (uint256 amountOut) {
        IERC20(subRoute.from).transfer(subRoute.addr, amountIn);
        uint8 direction = abi.decode(subRoute.data, (uint8));

        if (direction == BASE_TO_QUOTE) {
            amountOut = DODOV2Pool(subRoute.addr).sellBase(receiver);
        } else {
            amountOut = DODOV2Pool(subRoute.addr).sellQuote(receiver);
        }
    }
}
