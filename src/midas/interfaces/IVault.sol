// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IVault {
    /**
     * @param dataFeed data feed token/USD address
     * @param fee fee by token, 1% = 100
     * @param allowance token allowance (decimals 18)
     * @param stable indicates whether this token is considered a stable asset
     */
    struct TokenConfig {
        address dataFeed;
        uint256 fee;
        uint256 allowance;
        bool stable;
    }

        /**
     * @notice Allows instant deposits of a specified token.
     * @dev Implementations must handle appropriate access control,
     *      pause checks, blacklist checks, etc.
     * @param tokenIn The address of the token being deposited
     * @param amountToken The amount of `tokenIn` to deposit
     * @param minReceiveAmount The minimum amount of deposit tokens to receive
     * @param referrerId An optional referrer identifier
     */
    function depositInstant(
        address tokenIn,
        uint256 amountToken,
        uint256 minReceiveAmount,
        bytes32 referrerId
    ) external;

    function redeemInstant(address tokenOut, uint256 amountMTokenIn, uint256 minReceiveAmount) external;

    /**
     * @notice Retrieves the TokenConfig for a given token
     * @param token The asset token address
     * @return The TokenConfig structure for the specified token
     */
    function tokensConfig(address token) external view returns (TokenConfig memory);

    function mTokenDataFeed() external view returns (IDataFeed);

    function instantFee() external view returns (uint256);
}

interface IDataFeed {
    /**
     * @notice Retrieves the token's rate in 18 decimals
     * @return The 18-decimal rate
     */
    function getDataInBase18() external view returns (uint256);
}
