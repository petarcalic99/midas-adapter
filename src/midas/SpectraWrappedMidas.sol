// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {Spectra4626Wrapper, ERC4626Upgradeable} from "../utils/Spectra4626Wrapper.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IDataFeed} from "./interfaces/IVault.sol";
import {DecimalsCorrectionLibrary} from "./DecimalsCorrectionLibrary.sol";

/// @title SpectraWrappedMidasVault - Implementation of Spectra ERC4626 wrapper for a midasVault
/// @notice This contract wraps a MidasVault with the ERC4626 interface
/// @notice The contract is instantiated with the vault address, the Underlying address
/// @notice and the initial authority.
contract SpectraWrappedMidasVault is Spectra4626Wrapper {
    using Math for uint256;
    using DecimalsCorrectionLibrary for uint256;
    using SafeERC20 for IERC20;

    uint256 private UNDELRYING_DECIMALS;
    address private midasDeposit;
    address private midasRedeem;
    IDataFeed private mTokenDataFeed;

    uint256 private constant UNIT = 10**18;
    uint256 private constant STABLECOIN_RATE = 10**18;
    uint256 public constant ONE_HUNDRED_PERCENT = 100 * 100;

    error NotImplemented();

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _asset,
        address _midasToken,
        address _midasRedeem,
        address _midasDeposit,
        address _initAuth
    ) external initializer {
        __Spectra4626Wrapper_init(_asset, _midasToken, _initAuth);
        UNDELRYING_DECIMALS = IERC20Metadata(_asset).decimals();
        midasDeposit = _midasDeposit;
        midasRedeem = _midasRedeem;
        mTokenDataFeed = IVault(_midasDeposit).mTokenDataFeed();
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 GETTERS
    //////////////////////////////////////////////////////////////*/

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(
        address
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /// @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(
        address /*owner*/
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /// @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(
        address /*owner*/
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /// @dev See {IERC4626-previewDeposit}.
    function previewDeposit(
        uint256 assets
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /// @dev See {IERC4626-previewMint}.
    function previewMint(
        uint256 shares
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /// @dev See {IERC4626-previewWithdraw}.
    function previewWithdraw(
        uint256 assets
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return 0;
    }

    /// @dev See {IERC4626-previewRedeem}.
    function previewRedeem(
        uint256 shares
    ) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        if (shares == 0) {
            return 0;
        }
        uint256 vaultSharesAmount = _previewUnwrap(shares, Math.Rounding.Floor);
        
        return _midasVaultConvertToAssetsWithFees(vaultSharesAmount);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 PUBLIC OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC4626-deposit}.
    function deposit(
        uint256 /*assets*/,
        address /*receiver*/
    ) public override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        revert NotImplemented();
    }

    /// @dev See {IERC4626-mint}.
    function mint(
        uint256 /*shares*/,
        address /*receiver*/
    ) public override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        revert NotImplemented();
    }

    /// @dev See {IERC4626-withdraw}.
    function withdraw(
        uint256 /*assets*/,
        address /*receiver*/,
        address /*owner*/
    ) public override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        revert NotImplemented();
    }

    /// @dev See {IERC4626-redeem}.
    function redeem(
        uint256 /*shares*/,
        address /*receiver*/,
        address /*owner*/
    ) public override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        revert NotImplemented();
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Internal conversion function (from assets to shares) with support for rounding direction.
    /// @param assets The amount of assets to convert.
    /// @param rounding The rounding direction to use.
    /// @return The amount of shares.
    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view override(ERC4626Upgradeable) returns (uint256) {
        uint256 vaultSharesAmount = _midasVaultConvertToShares(assets);
        return _previewWrap(vaultSharesAmount, rounding);
    }

    /// @dev Internal conversion function (from shares to assets) with support for rounding direction.
    /// @param shares The amount of shares to convert.
    /// @param rounding The rounding direction to use.
    /// @return The amount of assets.
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override(ERC4626Upgradeable) returns (uint256) {
        uint256 vaultSharesAmount = _previewUnwrap(shares, rounding);
        return _midasVaultConvertToAssets(vaultSharesAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNALS
    //////////////////////////////////////////////////////////////*/

    /// @dev Internal midasVault conversion function (from assets to midasVault shares) rounding down.
    function _midasVaultConvertToShares(
        uint256 assets
    ) internal view returns (uint256) {
        IVault.TokenConfig memory tokenConfig = IVault(midasDeposit).tokensConfig(asset());
        uint256 rate = _getTokenRate(tokenConfig.dataFeed, tokenConfig.stable);
        require(rate > 0, "rate zero");
        uint256 amountInUsd = (assets * rate) / (UNIT);

        uint256 mTokenRate = _getTokenRate(address(mTokenDataFeed), false);
        require(mTokenRate > 0, "rate zero");

        uint256 amountMToken = (amountInUsd * (UNIT)) / mTokenRate;

        return amountMToken;
    }

    /// @dev Internal midasVault conversion function (from midasVault shares to assets) rounding down.
    function _midasVaultConvertToAssets(
        uint256 shares
    ) internal view returns (uint256) {

        uint256 mTokenRate = _getTokenRate(address(mTokenDataFeed), false);
        require(mTokenRate > 0, "rate zero");

        IVault.TokenConfig memory tokenConfig = IVault(midasRedeem).tokensConfig(asset());
        uint256 tokenOutRate = _getTokenRate(tokenConfig.dataFeed, tokenConfig.stable);
        require(tokenOutRate > 0, "rate zero");

        uint256 amountTokenOut = _truncate((shares * mTokenRate) / tokenOutRate, UNDELRYING_DECIMALS);
        
        return amountTokenOut;
    }

    /// @dev Internal midasVault conversion function (from midasVault shares to assets) rounding down, taking into account fees.
    function _midasVaultConvertToAssetsWithFees(
        uint256 shares
    ) internal view returns (uint256) {
        IVault.TokenConfig memory tokenConfig = IVault(midasRedeem).tokensConfig(asset());
        uint256 feePercent = tokenConfig.fee + IVault(midasRedeem).instantFee();
        if (feePercent > ONE_HUNDRED_PERCENT) feePercent = ONE_HUNDRED_PERCENT;
        uint256 feeAmount = (shares * feePercent) / ONE_HUNDRED_PERCENT;
        require(shares > feeAmount, "shares < fee");
        uint256 sharesWithoutFee = shares - feeAmount;

        uint256 mTokenRate = _getTokenRate(address(mTokenDataFeed), false);
        require(mTokenRate > 0, "rate zero");

        uint256 tokenOutRate = _getTokenRate(tokenConfig.dataFeed, tokenConfig.stable);
        require(tokenOutRate > 0, "rate zero");

        uint256 amountTokenOut = _truncate((sharesWithoutFee * mTokenRate) / tokenOutRate, UNDELRYING_DECIMALS);
        
        return amountTokenOut;
    }

    /**
     * @dev get token rate depends on data feed and stablecoin flag
     * @param dataFeed address of dataFeed from token config
     * @param stable is stablecoin
     */
    function _getTokenRate(address dataFeed, bool stable)
        internal
        view
        virtual
        returns (uint256)
    {
        // @dev if dataFeed returns rate, all peg checks passed
        uint256 rate = IDataFeed(dataFeed).getDataInBase18();

        if (stable) return STABLECOIN_RATE;

        return rate;
    }

    /**
     * @dev convert value to inputted decimals precision
     * @param value value for format
     * @param decimals decimals
     * @return converted amount
     */
    function _truncate(uint256 value, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        return value.convertFromBase18(decimals).convertToBase18(decimals);
    }
}
