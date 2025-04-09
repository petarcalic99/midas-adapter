// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Interface for Depositor contracts that implement custom logic for complex ERC-4626 deposits.
/// This interface mirrors functions involved in ISpectra4626Wrapper wrapping logic.
/// It also includes a tokenOut getter to fetch the receipt token as needed.
interface IDepositor {
    error ERC5143SlippageProtectionFailed();

    /// @dev Returns the address of the input token.
    function vaultShare() external view returns (address);

    /// @dev Returns the address of the output token.
    function tokenOut() external view returns (address);

    /// @dev Allows to preview the amount of minted tokenOut shares for a given amount of deposited input vault shares.
    /// @param inputShares The amount of input vault shares to deposit.
    /// @return The amount of minted tokenOut shares.
    function previewWrap(uint256 inputShares) external view returns (uint256);

    /// @dev Allows the owner to deposit input vault shares in exchange of tokenOut shares.
    /// @param inputShares The amount of input vault shares to deposit.
    /// @param receiver The address to receive the tokenOut shares.
    /// @return The amount of minted tokenOut shares.
    function wrap(uint256 inputShares, address receiver) external returns (uint256);

    /// @dev Allows the owner to deposit input vault shares in exchange of tokenOut shares, with support for slippage protection.
    /// @param inputShares The amount of input vault shares to deposit.
    /// @param receiver The address to receive the tokenOut shares.
    /// @param minShares The minimum allowed tokenOut shares from this deposit.
    /// @return The amount of minted tokenOut shares.
    function wrap(
        uint256 inputShares,
        address receiver,
        uint256 minShares
    ) external returns (uint256);
}
